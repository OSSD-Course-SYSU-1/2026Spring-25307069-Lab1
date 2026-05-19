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

#ifndef AMBIENT_LIGHT_EXTRACTOR_H
#define AMBIENT_LIGHT_EXTRACTOR_H

#include <cstdint>
#include <vector>
#include <atomic>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>

namespace AmbientLight {

// RGB color structure
struct ColorRGB {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    
    ColorRGB() : r(0), g(0), b(0) {}
    ColorRGB(uint8_t red, uint8_t green, uint8_t blue) : r(red), g(green), b(blue) {}
    
    bool operator==(const ColorRGB& other) const {
        return r == other.r && g == other.g && b == other.b;
    }
};

// Color data for UI layer
struct ColorData {
    ColorRGB dominantColor;    // Main dominant color
    ColorRGB averageColor;     // Average color
    ColorRGB topColor;         // Top edge color
    ColorRGB bottomColor;      // Bottom edge color
    ColorRGB leftColor;        // Left edge color
    ColorRGB rightColor;       // Right edge color
    int64_t timestamp;         // Timestamp
    
    ColorData() : timestamp(0) {}
};

// Frame buffer for processing
struct FrameBuffer {
    std::vector<uint8_t> data;
    int width;
    int height;
    int64_t timestamp;
    
    FrameBuffer() : width(0), height(0), timestamp(0) {}
};

class AmbientLightExtractor {
public:
    static AmbientLightExtractor& GetInstance();
    
    // Initialize with video dimensions
    void Initialize(int videoWidth, int videoHeight);
    
    // Release resources
    void Release();
    
    // Submit frame for processing (called from video decoder thread)
    void SubmitFrame(const uint8_t* yuvData, int width, int height, int64_t timestamp);
    
    // Get latest extracted color data (called from UI thread)
    ColorData GetLatestColorData();
    
    // Enable/disable ambient light
    void SetEnabled(bool enabled);
    bool IsEnabled() const { return enabled_.load(); }
    
    // Set update interval (ms)
    void SetUpdateInterval(int intervalMs);
    
    // Set brightness (0.0 - 1.0)
    void SetBrightness(float brightness);
    float GetBrightness() const { return brightness_.load(); }
    
    // Set smooth factor (0.0 - 1.0, higher = smoother but slower)
    void SetSmoothFactor(float factor);

private:
    AmbientLightExtractor();
    ~AmbientLightExtractor();
    
    // Processing thread function
    void ProcessingThread();
    
    // Process a single frame
    ColorData ProcessFrame(const FrameBuffer& frame);
    
    // Convert YUV to RGB
    void YUVToRGB(const uint8_t* yuv, int width, int height, std::vector<ColorRGB>& rgb);
    
    // Extract dominant color using k-means
    ColorRGB ExtractDominantColor(const std::vector<ColorRGB>& colors);
    
    // Calculate average color
    ColorRGB CalculateAverageColor(const std::vector<ColorRGB>& colors);
    
    // Extract edge colors
    void ExtractEdgeColors(const std::vector<ColorRGB>& colors, int width, int height,
                          ColorRGB& top, ColorRGB& bottom, ColorRGB& left, ColorRGB& right);
    
    // Apply color smoothing
    ColorRGB SmoothColor(const ColorRGB& newColor, const ColorRGB& prevColor);
    
    // Downsample frame for faster processing
    void DownsampleFrame(const uint8_t* srcYUV, int srcW, int srcH, 
                        std::vector<uint8_t>& dstYUV, int dstW, int dstH);

private:
    std::atomic<bool> enabled_{false};
    std::atomic<bool> isRunning_{false};
    std::atomic<float> brightness_{0.8f};
    std::atomic<float> smoothFactor_{0.3f};
    std::atomic<int> updateIntervalMs_{100};
    
    int videoWidth_ = 0;
    int videoHeight_ = 0;
    int sampleWidth_ = 0;
    int sampleHeight_ = 0;
    
    std::thread processingThread_;
    std::mutex frameMutex_;
    std::mutex colorMutex_;
    std::condition_variable frameCV_;
    
    std::queue<FrameBuffer> frameQueue_;
    ColorData latestColorData_;
    ColorData smoothedColorData_;
    
    static constexpr int MAX_QUEUE_SIZE = 2;
    static constexpr int DOWNSAMPLE_FACTOR = 8; // Process at 1/8 resolution
};

} // namespace AmbientLight

#endif // AMBIENT_LIGHT_EXTRACTOR_H
