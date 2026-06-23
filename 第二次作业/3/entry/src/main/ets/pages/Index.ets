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

import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { VideoPlayView } from '../view/VideoPlayView';
import { VideoPlayViewModel, ContinueData } from '../viewmodel/VideoPlayViewModel';
import { ThemeColors } from '../common/ThemeColors';
import { BreakPointConstants } from '../common/BreakPointConstants';

const VIDEO_NAMES = ['1.mp4', '2.mp4', '3.mp4'];
const TAG = 'INDEX';
const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State videoResources : resourceManager.RawFileDescriptor[] = [];
  @State viewModel: VideoPlayViewModel = new VideoPlayViewModel();
  @State isFullScreen: boolean = false;
  @Provide('isDarkTheme') isDarkTheme: boolean = true;
  @Provide('themeColors') themeColors: ThemeColors = new ThemeColors(true);
  @StorageProp(BreakPointConstants.BREAK_POINT_KEY) currentBreakpoint: string = BreakPointConstants.SM;

  toggleTheme(): void {
    this.isDarkTheme = !this.isDarkTheme;
    this.themeColors = new ThemeColors(this.isDarkTheme);
  }

  aboutToAppear(): void {
    try {
      this.videoResources.length = 0;
      for (let i = 0; i< VIDEO_NAMES.length; i++) {
        let rawDes = this.getUIContext().getHostContext()?.resourceManager.getRawFdSync(VIDEO_NAMES[i]);
        if (rawDes) {
          this.videoResources.push(rawDes);
        }
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `aboutToAppear catch error, code: ${error.code}, message: ${error.message}`);
    }

    // 将 ViewModel 存入 AppStorage（供 EntryAbility 保存流转数据）
    AppStorage.setOrCreate('videoPlayViewModel', this.viewModel);

    // 检查是否有流转恢复数据
    this.checkAndRestoreContinueData();
  }

  /**
   * 检查并恢复流转数据
   */
  private async checkAndRestoreContinueData(): Promise<void> {
    try {
      const restoreDataStr = AppStorage.get<string>('restoreContinueData');
      if (restoreDataStr) {
        const data: ContinueData = JSON.parse(restoreDataStr) as ContinueData;
        hilog.info(DOMAIN, TAG, `Restoring from continuation: videoIndex=${data.chooseNumber}, time=${data.currentTime}`);

        // 先让 ViewModel 初始化
        this.viewModel.videoSources = this.videoResources;
        this.viewModel.setUIContext(this.getUIContext());
        await this.viewModel.initialize();

        // 恢复状态
        this.viewModel.restoreFromContinueData(data);

        // 重新加载对应视频并 seek 到之前的位置
        if (data.chooseNumber >= 0 && data.chooseNumber < this.videoResources.length) {
          const newState = await this.viewModel.onVideoSelected(data.chooseNumber, this.videoResources[data.chooseNumber]);
          if (newState !== null) {
            this.viewModel.playState = newState;
            // seek 到之前的播放位置
            if (data.currentTime > 0) {
              await this.viewModel.performSeek(data.currentTime);
              // 恢复后暂停，等待用户操作
              this.viewModel.playState = this.viewModel.togglePlayPause(this.viewModel.playState);
            }
          }
        }

        // 清除恢复数据标记
        AppStorage.delete('restoreContinueData');
        hilog.info(DOMAIN, TAG, 'Continuation restore completed');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `checkAndRestoreContinueData error: ${error.code}, ${error.message}`);
    }
  }

  aboutToDisappear(): void {
    try {
      for (let i = 0; i< VIDEO_NAMES.length; i++) {
        this.getUIContext().getHostContext()?.resourceManager.closeRawFdSync(VIDEO_NAMES[i]);
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `aboutToDisappear catch error, code: ${error.code}, message: ${error.message}`);
    }
  }

  onBackPress(): boolean | void {
    if (this.isFullScreen) {
      this.isFullScreen = false;
      return true;
    }
    return false;
  }

  build() {
    Column() {
      VideoPlayView({
        viewModel: this.viewModel,
        videoSources: $videoResources,
        isFullScreen: this.isFullScreen,
        currentBreakpoint: this.currentBreakpoint
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.pageBackground)
  }
}
