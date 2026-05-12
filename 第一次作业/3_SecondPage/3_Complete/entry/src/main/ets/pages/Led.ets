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

import { window } from '@kit.ArkUI';
import { Settings } from '../model/Settings';

@ComponentV2
export struct Led {
  @Local settings: Settings = new Settings('', 88, FontWeight.Regular);

  build() {
    NavDestination() { // 使用NavDestination作为目标页面的根容器
      Column() { // 垂直容器：让文字居中显示
        Text(this.settings.content)
          .textOverflow({ overflow: TextOverflow.MARQUEE }) // 文字超出显示框时，跑马灯的方式展示（即滚动的方式展示）
          .marqueeOptions({
            start: true // 开启滚动功能
          })
          .fontSize(this.settings.fontSize) // 绑定字号变量
          .fontWeight(this.settings.fontWeight)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .onReady((context: NavDestinationContext) => {
      this.settings = context.pathInfo.param as Settings;
    }) // NavDestination内组件开始加载前执行，可以得到组件上下文信息，并获取到页面跳转时携带的参数
    .width('100%')
    .height('100%')
    .backButtonIcon($r('app.media.chevron_left'))
    .preferredOrientation(window.Orientation.LANDSCAPE) // 强制横屏（弹幕更适合横屏展示）
    .linearGradient({ // 设置背景线性渐变
      direction: GradientDirection.Right, // 渐变方向
      colors: [
        ['#013C9C', 0.0],
        ['#3066E4', 0.5],
        ['#43A1F4', 1.0]
      ]
    })
  }
}

// 构建页面函数，配置在route_map.json5文件中，需要跳转至本页面时自动调用
@Builder
export function LedBuilder() {
  Led();
}