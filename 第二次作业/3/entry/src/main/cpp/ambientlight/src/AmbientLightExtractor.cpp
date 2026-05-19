/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "AmbientLightExtractor.h"
#include <hilog/log.h>
#include <algorithm>
#include <cmath>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "AmbientLight"

constexpr uint32_t LOG_PRINT_DOMAIN = 0xFF00;

namespace AmbientLight {

AmbientLightExtractor& AmbientLightExtractor::GetInstance() {
    static AmbientLightExtractor instance;
    return instance;
}

AmbientLightExtractor::AmbientLightExtractor() = default;

AmbientLightExtractor::~AmbientLightExtractor() {
    Release();
}

void AmbientLightExtractor::Initialize(int videoWidth, int videoHeight) {
    std::lock_guard<std::mutex> lock(frameMutex_);
    
    videoWidth_ = videoWidth;
    videoHeight_ = videoHeight;
    sampleWidth_ = videoWidth / DOWNSAMPLE_FACTOR;
    sampleHeight_ = videoHeight / DOWNSAMPLE_FACTOR;
    
    // Ensure minimum dimensions
    if (sampleWidth_ < 16) sampleWidth_ = 16;
    if (sampleHeight_ < 16) sampleHeight_ = 16;
    
    isRunning_ = true;
    processingThread_ = std::thread(&AmbientLightExtractor::ProcessingThread, this);
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, LOG_TAG, 
                 "AmbientLight initialized: video=%dx%d, sample=%dx%d",
                 videoWidth_, videoHeight_, sampleWidth_, sampleHeight_);
}

void AmbientLightExtractor::Release() {
    isRunning_ = false;
    frameCV_.notify_all();
    
    if (processingThread_.joinable()) {
        processingThread_.join();
    }
    
    std::lock_guard<std::mutex> lock(frameMutex_);
    while (!frameQueue_.empty()) {
        frameQueue_.pop();
    }
}

void AmbientLightExtractor::SetEnabled(bool enabled) {
    enabled_.store(enabled);
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, LOG_TAG, 
                 "AmbientLight enabled: %d", enabled);
}

void AmbientLightExtractor::SetUpdateInterval(int intervalMs) {
    updateIntervalMs_.store(intervalMs);
}

void AmbientLightExtractor::SetBrightness(float brightness) {
    brightness_.store(std::max(0.0f, std::min(1.0f, brightness)));
}

void AmbientLightExtractor::SetSmoothFactor(float factor) {
    smoothFactor_.store(std::max(0.0f, std::min(1.0f, factor)));
}

void AmbientLightExtractor::SubmitFrame(const uint8_t* yuvData, int width, int height, int64_t timestamp) {
    if (!enabled_.load() || !isRunning_.load()) {
        return;
    }
    
    std::lock_guard<std::mutex> lock(frameMutex_);
    
    // Limit queue size to prevent memory buildup
    if (frameQueue_.size() >= MAX_QUEUE_SIZE) {
        frameQueue_.pop();
    }
    
    FrameBuffer frame;
    frame.width = sampleWidth_;
    frame.height = sampleHeight_;
    frame.timestamp = timestamp;
    
    // Downsample YUV data
    int dstYUVSize = sampleWidth_ * sampleHeight_ * 3 / 2;
    frame.data.resize(dstYUVSize);
    DownsampleFrame(yuvData, width, height, frame.data, sampleWidth_, sampleHeight_);
    
    frameQueue_.push(std::move(frame));
    frameCV_.notify_one();
}

ColorData AmbientLightExtractor::GetLatestColorData() {
    std::lock_guard<std::mutex> lock(colorMutex_);
    return smoothedColorData_;
}

void AmbientLightExtractor::ProcessingThread() {
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, LOG_TAG, "Processing thread started");
    
    while (isRunning_.load()) {
        FrameBuffer frame;
        
        {
            std::unique_lock<std::mutex> lock(frameMutex_);
            frameCV_.wait(lock, [this]() {
                return !isRunning_.load() || !frameQueue_.empty();
            });
            
            if (!isRunning_.load()) break;
            if (frameQueue_.empty()) continue;
            
            frame = std::move(frameQueue_.front());
            frameQueue_.pop();
        }
        
        // Process frame
        ColorData colorData = ProcessFrame(frame);
        
        // Apply smoothing
        {
            std::lock_guard<std::mutex> lock(colorMutex_);
            colorData.dominantColor = SmoothColor(colorData.dominantColor, smoothedColorData_.dominantColor);
            colorData.averageColor = SmoothColor(colorData.averageColor, smoothedColorData_.averageColor);
            colorData.topColor = SmoothColor(colorData.topColor, smoothedColorData_.topColor);
            colorData.bottomColor = SmoothColor(colorData.bottomColor, smoothedColorData_.bottomColor);
            colorData.leftColor = SmoothColor(colorData.leftColor, smoothedColorData_.leftColor);
            colorData.rightColor = SmoothColor(colorData.rightColor, smoothedColorData_.rightColor);
            
            smoothedColorData_ = colorData;
        }
        
        // Control update rate
        std::this_thread::sleep_for(std::chrono::milliseconds(updateIntervalMs_.load()));
    }
    
    OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, LOG_TAG, "Processing thread ended");
}

ColorData AmbientLightExtractor::ProcessFrame(const FrameBuffer& frame) {
    ColorData data;
    data.timestamp = frame.timestamp;
    
    // Convert YUV to RGB
    std::vector<ColorRGB> rgbColors;
    YUVToRGB(frame.data.data(), frame.width, frame.height, rgbColors);
    
    if (rgbColors.empty()) {
        return data;
    }
    
    // Extract colors
    data.dominantColor = ExtractDominantColor(rgbColors);
    data.averageColor = CalculateAverageColor(rgbColors);
    ExtractEdgeColors(rgbColors, frame.width, frame.height, 
                     data.topColor, data.bottomColor, data.leftColor, data.rightColor);
    
    // Apply brightness
    float brightness = brightness_.load();
    auto applyBrightness = [brightness](ColorRGB& color) {
        color.r = static_cast<uint8_t>(color.r * brightness);
        color.g = static_cast<uint8_t>(color.g * brightness);
        color.b = static_cast<uint8_t>(color.b * brightness);
    };
    
    applyBrightness(data.dominantColor);
    applyBrightness(data.averageColor);
    applyBrightness(data.topColor);
    applyBrightness(data.bottomColor);
    applyBrightness(data.leftColor);
    applyBrightness(data.rightColor);
    
    return data;
}

void AmbientLightExtractor::DownsampleFrame(const uint8_t* srcYUV, int srcW, int srcH, 
                                           std::vector<uint8_t>& dstYUV, int dstW, int dstH) {
    int srcYSize = srcW * srcH;
    int srcUVSize = srcYSize / 4;
    
    int dstYSize = dstW * dstH;
    int dstUVSize = dstYSize / 4;
    
    // Downsample Y plane
    float xRatio = static_cast<float>(srcW) / dstW;
    float yRatio = static_cast<float>(srcH) / dstH;
    
    for (int y = 0; y < dstH; y++) {
        for (int x = 0; x < dstW; x++) {
            int srcX = static_cast<int>(x * xRatio);
            int srcY = static_cast<int>(y * yRatio);
            srcX = std::min(srcX, srcW - 1);
            srcY = std::min(srcY, srcH - 1);
            
            dstYUV[y * dstW + x] = srcYUV[srcY * srcW + srcX];
        }
    }
    
    // Downsample UV planes (UV is subsampled 2x2 in YUV420)
    uint8_t* dstU = dstYUV.data() + dstYSize;
    uint8_t* dstV = dstU + dstUVSize;
    const uint8_t* srcU = srcYUV + srcYSize;
    const uint8_t* srcV = srcU + srcUVSize;
    
    int srcUVW = srcW / 2;
    int srcUVH = srcH / 2;
    int dstUVW = dstW / 2;
    int dstUVH = dstH / 2;
    
    float uvXRatio = static_cast<float>(srcUVW) / dstUVW;
    float uvYRatio = static_cast<float>(srcUVH) / dstUVH;
    
    for (int y = 0; y < dstUVH; y++) {
        for (int x = 0; x < dstUVW; x++) {
            int srcX = static_cast<int>(x * uvXRatio);
            int srcY = static_cast<int>(y * uvYRatio);
            srcX = std::min(srcX, srcUVW - 1);
            srcY = std::min(srcY, srcUVH - 1);
            
            dstU[y * dstUVW + x] = srcU[srcY * srcUVW + srcX];
            dstV[y * dstUVW + x] = srcV[srcY * srcUVW + srcX];
        }
    }
}

void AmbientLightExtractor::YUVToRGB(const uint8_t* yuv, int width, int height, std::vector<ColorRGB>& rgb) {
    rgb.clear();
    rgb.reserve(width * height);
    
    const uint8_t* yPlane = yuv;
    const uint8_t* uPlane = yuv + width * height;
    const uint8_t* vPlane = uPlane + (width * height) / 4;
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int yIndex = y * width + x;
            int uvIndex = (y / 2) * (width / 2) + (x / 2);
            
            int Y = yPlane[yIndex];
            int U = uPlane[uvIndex] - 128;
            int V = vPlane[uvIndex] - 128;
            
            // YUV to RGB conversion
            int R = Y + (int)(1.402f * V);
            int G = Y - (int)(0.344f * U + 0.714f * V);
            int B = Y + (int)(1.772f * U);
            
            // Clamp to 0-255
            R = std::max(0, std::min(255, R));
            G = std::max(0, std::min(255, G));
            B = std::max(0, std::min(255, B));
            
            rgb.emplace_back(static_cast<uint8_t>(R), static_cast<uint8_t>(G), static_cast<uint8_t>(B));
        }
    }
}

ColorRGB AmbientLightExtractor::ExtractDominantColor(const std::vector<ColorRGB>& colors) {
    if (colors.empty()) return ColorRGB();
    
    // Simple k-means with k=3 for dominant color extraction
    const int K = 3;
    const int MAX_ITER = 10;
    
    // Initialize centroids
    std::vector<ColorRGB> centroids;
    centroids.push_back(colors[0]);
    centroids.push_back(colors[colors.size() / 2]);
    centroids.push_back(colors[colors.size() - 1]);
    
    std::vector<int> assignments(colors.size(), 0);
    
    for (int iter = 0; iter < MAX_ITER; iter++) {
        // Assign points to nearest centroid
        for (size_t i = 0; i < colors.size(); i++) {
            int bestCluster = 0;
            int bestDist = INT_MAX;
            
            for (int k = 0; k < K; k++) {
                int dr = (int)colors[i].r - (int)centroids[k].r;
                int dg = (int)colors[i].g - (int)centroids[k].g;
                int db = (int)colors[i].b - (int)centroids[k].b;
                int dist = dr * dr + dg * dg + db * db;
                
                if (dist < bestDist) {
                    bestDist = dist;
                    bestCluster = k;
                }
            }
            assignments[i] = bestCluster;
        }
        
        // Update centroids
        std::vector<int> sumR(K, 0), sumG(K, 0), sumB(K, 0), count(K, 0);
        for (size_t i = 0; i < colors.size(); i++) {
            int k = assignments[i];
            sumR[k] += colors[i].r;
            sumG[k] += colors[i].g;
            sumB[k] += colors[i].b;
            count[k]++;
        }
        
        for (int k = 0; k < K; k++) {
            if (count[k] > 0) {
                centroids[k].r = sumR[k] / count[k];
                centroids[k].g = sumG[k] / count[k];
                centroids[k].b = sumB[k] / count[k];
            }
        }
    }
    
    // Find largest cluster
    std::vector<int> clusterSizes(K, 0);
    for (int assignment : assignments) {
        clusterSizes[assignment]++;
    }
    
    int largestCluster = 0;
    for (int k = 1; k < K; k++) {
        if (clusterSizes[k] > clusterSizes[largestCluster]) {
            largestCluster = k;
        }
    }
    
    return centroids[largestCluster];
}

ColorRGB AmbientLightExtractor::CalculateAverageColor(const std::vector<ColorRGB>& colors) {
    if (colors.empty()) return ColorRGB();
    
    long sumR = 0, sumG = 0, sumB = 0;
    for (const auto& color : colors) {
        sumR += color.r;
        sumG += color.g;
        sumB += color.b;
    }
    
    return ColorRGB(
        static_cast<uint8_t>(sumR / colors.size()),
        static_cast<uint8_t>(sumG / colors.size()),
        static_cast<uint8_t>(sumB / colors.size())
    );
}

void AmbientLightExtractor::ExtractEdgeColors(const std::vector<ColorRGB>& colors, int width, int height,
                                             ColorRGB& top, ColorRGB& bottom, ColorRGB& left, ColorRGB& right) {
    if (colors.empty() || width <= 0 || height <= 0) return;
    
    // Sample edge pixels
    const int SAMPLE_SIZE = std::min(32, width / 4);
    
    long sumTopR = 0, sumTopG = 0, sumTopB = 0;
    long sumBottomR = 0, sumBottomG = 0, sumBottomB = 0;
    long sumLeftR = 0, sumLeftG = 0, sumLeftB = 0;
    long sumRightR = 0, sumRightG = 0, sumRightB = 0;
    
    int topCount = 0, bottomCount = 0, leftCount = 0, rightCount = 0;
    
    // Top edge
    for (int x = 0; x < width; x += width / SAMPLE_SIZE) {
        const auto& color = colors[x];
        sumTopR += color.r;
        sumTopG += color.g;
        sumTopB += color.b;
        topCount++;
    }
    
    // Bottom edge
    for (int x = 0; x < width; x += width / SAMPLE_SIZE) {
        const auto& color = colors[(height - 1) * width + x];
        sumBottomR += color.r;
        sumBottomG += color.g;
        sumBottomB += color.b;
        bottomCount++;
    }
    
    // Left edge
    for (int y = 0; y < height; y += height / SAMPLE_SIZE) {
        const auto& color = colors[y * width];
        sumLeftR += color.r;
        sumLeftG += color.g;
        sumLeftB += color.b;
        leftCount++;
    }
    
    // Right edge
    for (int y = 0; y < height; y += height / SAMPLE_SIZE) {
        const auto& color = colors[y * width + (width - 1)];
        sumRightR += color.r;
        sumRightG += color.g;
        sumRightB += color.b;
        rightCount++;
    }
    
    if (topCount > 0) {
        top = ColorRGB(sumTopR / topCount, sumTopG / topCount, sumTopB / topCount);
    }
    if (bottomCount > 0) {
        bottom = ColorRGB(sumBottomR / bottomCount, sumBottomG / bottomCount, sumBottomB / bottomCount);
    }
    if (leftCount > 0) {
        left = ColorRGB(sumLeftR / leftCount, sumLeftG / leftCount, sumLeftB / leftCount);
    }
    if (rightCount > 0) {
        right = ColorRGB(sumRightR / rightCount, sumRightG / rightCount, sumRightB / rightCount);
    }
}

ColorRGB AmbientLightExtractor::SmoothColor(const ColorRGB& newColor, const ColorRGB& prevColor) {
    float factor = smoothFactor_.load();
    
    return ColorRGB(
        static_cast<uint8_t>(prevColor.r * factor + newColor.r * (1.0f - factor)),
        static_cast<uint8_t>(prevColor.g * factor + newColor.g * (1.0f - factor)),
        static_cast<uint8_t>(prevColor.b * factor + newColor.b * (1.0f - factor))
    );
}

} // namespace AmbientLight
