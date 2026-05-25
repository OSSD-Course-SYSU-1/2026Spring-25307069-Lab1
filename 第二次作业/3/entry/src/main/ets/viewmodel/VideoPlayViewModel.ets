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
import { window } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { PlayerState } from '../model/PlayerStateModel';
import { CommonConstants as Const } from '../common/CommonConstants';
import player from 'libplayer.so';
import { AmbientLightManager } from '../ambientlight/AmbientLightManager';

const DOMAIN = 0x0000;
const TAG = 'VideoPlayViewModel';

export interface DanmakuItem {
  id: string;
  text: string;
  color: string;
  left: number;
  top: number;
}

export interface WindowSystemBarProperties {
  statusBarContentColor: string;
}

@Observed
export class VideoPlayViewModel {
  @Track chooseNumber: number = -1;
  @Track chooseSpeed: number = Const.VIDEO_DEFAULT_SPEED;
  @Track isUse: boolean = false;
  @Track controlsVisible: boolean = true;
  // Controls auto-hide timer
  private controlsHideTimerId: number = -1;
  private readonly CONTROLS_HIDE_DELAY: number = 5000; // 5 seconds
  @Track isSpeedListVisible: boolean = false;
  @Track isSwitchEnable: boolean = true;
  @Track currentTime: number = 0;
  @Track durationTime: number = 0;
  @Track speedText: string | Resource = $r('app.string.Default_speed_text');
  @Track isSeek: boolean = false;
  @Track playState: PlayerState = PlayerState.IDLE;
  @Track danmakuList: DanmakuItem[] = [];
  @Track selectedDanmakuColor: string = '#FFFFFF';
  @Track isColorPanelVisible: boolean = false;
  @Track danmakuInputText: string = '';

  // Ambient light manager
  @Track ambientLightManager: AmbientLightManager = new AmbientLightManager();

  // Ambient light color - updated based on video playback state
  @Track ambientLightColor: string = '#FF6600';
  private ambientLightTimerId: number = -1;
  private ambientLightColorIndex: number = 0;
  private readonly ambientLightPalette: string[] = [
    '#FF6600', '#3366FF', '#FF3366', '#33CC66',
    '#9933FF', '#FFCC00', '#FF3333', '#33CCCC'
  ];

  public videoSources: resourceManager.RawFileDescriptor[] = [];
  private danmakuIdCounter: number = 0;
  public nativePlayerObj: bigint = BigInt(0);
  private timerId: number = -1;
  private danmakuTimerId: number = -1;
  private danmakuLastTimestamp: number = 0;
  private hostContext: Context | undefined = undefined;

  setUIContext(uiContext: UIContext): void {
    this.hostContext = uiContext.getHostContext();
  }

  async initialize(): Promise<void> {
    try {
      await this.setWindowProperties();
      this.registerEventListeners();
      this.startTimer();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `initialize catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  async setWindowProperties(): Promise<void> {
    if (!this.hostContext) {
      return;
    }
    try {
      const topWindow = await window.getLastWindow(this.hostContext);
      const props: WindowSystemBarProperties = {
        statusBarContentColor: '#FFFFFF'
      };
      await topWindow.setWindowSystemBarProperties(props);
      await topWindow.setWindowKeepScreenOn(true);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to set window properties. Cause: ${error.code}, message: ${error.message}`);
    }
  }

  registerEventListeners(): void {
    if (!this.hostContext) {
      return;
    }
    this.hostContext.eventHub.on('onBackground', () => this.onBackground());
    this.hostContext.eventHub.on('onForeground', () => this.onForeground());
  }

  unregisterEventListeners(): void {
    if (!this.hostContext) {
      return;
    }
    this.hostContext.eventHub.off('onBackground');
    this.hostContext.eventHub.off('onForeground');
  }

  startTimer(): void {
    this.stopTimer();
    this.timerId = setInterval(() => {
      if (this.nativePlayerObj === BigInt(0)) {
        return;
      }
      if (!this.isSeek) {
        try {
          const renderTime = player.getRenderTime(this.nativePlayerObj);
          this.currentTime = renderTime / Const.TIME_RATIO;
        } catch (error) {
          hilog.error(DOMAIN, TAG, `getRenderTime failed`);
        }
      }
    }, Const.TIME_INTERVAL);
    this.startDanmakuTimer();
    this.startAmbientLightTimer();
  }

  stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.stopAmbientLightTimer();
  }

  /**
   * Start ambient light color timer - only updates when video is playing
   */
  private startAmbientLightTimer(): void {
    this.stopAmbientLightTimer();
    this.ambientLightTimerId = setInterval(() => {
      // Only update color when video is playing (not paused)
      if (this.playState === PlayerState.PLAYING) {
        // Calculate color index based on current playback time
        // This simulates color following video content
        const timeBasedIndex = Math.floor(this.currentTime / 2) % this.ambientLightPalette.length;
        if (timeBasedIndex !== this.ambientLightColorIndex) {
          this.ambientLightColorIndex = timeBasedIndex;
          this.ambientLightColor = this.ambientLightPalette[this.ambientLightColorIndex];
          hilog.info(DOMAIN, TAG, `Ambient light color changed to: ${this.ambientLightColor}`);
        }
      }
    }, 500); // Check every 500ms
  }

  /**
   * Stop ambient light color timer
   */
  private stopAmbientLightTimer(): void {
    if (this.ambientLightTimerId !== -1) {
      clearInterval(this.ambientLightTimerId);
      this.ambientLightTimerId = -1;
    }
  }

  startDanmakuTimer(): void {
    this.stopDanmakuTimer();
    this.danmakuLastTimestamp = Date.now();
    hilog.info(DOMAIN, TAG, 'startDanmakuTimer called');
    // time-delta based updates targeting ~60fps for smooth motion
    this.danmakuTimerId = setInterval(() => {
      const now = Date.now();
      const deltaMs = now - this.danmakuLastTimestamp;
      if (deltaMs <= 0) {
        this.danmakuLastTimestamp = now;
        return;
      }
      this.danmakuLastTimestamp = now;
      if (this.danmakuList.length === 0) {
        return;
      }
      // speed in percent-per-second (how many percent of width per second)
      const speedPercentPerSecond = 35; // tuneable: 35% width per second as requested
      const deltaPercent = (speedPercentPerSecond * deltaMs) / 1000.0;
      const nextList: DanmakuItem[] = [];
      for (const item of this.danmakuList) {
        const nextLeft = item.left - deltaPercent;
        if (nextLeft >= -120) {
          nextList.push({
            id: item.id,
            text: item.text,
            color: item.color,
            left: nextLeft,
            top: item.top
          });
        }
      }
      // debug: log first few left values to verify movement
      try {
        if (nextList.length > 0) {
          const lefts = nextList.map((n) => Math.round(n.left * 100) / 100).slice(0, 5).join(',');
          hilog.info(DOMAIN, TAG, `Danmaku update lefts: ${lefts}`);
        }
      } catch (e) {
        // ignore logging errors
      }
      this.danmakuList = nextList;
    }, 16);
  }

  stopDanmakuTimer(): void {
    if (this.danmakuTimerId !== -1) {
      clearInterval(this.danmakuTimerId);
      this.danmakuTimerId = -1;
    }
  }

  onBackground(): void {
    if (this.nativePlayerObj !== BigInt(0)) {
      player.pause(this.nativePlayerObj);
    }
  }

  onForeground(): void {
    if (this.playState === PlayerState.PLAYING) {
      if (this.nativePlayerObj !== BigInt(0)) {
        player.resume(this.nativePlayerObj);
      }
    }
  }

  togglePlayPause(playState: PlayerState): PlayerState {
    if (this.nativePlayerObj === BigInt(0)) {
      return playState;
    }
    if (playState === PlayerState.PLAYING) {
      player.pause(this.nativePlayerObj);
      // Paused: stop auto-hide, keep controls visible
      this.stopControlsHideTimer();
      return PlayerState.PAUSE;
    } else if (playState === PlayerState.PAUSE) {
      player.resume(this.nativePlayerObj);
      // Resumed: restart auto-hide
      this.startControlsHideTimer();
      return PlayerState.PLAYING;
    }
    return playState;
  }

  async performSeek(value: number): Promise<void> {
    if (this.nativePlayerObj === BigInt(0)) {
      this.isSeek = false;
      return;
    }
    try {
      hilog.info(DOMAIN, TAG, `Performing seek to ${value}s`);
      await player.seekVideo(this.nativePlayerObj, value);
      // Keep isSeek true for a short time to allow player to stabilize
      setTimeout(() => {
        this.isSeek = false;
        hilog.info(DOMAIN, TAG, `Seek complete, isSeek=${this.isSeek}`);
      }, Const.RELOAD_TIME);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Seek failed`);
      this.isSeek = false;
    }
  }

  toggleSpeedList(): void {
    this.isSpeedListVisible = true;
  }

  toggleColorPanel(): void {
    this.isColorPanelVisible = !this.isColorPanelVisible;
  }

  hideColorPanel(): void {
    this.isColorPanelVisible = false;
  }

  /**
   * Show controls and start auto-hide timer
   */
  showControls(): void {
    if (!this.isUse) {
      return;
    }
    this.stopControlsHideTimer();
    this.controlsVisible = true;
    this.startControlsHideTimer();
  }

  /**
   * Toggle controls visibility
   */
  toggleControls(): void {
    if (!this.isUse) {
      return;
    }
    // When paused, never hide controls
    if (this.playState === PlayerState.PAUSE) {
      if (!this.controlsVisible) {
        this.showControls();
      }
      return;
    }
    if (this.controlsVisible) {
      // Already visible: just reset the auto-hide timer
      this.startControlsHideTimer();
    } else {
      this.showControls();
    }
  }

  /**
   * Hide controls immediately
   */
  private hideControls(): void {
    this.controlsVisible = false;
    this.stopControlsHideTimer();
  }

  private startControlsHideTimer(): void {
    this.stopControlsHideTimer();
    this.controlsHideTimerId = setTimeout(() => {
      this.controlsVisible = false;
      this.controlsHideTimerId = -1;
    }, this.CONTROLS_HIDE_DELAY);
  }

  private stopControlsHideTimer(): void {
    if (this.controlsHideTimerId !== -1) {
      clearTimeout(this.controlsHideTimerId);
      this.controlsHideTimerId = -1;
    }
  }

  selectDanmakuColor(color: string): void {
    this.selectedDanmakuColor = color;
    hilog.info(DOMAIN, TAG, `Selected danmaku color: ${color}`);
    this.hideColorPanel();
  }

  sendDanmaku(text?: string): void {
    const content = (typeof text === 'string' ? text : this.danmakuInputText || '').trim();
    if (!content) {
      return;
    }
    // simple track assignment: rotate among 5 tracks
    const trackCount = 5;
    const topBase = 8; // percent from top of video selection area
    const trackIndex = this.danmakuList.length % trackCount;
    const topPercent = topBase + trackIndex * 6; // percent values
    const item: DanmakuItem = {
      id: `danmaku_${this.danmakuIdCounter++}`,
      text: content,
      color: this.selectedDanmakuColor || '#FFFFFF',
      left: 90,
      top: topPercent
    };
    this.danmakuList = [...this.danmakuList, item];
    hilog.info(DOMAIN, TAG, `Send danmaku: ${item.text} color:${item.color}`);
    hilog.info(DOMAIN, TAG, `Danmaku added with left=${item.left}`);
    // clear input
    this.danmakuInputText = '';
  }

  hideSpeedList(): void {
    if (this.isSpeedListVisible) {
      this.isSpeedListVisible = false;
    }
  }

  onSpeedSelected(speed: number, index: number): void {
    if (this.chooseSpeed !== speed) {
      this.chooseSpeed = speed;
      if (this.nativePlayerObj !== BigInt(0)) {
        player.setSpeed(this.nativePlayerObj, speed);
      }
      this.speedText = Const.VIDEO_SPEED_TEXT_ARR[index];
      this.isSpeedListVisible = false;
    }
  }

  async onVideoSelected(index: number, rawDes: resourceManager.RawFileDescriptor): Promise<PlayerState | null> {
    if (this.chooseNumber === index) {
      return null;
    }
    this.isSwitchEnable = false;
    this.durationTime = 0;
    this.chooseNumber = index;
    this.isUse = false;
    this.chooseSpeed = Const.VIDEO_DEFAULT_SPEED;
    this.speedText = $r('app.string.Default_speed_text');
    if (!rawDes) {
      hilog.error(DOMAIN, TAG, 'player inputFile is null');
      this.isSwitchEnable = true;
      return null;
    }
    try {
      await this.releasePlayer();
      this.nativePlayerObj = player.createPlayer();
      const data = await player.init(this.nativePlayerObj, rawDes.fd, rawDes.offset, rawDes.length);
      this.isSeek = false;
      if (data.code === 0) {
        this.durationTime = data.durationTime / Const.TIME_RATIO;
        this.isUse = true;
        this.controlsVisible = true;
        this.startControlsHideTimer();
        this.isSwitchEnable = true;
        // Initialize ambient light with video dimensions
        if (data.videoWidth && data.videoHeight) {
          this.ambientLightManager.initialize(data.videoWidth, data.videoHeight);
        }
        player.play(this.nativePlayerObj);
        return PlayerState.PLAYING;
      } else {
        hilog.error(DOMAIN, TAG, 'player init failed, err code is ' + data.code);
        await this.releasePlayer();
      }
      this.isSwitchEnable = true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Switch video failed: ${error.code}, message: ${error.message}`);
      await this.releasePlayer();
      this.isSwitchEnable = true;
    }
    return null;
  }

  async releasePlayer(): Promise<void> {
    if (this.nativePlayerObj !== BigInt(0)) {
      try {
        player.releasePlayer(this.nativePlayerObj);
        this.nativePlayerObj = BigInt(0);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Release player failed: ${error.code}, message: ${error.message}`);
      }
    }
  }

  // === Gesture Control Methods ===

  /**
   * Seek forward/backward by delta seconds
   */
  async seekByDelta(deltaSeconds: number): Promise<void> {
    if (this.nativePlayerObj === BigInt(0) || !this.isUse) {
      return;
    }
    const newTime = Math.max(0, Math.min(this.currentTime + deltaSeconds, this.durationTime));
    await this.performSeek(newTime);
    hilog.info(DOMAIN, TAG, `Seek by ${deltaSeconds}s to ${newTime}s`);
  }

  async cleanup(): Promise<void> {
    try {
      this.stopTimer();
      this.stopDanmakuTimer();
      this.unregisterEventListeners();
      await this.releasePlayer();
      // Release ambient light resources
      this.ambientLightManager.release();
    } catch (error) {
      hilog.error(0x0000, TAG, `cleanup catch error, code: ${error.code}, message: ${error.message}`);
    }
  }
}
