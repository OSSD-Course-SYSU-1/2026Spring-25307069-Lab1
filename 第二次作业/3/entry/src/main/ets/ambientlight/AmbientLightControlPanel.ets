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

/**
 * Ambient Light Control Panel
 */
@Component
export struct AmbientLightControlPanel {
  @Consume('ambientLightEnabled') ambientLightEnabled: boolean;
  @Consume('ambientLightColor') ambientLightColor: string;
  @State isExpanded: boolean = false;

  private readonly BUTTON_SIZE: string = '36vp';
  private colorTimerId: number = -1;
  private colorIndex: number = 0;

  // Demo color palette - simulates video color changes
  private readonly demoPalette: string[] = [
    '#FF6600', '#3366FF', '#FF3366', '#33CC66',
    '#9933FF', '#FFCC00', '#FF3333', '#33CCCC'
  ];

  aboutToAppear() {
    // Start color cycling timer
    this.colorTimerId = setInterval(() => {
      if (this.ambientLightEnabled) {
        this.colorIndex = (this.colorIndex + 1) % this.demoPalette.length;
        this.ambientLightColor = this.demoPalette[this.colorIndex];
      }
    }, 2000);
  }

  aboutToDisappear() {
    if (this.colorTimerId !== -1) {
      clearInterval(this.colorTimerId);
      this.colorTimerId = -1;
    }
  }

  build() {
    Column() {
      this.MainButton()

      if (this.isExpanded && this.ambientLightEnabled) {
        this.ControlPanel()
      }
    }
    .backgroundColor('#80000000')
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
      .backgroundColor(this.ambientLightEnabled ? '#F67609' : '#444444')
      .borderRadius('18vp')
      .onClick(() => {
        this.ambientLightEnabled = !this.ambientLightEnabled;
      })

      if (this.ambientLightEnabled) {
        Button() {
          Text(this.isExpanded ? '▼' : '▶')
            .fontSize('14fp')
            .fontColor(Color.White)
        }
        .width('28vp')
        .height('28vp')
        .margin({ left: '8vp' })
        .backgroundColor('#333333')
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
        .backgroundColor('#444444')
        .margin({ top: '8vp', bottom: '8vp' })

      // Current color preview
      Row() {
        Text('当前颜色')
          .fontSize('12fp')
          .fontColor(Color.White)
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
