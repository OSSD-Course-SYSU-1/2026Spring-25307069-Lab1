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

import { Settings } from '../model/Settings';

@Entry
@ComponentV2
struct Index {
  // 1. 弹幕内容（字符串类型，默认文字）
  @Local content: string = '欢迎学习鸿蒙开发';
  // 2. 字号（数字类型，默认88）
  @Local fontSize: number = 88;
  // 字号标识（小/中/大，同步显示给用户）
  @Local fontSizeFlag: string = '小';
  // 3. 字体粗细（枚举类型，默认常规）
  @Local fontWeight: FontWeight = FontWeight.Regular;
  // 字体粗细选中项
  @Local selectedIndex: number = 0;
  // 字体粗细数组（常规、中等、加粗）
  fontWeights: FontWeight[] = [FontWeight.Regular, FontWeight.Medium, FontWeight.Bold];
  // 导航控制器
  pathInfos: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pathInfos) { // 使用Navigation作为首页的根容器，并绑定导航控制器
      Column() {
        // 1. 标题区
        Text('手持弹幕')
          .fontSize(26) // 字体大小
          .fontColor('#000000') // 字体颜色
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 }) // 左外边距16(离屏幕边缘有距离)
          .height(56) // 组件高度
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
              Text(this.content)
              // 第1步：开启跑马灯滚动模式
                .textOverflow({ overflow: TextOverflow.MARQUEE }) // TextOverflow.MARQUEE表示Text组件的文字溢出以跑马灯模式处理
                // 第2步：配置滚动的规则
                .marqueeOptions({
                  start: true // 关键：是否启动滚动。true：启动滚动；false：停止滚动
                })
                .fontSize(this.fontSize / 1.8) // 绑定字号变量
                .fontWeight(this.fontWeight) // 字体粗细
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
            TextArea({ text: this.content }) // 初始默认文字
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
              .onChange((value: string) => { // 用户修改输入框文本时触发，返回当前值
                this.content = value; // 将当前值赋值给content
              })
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
                  Text(this.fontSizeFlag)
                    .fontSize(14)
                }
                .width('100%')
                .height(48)
                .justifyContent(FlexAlign.SpaceBetween)

                Slider({
                  value: this.fontSize,
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
                  .onChange((value: number) => { // 用户拖动或点击时触发，返回当前滑动的进度值
                    this.fontSize = value;
                    // 根据当前fontSize匹配fontSizeFlag
                    if (this.fontSize === 88) {
                      this.fontSizeFlag = '小';
                    } else if (this.fontSize === 248) {
                      this.fontSizeFlag = '大';
                    } else {
                      this.fontSizeFlag = '中';
                    }
                  })
              }

              // 字体粗细区
              Row() {
                Text('字体粗细')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Select([
                  { value: this.fontWeights[0].toString() },
                  { value: this.fontWeights[1].toString() },
                  { value: this.fontWeights[2].toString() }
                ])
                  .value(this.fontWeight.toString())
                  .selected(this.selectedIndex)
                  .backgroundColor('#FFFFFF')
                  .fontColor('#99000000')
                  .borderWidth(0)
                  .onSelect((index: number) => { // 选中下拉菜单中某一项时触发，返回选中项的索引
                    this.fontWeight = this.fontWeights[index]; // 将选中项赋值给fontWeight
                    this.selectedIndex = index; // 将选中项的索引赋值给selectedIndex
                  })
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
            .onClick(() => {
              // 1. 把当前页面的设置项组装成Settings对象
              const settings = new Settings(this.content, this.fontSize, this.fontWeight);
              // 2. 跳转：第一个参数是路由表的name，第二个是传递的参数
              this.pathInfos.pushPathByName('Led', settings);
            })
        }
        .padding({
          left: 16,
          right: 16
        })
      }
      .width('100%') // 设置Column容器宽度为100%，横向占满屏幕
      .height('100%') // 设置Column容器高度为100%，纵向占满屏幕
      .background('#F1F3F5') //设置Column容器的背景色
      .alignItems(HorizontalAlign.Start)
    }
    .mode(NavigationMode.Stack) // 设置单栏模式
    .hideToolBar(true) // 隐藏工具栏
  }
}