/*
 * AVPlayer Manager for local video playback
 * Based on system AVPlayer component, supports local file URI and network URL
 */

import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AVPlayerManager';

export class AVPlayerManager {
  private avPlayer: media.AVPlayer | null = null;
  private surfaceId: string = '';
  private currentDuration: number = 0;
  private currentTimeMs: number = 0;
  private isPrepared: boolean = false;

  // Callbacks
  onTimeUpdate?: (timeMs: number) => void;
  onDurationUpdate?: (durationMs: number) => void;
  onStateChange?: (state: string) => void;
  onError?: (error: Error) => void;

  async init(surfaceId: string): Promise<void> {
    this.surfaceId = surfaceId;
    try {
      this.avPlayer = await media.createAVPlayer();
      this.setupCallbacks();
      hilog.info(DOMAIN, TAG, `AVPlayer created, surfaceId: ${surfaceId}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to create AVPlayer`);
    }
  }

  private setupCallbacks(): void {
    if (!this.avPlayer) return;

    this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      hilog.info(DOMAIN, TAG, `AVPlayer state: ${state}, reason: ${reason}`);
      switch (state) {
        case 'initialized':
          this.avPlayer!.surfaceId = this.surfaceId;
          this.avPlayer!.prepare();
          break;
        case 'prepared':
          this.isPrepared = true;
          this.currentDuration = this.avPlayer!.duration;
          this.currentTimeMs = this.avPlayer!.currentTime;
          this.onDurationUpdate?.(this.currentDuration);
          this.onTimeUpdate?.(this.currentTimeMs);
          this.avPlayer!.play();
          this.onStateChange?.('playing');
          break;
        case 'playing':
          this.onStateChange?.('playing');
          break;
        case 'paused':
          this.onStateChange?.('paused');
          break;
        case 'completed':
          this.onStateChange?.('completed');
          break;
        case 'stopped':
          this.isPrepared = false;
          break;
        default:
          break;
      }
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.currentTimeMs = time;
      this.onTimeUpdate?.(time);
    });

    this.avPlayer.on('durationUpdate', (duration: number) => {
      this.currentDuration = duration;
      this.onDurationUpdate?.(duration);
    });

    this.avPlayer.on('error', (err: Error) => {
      hilog.error(DOMAIN, TAG, `AVPlayer error: ${err.message}`);
      this.onError?.(err);
    });
  }

  /**
   * Set video source by URI (local file:// or network http(s)://)
   */
  async setSource(uri: string): Promise<void> {
    if (!this.avPlayer) {
      hilog.error(DOMAIN, TAG, 'AVPlayer not initialized');
      return;
    }
    try {
      this.isPrepared = false;
      this.currentDuration = 0;
      this.currentTimeMs = 0;
      await this.avPlayer.reset();
      this.avPlayer.url = uri;
      hilog.info(DOMAIN, TAG, `AVPlayer source set: ${uri}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to set source`);
    }
  }

  async play(): Promise<void> {
    if (this.avPlayer && this.isPrepared) {
      try {
        await this.avPlayer.play();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Play failed`);
      }
    }
  }

  async pause(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.pause();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Pause failed`);
      }
    }
  }

  async resume(): Promise<void> {
    if (this.avPlayer && this.isPrepared) {
      try {
        await this.avPlayer.play();
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Resume failed`);
      }
    }
  }

  async seek(timeMs: number): Promise<void> {
    if (this.avPlayer && this.isPrepared) {
      try {
        await this.avPlayer.seek(timeMs, media.SeekMode.SEEK_PREV_SYNC);
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Seek failed`);
      }
    }
  }

  async setSpeed(speed: number): Promise<void> {
    if (!this.avPlayer) return;
    try {
      let playbackSpeed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
      if (speed <= 0.75) {
        playbackSpeed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
      } else if (speed <= 1.0) {
        playbackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
      } else if (speed <= 1.25) {
        playbackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_25_X;
      } else if (speed <= 1.75) {
        playbackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_75_X;
      } else {
        playbackSpeed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
      }
      await this.avPlayer.setSpeed(playbackSpeed);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `SetSpeed failed`);
    }
  }

  getDuration(): number {
    return this.currentDuration;
  }

  getCurrentTime(): number {
    return this.currentTimeMs;
  }

  get isPlaying(): boolean {
    return this.avPlayer?.state === 'playing';
  }

  async release(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.release();
        hilog.info(DOMAIN, TAG, 'AVPlayer released');
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Release failed`);
      }
      this.avPlayer = null;
      this.isPrepared = false;
    }
  }
}
