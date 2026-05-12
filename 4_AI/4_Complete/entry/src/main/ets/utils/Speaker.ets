/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Speaker';

export class Speaker {
  // 定义引擎参数
  initParamsInfo: textToSpeech.CreateEngineParams = {
    language: 'zh-CN', // 语种设置为中文
    online: 1, // 模式设置为离线
    person: 13 // 聆小珊女声音色
  };
  // 定义引擎实例
  ttsEngine?: textToSpeech.TextToSpeechEngine;

  // 构造函数，创建引擎实例
  constructor() {
    // 调用创建引擎方法
    textToSpeech.createEngine(this.initParamsInfo, // 传入引擎参数
      (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => { // 回调得到引擎实例
        // 判断是否出现异常
        if (!err) {
          // 无异常，赋值
          this.ttsEngine = textToSpeechEngine;
        } else {
          // 有异常，输出日志
          hilog.error(0x0000, TAG, `createEngine failed, error code: ${err.code}, message: ${err.message}.`);
        }
      });
  }

  // 播报函数，定义播报音频流参数，并调用speak方法进行播报
  startSpeak(content: string) {
    let speakParams: textToSpeech.SpeakParams = {
      // requestId用于区分不同的请求，故在同一个实例内只能使用一次，不允许重复
      requestId: Date.now().toString()
    };
    try {
      this.ttsEngine?.speak(content, speakParams); // 传入待播报文本和参数
    } catch (error) {
      this.ttsEngine?.stop();
      hilog.error(0x0000, TAG, `speak failed, error code: ${error.code}, message: ${error.message}.`);
    }
  }

  // 停止合成与播报
  stopSpeak() {
    this.ttsEngine?.stop();
  }

  // 关闭引擎，释放引擎资源
  shutdownEngine() {
    this.ttsEngine?.shutdown();
  }
}