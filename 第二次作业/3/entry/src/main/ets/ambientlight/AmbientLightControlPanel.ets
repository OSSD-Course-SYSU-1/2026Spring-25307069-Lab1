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

import { FlowSpeed } from './AmbientLightTypes';
import { ThemeColors } from '../common/ThemeColors';

/**
 * Ambient Light Control Panel
 */
@Component
export struct AmbientLightControlPanel {
  @Consume('ambientLightEnabled') ambientLightEnabled: boolean;
  @Consume('themeColors') themeColors: ThemeColors = new ThemeColors(true);
  @Prop ambientLightColor: string = '#FF6600';
  @State isExpanded: boolean = false;

  private readonly BUTTON_SIZE: string = '36vp';

  build() {
    Column() {
      this.MainButton()

      if (this.isExpanded && this.ambientLightEnabled) {
        this.ControlPanel()
      }
    }
    .backgroundColor(this.themeColors.isDark ? '#80000000' : '#CCFFFFFF')
    .borderRadius('20vp')
    .padding(this.isExpanded ? '12vp' : '8vp')
  }

  @Builder
  MainButton() {
    Row() {
      Button() {
        Text('💡')
          .fontSize('20fp')
      }
      .width(this.BUTTON_SIZE)
      .height(this.BUTTON_SIZE)
      .backgroundColor(this.ambientLightEnabled ? this.themeColors.accentColor : this.themeColors.buttonBackground)
      .borderRadius('18vp')
      .onClick(() => {
        this.ambientLightEnabled = !this.ambientLightEnabled;
      })

      if (this.ambientLightEnabled) {
        Button() {
          Text(this.isExpanded ? '▼' : '▶')
            .fontSize('14fp')
            .fontColor(this.themeColors.primaryText)
        }
        .width('28vp')
        .height('28vp')
        .margin({ left: '8vp' })
        .backgroundColor(this.themeColors.buttonBackground)
        .borderRadius('14vp')
        .onClick(() => {
          this.isExpanded = !this.isExpanded;
        })
      }
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ControlPanel() {
    Column({ space: '12vp' }) {
      Row()
        .width('100%')
        .height('1vp')
        .backgroundColor(this.themeColors.dividerColor)
        .margin({ top: '8vp', bottom: '8vp' })

      // Current color preview
      Row() {
        Text('当前颜色')
          .fontSize('12fp')
          .fontColor(this.themeColors.primaryText)
        Column()
          .width('24vp')
          .height('24vp')
          .backgroundColor(this.ambientLightColor)
          .borderRadius('12vp')
          .margin({ left: '8vp' })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .margin({ top: '8vp' })
  }
}
