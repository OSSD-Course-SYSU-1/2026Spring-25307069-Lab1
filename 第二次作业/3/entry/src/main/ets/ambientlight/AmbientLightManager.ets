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

import { hilog } from '@kit.PerformanceAnalysisKit';
import player from 'libplayer.so';
import {
  ColorData,
  ColorDataImpl,
  RGBColor,
  AmbientLightConfig,
  FlowSpeed,
  DEFAULT_CONFIG,
  FlowSpeedIntervals,
  rgbToHex,
  blendColors
} from './AmbientLightTypes';

const DOMAIN = 0xFF00;
const TAG = 'AmbientLightManager';

/**
 * Ambient Light Manager - handles color extraction and UI updates
 * Using simple class without @Observed to avoid decorator conflicts
 */
export class AmbientLightManager {
  // Current color data
  currentColors: ColorData = new ColorData();

  // Configuration
  config: AmbientLightConfig = new AmbientLightConfig();

  // Animation offset for flowing effect
  flowOffset: number = 0;

  // Callback for state change notification
  onStateChange?: () => void;

  private updateTimerId: number = -1;
  private animationTimerId: number = -1;
  private isInitialized: boolean = false;

  /**
   * Initialize ambient light with video dimensions
   */
  initialize(videoWidth: number, videoHeight: number): void {
    if (this.isInitialized) {
      return;
    }

    try {
      player.initialize(videoWidth, videoHeight);
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, `Initialized with dimensions: ${videoWidth}x${videoHeight}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize: ${error.message}`);
    }
  }

  /**
   * Release resources
   */
  release(): void {
    this.stopUpdateTimer();
    this.stopAnimationTimer();

    if (this.isInitialized) {
      try {
        player.release();
        this.isInitialized = false;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Failed to release: ${error.message}`);
      }
    }
  }

  /**
   * Enable/disable ambient light
   */
  setEnabled(enabled: boolean): void {
    this.config.enabled = enabled;

    try {
      player.setEnabled(enabled);

      if (enabled) {
        this.startUpdateTimer();
        this.startAnimationTimer();
      } else {
        this.stopUpdateTimer();
        this.stopAnimationTimer();
      }

      hilog.info(DOMAIN, TAG, `Ambient light ${enabled ? 'enabled' : 'disabled'}`);
      
      // Notify state change
      if (this.onStateChange) {
        this.onStateChange();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to set enabled: ${error.message}`);
    }
  }

  /**
   * Check if ambient light is enabled
   */
  isEnabled(): boolean {
    return this.config.enabled;
  }

  /**
   * Set brightness (0.0 - 1.0)
   */
  setBrightness(brightness: number): void {
    this.config.brightness = Math.max(0, Math.min(1, brightness));

    try {
      player.setBrightness(this.config.brightness);
      hilog.info(DOMAIN, TAG, `Brightness set to: ${this.config.brightness}`);
      
      if (this.onStateChange) {
        this.onStateChange();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to set brightness: ${error.message}`);
    }
  }

  /**
   * Get current brightness
   */
  getBrightness(): number {
    return this.config.brightness;
  }

  /**
   * Set flow speed
   */
  setFlowSpeed(speed: FlowSpeed): void {
    this.config.flowSpeed = speed;
    this.config.updateInterval = FlowSpeedIntervals.getInterval(speed);

    try {
      player.setUpdateInterval(this.config.updateInterval);
      hilog.info(DOMAIN, TAG, `Flow speed set to: ${speed}, interval: ${this.config.updateInterval}ms`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to set flow speed: ${error.message}`);
    }

    // Restart timer with new interval if running
    if (this.config.enabled) {
      this.startUpdateTimer();
    }
    
    if (this.onStateChange) {
      this.onStateChange();
    }
  }

  /**
   * Get current flow speed
   */
  getFlowSpeed(): FlowSpeed {
    return this.config.flowSpeed;
  }

  /**
   * Start color update timer
   */
  private startUpdateTimer(): void {
    this.stopUpdateTimer();

    this.updateTimerId = setInterval(() => {
      this.fetchColorData();
    }, this.config.updateInterval);
  }

  /**
   * Stop color update timer
   */
  private stopUpdateTimer(): void {
    if (this.updateTimerId !== -1) {
      clearInterval(this.updateTimerId);
      this.updateTimerId = -1;
    }
  }

  /**
   * Start animation timer for flowing effect
   */
  private startAnimationTimer(): void {
    this.stopAnimationTimer();

    // 60fps animation
    this.animationTimerId = setInterval(() => {
      this.flowOffset = (this.flowOffset + 0.02) % (Math.PI * 2);
      
      if (this.onStateChange) {
        this.onStateChange();
      }
    }, 16);
  }

  /**
   * Stop animation timer
   */
  private stopAnimationTimer(): void {
    if (this.animationTimerId !== -1) {
      clearInterval(this.animationTimerId);
      this.animationTimerId = -1;
    }
  }

  /**
   * Fetch color data from native layer or generate demo colors
   */
  private fetchColorData(): void {
    try {
      // Try to get real color data from native layer
      const raw = player.getColorData();
      
      // Check if we got valid color data (non-zero timestamp means valid data)
      if (raw && raw.timestamp > 0) {
        const colorData: ColorData = new ColorData(raw);
        // Apply smooth transition
        this.currentColors = new ColorDataImpl(
          this.smoothColorTransition(this.currentColors.dominantColor, colorData.dominantColor),
          this.smoothColorTransition(this.currentColors.averageColor, colorData.averageColor),
          this.smoothColorTransition(this.currentColors.topColor, colorData.topColor),
          this.smoothColorTransition(this.currentColors.bottomColor, colorData.bottomColor),
          this.smoothColorTransition(this.currentColors.leftColor, colorData.leftColor),
          this.smoothColorTransition(this.currentColors.rightColor, colorData.rightColor),
          colorData.timestamp
        );
      } else {
        // Generate demo colors if no valid data from native layer
        this.generateDemoColors();
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, `Native color data not available, using demo mode`);
      this.generateDemoColors();
    }
    
    if (this.onStateChange) {
      this.onStateChange();
    }
  }

  /**
   * Generate demo colors for testing (when native layer doesn't provide colors)
   */
  private demoColorIndex: number = 0;
  private readonly demoColors: RGBColor[] = [
    new RGBColor(255, 100, 50),   // Orange
    new RGBColor(50, 150, 255),   // Blue
    new RGBColor(255, 50, 150),   // Pink
    new RGBColor(50, 255, 100),   // Green
    new RGBColor(150, 50, 255),   // Purple
    new RGBColor(255, 200, 50),   // Yellow
    new RGBColor(255, 80, 80),    // Red
    new RGBColor(80, 255, 255),   // Cyan
  ];

  private generateDemoColors(): void {
    // Cycle through demo colors
    const baseColor = this.demoColors[this.demoColorIndex % this.demoColors.length];
    this.demoColorIndex++;

    // Create variations for different edges
    const topColor = new RGBColor(
      Math.min(255, baseColor.r + 30),
      Math.min(255, baseColor.g + 30),
      Math.min(255, baseColor.b + 30)
    );
    const bottomColor = new RGBColor(
      Math.max(0, baseColor.r - 30),
      Math.max(0, baseColor.g - 30),
      Math.max(0, baseColor.b - 30)
    );
    const leftColor = new RGBColor(
      Math.min(255, baseColor.r + 50),
      baseColor.g,
      Math.max(0, baseColor.b - 20)
    );
    const rightColor = new RGBColor(
      Math.max(0, baseColor.r - 20),
      baseColor.g,
      Math.min(255, baseColor.b + 50)
    );

    this.currentColors = new ColorDataImpl(
      this.smoothColorTransition(this.currentColors.dominantColor, baseColor),
      this.smoothColorTransition(this.currentColors.averageColor, baseColor),
      this.smoothColorTransition(this.currentColors.topColor, topColor),
      this.smoothColorTransition(this.currentColors.bottomColor, bottomColor),
      this.smoothColorTransition(this.currentColors.leftColor, leftColor),
      this.smoothColorTransition(this.currentColors.rightColor, rightColor),
      Date.now()
    );
  }

  /**
   * Smooth color transition
   */
  private smoothColorTransition(current: RGBColor, target: RGBColor): RGBColor {
    return blendColors(current, target, 0.3);
  }

  /**
   * Get gradient colors for top edge
   */
  getTopGradientColors(): [string, string, string, string] {
    const c = this.currentColors;

    return [
      rgbToHex(c.topColor),
      rgbToHex(blendColors(c.topColor, c.leftColor, 0.3)),
      rgbToHex(blendColors(c.topColor, c.rightColor, 0.3)),
      rgbToHex(c.averageColor)
    ];
  }

  /**
   * Get gradient colors for bottom edge
   */
  getBottomGradientColors(): [string, string, string, string] {
    const c = this.currentColors;

    return [
      rgbToHex(c.bottomColor),
      rgbToHex(blendColors(c.bottomColor, c.leftColor, 0.3)),
      rgbToHex(blendColors(c.bottomColor, c.rightColor, 0.3)),
      rgbToHex(c.averageColor)
    ];
  }

  /**
   * Get gradient colors for left edge
   */
  getLeftGradientColors(): [string, string] {
    const c = this.currentColors;

    return [
      rgbToHex(c.leftColor),
      rgbToHex(blendColors(c.leftColor, c.averageColor, 0.5))
    ];
  }

  /**
   * Get gradient colors for right edge
   */
  getRightGradientColors(): [string, string] {
    const c = this.currentColors;

    return [
      rgbToHex(c.rightColor),
      rgbToHex(blendColors(c.rightColor, c.averageColor, 0.5))
    ];
  }

  /**
   * Get dominant color as hex
   */
  getDominantColorHex(): string {
    return rgbToHex(this.currentColors.dominantColor);
  }

  /**
   * Get average color as hex
   */
  getAverageColorHex(): string {
    return rgbToHex(this.currentColors.averageColor);
  }
}
