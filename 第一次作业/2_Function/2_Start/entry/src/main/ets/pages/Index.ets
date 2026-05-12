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

@Entry
@ComponentV2
struct Index {

  build() {
    Column() {
      // 1. 标题区
      Column() {
        Text('手持弹幕')
          .fontSize(26) // 字体大小
          .fontColor('#000000') // 字体颜色
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 }) // 左外边距16(离屏幕边缘有距离)
          .height(56) // 组件高度
      }
      .width('100%') // 设置Column容器宽度撑满屏幕
      .alignItems(HorizontalAlign.Start) // 设置Column容器的内容左对齐

      // 2. 预览区
      Column() {
        Text('预览') // Text组件：文本组件，可以展示单行文本
          .fontSize(14) // 字体大小14
          .fontColor('#99000000') // 字体颜色
          .fontWeight(FontWeight.Medium)
          .margin({ left: 28 }) // 左外边距28（离屏幕边缘有距离）

        // 弹幕展示框
        Column() {
          // 弹幕滚动区域
          Row() {
            Text('欢迎学习鸿蒙开发')
            // 第1步：开启跑马灯滚动模式
              .textOverflow({ overflow: TextOverflow.MARQUEE }) // TextOverflow.MARQUEE表示Text组件的文字溢出以跑马灯模式处理
              // 第2步：配置滚动的规则
              .marqueeOptions({
                start: true // 关键：是否启动滚动。true：启动滚动；false：停止滚动
              })
              .fontSize(88) // 字体大小
              .fontWeight(FontWeight.Regular) // 字体粗细
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .height('100%')
          .linearGradient({
            direction: GradientDirection.Right, // 渐变方向
            colors: [
              ['#013C9C', 0.0],
              ['#3066E4', 0.5],
              ['#43A1F4', 1.0]
            ]
          })
          .borderRadius(16) // 边框的圆角半径
          .justifyContent(FlexAlign.Center) // 设置文本居中
        }
        .width('100%')
        .height(199) // 展示框高度
        .backgroundColor('#E5E5EA') // 展示框背景色
        .padding({
          top: 24,
          right: 16,
          bottom: 24,
          left: 16
        }) // 内边距
        .margin({ top: 8 }) // 外边距（距离“预览”标题的间距）
        .alignItems(HorizontalAlign.Start) // 设置Column容器内容左对齐
      }
      .width('100%')
      .margin({ top: 28 })
      .alignItems(HorizontalAlign.Start) // 设置Column容器的内容左对齐

      // 3. 操作区
      Column() {
        // 弹幕内容区
        Column() {
          Text('弹幕内容')
            .fontSize(14)
            .fontColor('#99000000')
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 })

          // 输入框
          TextArea({ text: '欢迎学习鸿蒙开发' }) // 初始默认文字
            .backgroundColor(Color.White) // 白色背景色
            .maxLength(50) // 限制输入文本的个数，最多输入50个字
            .showCounter(
              true, // 开启统计
              {
                thresholdPercentage: 1, // 全程显示统计（不用等字数快满才出现）
                highlightBorder: true // 输入快满时，边框会高亮提醒
              }
            )
            .height(72) // 输入框高度
            .padding({
              top: 8,
              right: 16,
              bottom: 8,
              left: 16
            }) // 输入框内部的文字，距离输入框边缘的距离
            .margin({ top: 8 }) // 输入框距离上方标题的间距
            .borderRadius(16) // 边框的圆角半径
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({
          top: 28,
          bottom: 28
        })

        // 设置区
        Column() {
          // 标题
          Text('显示设置')
            .fontSize(14)
            .fontColor('#99000000')
            .fontWeight(FontWeight.Medium)
            .margin({
              bottom: 8,
              left: 12
            })

          Column() {
            // 字号大小区
            Column() {
              Row() {
                Text('字体大小')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text('小')
                  .fontSize(14)
              }
              .width('100%')
              .height(48)
              .justifyContent(FlexAlign.SpaceBetween)

              Slider({
                value: 168,
                min: 88,
                max: 248,
                step: 80,
                style: SliderStyle.InSet
              })
                .width('calc(100% + 12vp)')
                .height(40)
                .blockColor(Color.White) // 滑块背景色
                .trackColor('#F1F3F5') // 滑轨背景色
                .selectedColor('#0A59F7') // 滑轨的已滑动部分背景色
                .showSteps(true) // 显示步长刻度
            }

            // 字体粗细区
            Row() {
              Text('字体粗细')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              Select([])
                .backgroundColor('#FFFFFF')
                .fontColor('#99000000')
                .borderWidth(0)
            }
            .width('100%')
            .height(48)
            .margin({ top: 12 })
            .justifyContent(FlexAlign.SpaceBetween)

          }
          .width('100%')
          .padding({
            left: 12,
            right: 12,
            top: 4,
            bottom: 4
          })
          .margin({ bottom: 12 })
          .backgroundColor(Color.White)
          .borderRadius(16)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start) // 设置Column容器的内容左对齐

        Button('显示弹幕')
          .height(40)
          .backgroundColor('#0A59F7')
          .margin({ top: 32 })
          .width('100%')
      }
      .padding({
        left: 16,
        right: 16
      })
    }
    .width('100%') // 设置Column容器宽度为100%，横向占满屏幕
    .height('100%') // 设置Column容器高度为100%，纵向占满屏幕
    .background('#F1F3F5') //设置Column容器的背景色
  }
}