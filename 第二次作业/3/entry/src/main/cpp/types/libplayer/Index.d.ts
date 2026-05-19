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

export class Response {
  code: number;
  message: string;
  videoWidth: number;
  videoHeight: number;
  durationTime: number;
}

export interface RGBColor {
  r: number;
  g: number;
  b: number;
}

export interface ColorData {
  dominantColor: RGBColor;
  averageColor: RGBColor;
  topColor: RGBColor;
  bottomColor: RGBColor;
  leftColor: RGBColor;
  rightColor: RGBColor;
  timestamp: number;
}

// Player methods
export const createPlayer: () => bigint;

export const releasePlayer: (objAddr: bigint) => void;

export const play: (objAddr: bigint) => void;

export const pause: (objAddr: bigint) => void;

export const resume: (objAddr: bigint) => void;

export const getRenderTime: (objAddr: bigint) => number;

export const setSpeed: (objAddr: bigint, speed: number) => void;

export const seekVideo: (objAddr: bigint, desTime: number) => Promise<void>;

export const init: (
  objAddr: bigint,
  inputFileFd: number,
  inputFileOffset: number,
  inputFileSize: number
) => Promise<Response>;

// Ambient Light methods
export const setEnabled: (enabled: boolean) => void;

export const isEnabled: () => boolean;

export const initialize: (videoWidth: number, videoHeight: number) => void;

export const release: () => void;

export const getColorData: () => ColorData;

export const setBrightness: (brightness: number) => void;

export const getBrightness: () => number;

export const setUpdateInterval: (intervalMs: number) => void;

export const setSmoothFactor: (factor: number) => void;