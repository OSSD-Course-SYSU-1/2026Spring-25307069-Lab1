import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { Logger } from '../utils/Logger';

export class AudioService {
  private avPlayer: media.AVPlayer | null = null;
  private currentSound: string = '';

  async play(soundName: string): Promise<void> {
    if (soundName === '无' || soundName === this.currentSound) return;
    await this.stop();
    try {
      this.avPlayer = await media.createAVPlayer();
      const soundMap: Record<string, string> = { '雨声': 'rain.mp3', '海浪': 'ocean.mp3', '森林': 'forest.mp3', '风声': 'wind.mp3' };
      const file = soundMap[soundName];
      if (file) {
        // 内置音效：通过 rawfile 播放
        const fd = await getContext().resourceManager.getRawFd(file);
        this.avPlayer.fdSrc = fd;
      } else {
        // 自定义音效：通过文件 URI 播放
        this.avPlayer.url = soundName;
      }
      this.avPlayer.setVolume(0.5);
      this.avPlayer.loop = true;
      this.avPlayer.on('stateChange', (state: string) => {
        if (state === 'prepared') {
          this.avPlayer?.play();
          this.currentSound = soundName;
        }
      });
      this.avPlayer.prepare();
      Logger.info(`播放: ${soundName}`);
    } catch (e) { Logger.error(`播放失败: ${JSON.stringify(e)}`); }
  }

  async playByUri(uri: string): Promise<void> {
    if (uri === this.currentSound) return;
    await this.stop();
    try {
      this.avPlayer = await media.createAVPlayer();
      this.avPlayer.url = uri;
      this.avPlayer.setVolume(0.5);
      this.avPlayer.loop = true;
      this.avPlayer.on('stateChange', (state: string) => {
        if (state === 'prepared') {
          this.avPlayer?.play();
          this.currentSound = uri;
        }
      });
      this.avPlayer.prepare();
      Logger.info(`播放自定义音频: ${uri}`);
    } catch (e) { Logger.error(`播放自定义音频失败: ${JSON.stringify(e)}`); }
  }

  async stop(): Promise<void> {
    if (this.avPlayer) {
      try { await this.avPlayer.stop(); await this.avPlayer.release(); } catch (e) { /* ignore */ }
      this.avPlayer = null;
      this.currentSound = '';
    }
  }
}
