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

/**
 * RGB Color class - simple class, no @Observed
 */
export class RGBColor {
  r: number = 128;
  g: number = 128;
  b: number = 128;

  constructor(r: number = 128, g: number = 128, b: number = 128) {
    this.r = r;
    this.g = g;
    this.b = b;
  }
}

/**
 * Color data extracted from video frame - simple class, no @Observed
 */
export class ColorData {
  dominantColor: RGBColor = new RGBColor();
  averageColor: RGBColor = new RGBColor();
  topColor: RGBColor = new RGBColor();
  bottomColor: RGBColor = new RGBColor();
  leftColor: RGBColor = new RGBColor();
  rightColor: RGBColor = new RGBColor();
  timestamp: number = 0;

  constructor(data?: ESObject) {
    if (data !== undefined) {
      this.parseFromNative(data);
    }
  }

  private parseFromNative(data: ESObject): void {
    if (data.dominantColor !== undefined) {
      const dc: ESObject = data.dominantColor as ESObject;
      this.dominantColor = new RGBColor(dc.r as number, dc.g as number, dc.b as number);
    }
    if (data.averageColor !== undefined) {
      const ac: ESObject = data.averageColor as ESObject;
      this.averageColor = new RGBColor(ac.r as number, ac.g as number, ac.b as number);
    }
    if (data.topColor !== undefined) {
      const tc: ESObject = data.topColor as ESObject;
      this.topColor = new RGBColor(tc.r as number, tc.g as number, tc.b as number);
    }
    if (data.bottomColor !== undefined) {
      const bc: ESObject = data.bottomColor as ESObject;
      this.bottomColor = new RGBColor(bc.r as number, bc.g as number, bc.b as number);
    }
    if (data.leftColor !== undefined) {
      const lc: ESObject = data.leftColor as ESObject;
      this.leftColor = new RGBColor(lc.r as number, lc.g as number, lc.b as number);
    }
    if (data.rightColor !== undefined) {
      const rc: ESObject = data.rightColor as ESObject;
      this.rightColor = new RGBColor(rc.r as number, rc.g as number, rc.b as number);
    }
    if (data.timestamp !== undefined) {
      this.timestamp = data.timestamp as number;
    }
  }
}

/**
 * Helper to construct ColorData from individual color values
 */
export class ColorDataImpl extends ColorData {
  constructor(dominantColor: RGBColor, averageColor: RGBColor, topColor: RGBColor,
              bottomColor: RGBColor, leftColor: RGBColor, rightColor: RGBColor,
              timestamp: number) {
    super();
    this.dominantColor = dominantColor;
    this.averageColor = averageColor;
    this.topColor = topColor;
    this.bottomColor = bottomColor;
    this.leftColor = leftColor;
    this.rightColor = rightColor;
    this.timestamp = timestamp;
  }
}

/**
 * Ambient light configuration - simple class, no @Observed
 */
export class AmbientLightConfig {
  enabled: boolean = false;
  brightness: number = 0.8;
  updateInterval: number = 100;
  smoothFactor: number = 0.3;
  flowSpeed: FlowSpeed = FlowSpeed.MEDIUM;
}

/**
 * Flow speed options
 */
export enum FlowSpeed {
  SLOW = 0,
  MEDIUM = 1,
  FAST = 2
}

/**
 * Convert RGBColor to hex string
 */
export function rgbToHex(color: RGBColor): string {
  const toHex = (n: number): string => {
    const hex = Math.round(n).toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  };
  return `#${toHex(color.r)}${toHex(color.g)}${toHex(color.b)}`;
}

/**
 * Convert RGBColor to rgba string with alpha
 */
export function rgbToRgba(color: RGBColor, alpha: number): string {
  return `rgba(${Math.round(color.r)}, ${Math.round(color.g)}, ${Math.round(color.b)}, ${alpha})`;
}

/**
 * Blend two colors
 */
export function blendColors(color1: RGBColor, color2: RGBColor, ratio: number): RGBColor {
  const r = color1.r * (1 - ratio) + color2.r * ratio;
  const g = color1.g * (1 - ratio) + color2.g * ratio;
  const b = color1.b * (1 - ratio) + color2.b * ratio;
  return new RGBColor(r, g, b);
}

/**
 * Default ambient light configuration
 */
export const DEFAULT_CONFIG: AmbientLightConfig = new AmbientLightConfig();

/**
 * Flow speed to update interval mapping
 */
export class FlowSpeedIntervals {
  static getInterval(speed: FlowSpeed): number {
    if (speed === FlowSpeed.SLOW) {
      return 200;
    } else if (speed === FlowSpeed.MEDIUM) {
      return 100;
    } else {
      return 50;
    }
  }
}
