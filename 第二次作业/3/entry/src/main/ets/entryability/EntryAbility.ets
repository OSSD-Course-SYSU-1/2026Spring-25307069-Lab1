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

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BreakPointManager } from '../common/BreakPointManager';
import { VideoPlayViewModel } from '../viewmodel/VideoPlayViewModel';

const DOMAIN = 0x0000;
const TAG = 'ENTRY';

export default class EntryAbility extends UIAbility {
  private breakPointManager: BreakPointManager = new BreakPointManager();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');

      // 检查是否为流转恢复
      if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
        this.handleContinuation(want);
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `onCreate catch error, code: ${error.code}, message: ${error.message}`);
      return;
    }
  }

  /**
   * 源端：保存迁移数据
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onContinue');

    try {
      // 从 AppStorage 获取 ViewModel 保存的流转数据
      const continueDataStr = AppStorage.get<string>('continueData');
      if (continueDataStr) {
        wantParam['continueData'] = continueDataStr;
        hilog.info(DOMAIN, TAG, `Continue data saved, length: ${continueDataStr.length}`);
        return AbilityConstant.OnContinueResult.AGREE;
      }
      // 没有可迁移的数据也同意（用户可能在首页未播放）
      return AbilityConstant.OnContinueResult.AGREE;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `onContinue error: ${error.code}, ${error.message}`);
      return AbilityConstant.OnContinueResult.REJECT;
    }
  }

  /**
   * 对端：恢复迁移数据
   */
  private handleContinuation(want: Want): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Handling continuation restore');

    if (want.parameters !== undefined) {
      const continueDataStr = want.parameters['continueData'] as string;
      if (continueDataStr) {
        AppStorage.setOrCreate('restoreContinueData', continueDataStr);
        hilog.info(DOMAIN, TAG, 'Continue data restored from source device');
      }
    }

    // 设置迁移状态为 ACTIVE
    this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE);
  }

  onDestroy(): void {
    this.breakPointManager.release();
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    // 初始化断点管理
    this.breakPointManager.init(windowStage);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
    try {
      windowStage.on('windowStageEvent', (data) => {
        if (data === window.WindowStageEventType.RESUMED) {
          this.context.eventHub.emit('onForeground');
        } else if (data === window.WindowStageEventType.PAUSED) {
          this.context.eventHub.emit('onBackground');
        } else {
          hilog.info(DOMAIN, TAG, 'The window stage is not paused or resume');
        }
      })
    } catch (error) {
      hilog.error(0x0000, TAG, `windowStageEvent catch error, code: ${error.code}, message: ${error.message}`);
      return;
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
    // 前台时保存最新的流转数据到 AppStorage
    this.saveContinueData();
  }

  /**
   * 将当前播放状态保存到 AppStorage（供 onContinue 读取）
   */
  private saveContinueData(): void {
    try {
      const viewModel = AppStorage.get<VideoPlayViewModel>('videoPlayViewModel');
      if (viewModel && viewModel.isUse) {
        const data = viewModel.serializeContinueData();
        AppStorage.setOrCreate('continueData', JSON.stringify(data));
        hilog.info(DOMAIN, TAG, 'Continue data saved to AppStorage');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `saveContinueData error: ${error.code}, ${error.message}`);
    }
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
