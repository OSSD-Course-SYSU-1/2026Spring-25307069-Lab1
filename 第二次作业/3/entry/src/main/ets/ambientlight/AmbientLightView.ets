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

/**
 * Ambient Light View Component
 * Renders soft glow OUTSIDE the video area (does not cover video content)
 * The glow extends outward from the video edges into the surrounding area
 */
@Component
export struct AmbientLightView {
  @Consume('ambientLightEnabled') ambientLightEnabled: boolean;
  @Prop ambientLightColor: string = '#FF6600';
  isFullScreen: boolean = false;

  // Glow thickness
  private glowWidth: string = '12vp';
  private glowWidthFs: string = '20vp';

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Top glow - positioned above center, extends upward
      Column()
        .width('100%')
        .height(this.isFullScreen ? this.glowWidthFs : this.glowWidth)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [this.ambientLightColor, 0.0],
            [this.ambientLightColor, 0.3],
            ['rgba(0,0,0,0)', 1.0]
          ]
        })
        .opacity(0.7)
        .blur(15)
        .position({ top: 0 })

      // Bottom glow - positioned below center, extends downward
      Column()
        .width('100%')
        .height(this.isFullScreen ? this.glowWidthFs : this.glowWidth)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            [this.ambientLightColor, 0.0],
            [this.ambientLightColor, 0.3],
            ['rgba(0,0,0,0)', 1.0]
          ]
        })
        .opacity(0.7)
        .blur(15)
        .position({ bottom: 0 })

      // Left glow - positioned left of center, extends leftward
      Row()
        .width(this.isFullScreen ? this.glowWidthFs : this.glowWidth)
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [
            [this.ambientLightColor, 0.0],
            [this.ambientLightColor, 0.3],
            ['rgba(0,0,0,0)', 1.0]
          ]
        })
        .opacity(0.7)
        .blur(15)
        .position({ left: 0 })

      // Right glow - positioned right of center, extends rightward
      Row()
        .width(this.isFullScreen ? this.glowWidthFs : this.glowWidth)
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Left,
          colors: [
            [this.ambientLightColor, 0.0],
            [this.ambientLightColor, 0.3],
            ['rgba(0,0,0,0)', 1.0]
          ]
        })
        .opacity(0.7)
        .blur(15)
        .position({ right: 0 })
    }
    .width('100%')
    .height('100%')
    .visibility(this.ambientLightEnabled ? Visibility.Visible : Visibility.Hidden)
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
