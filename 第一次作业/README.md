# 快速入门-手持弹幕

## 项目简介

本示例通过ArkTS基本语法、ArkUI基本能力实现手持弹幕场景，提供手把手的教学实践，从零基础开始，带开发者快速掌握应用开发的基础技能。

## 效果预览

![](screenshots/phone.gif)

## 使用说明

1. 在模拟器/直板机上运行本工程，进入首页。
2. 修改弹幕内容，预览区弹幕内容实时更新，文本超长时滚动。
3. 修改字体大小，预览区文本字体大小实时更新，字体大小位置根据具体值显示为“大”、“中”或“小”。
4. 修改字体粗细，预览区文本字体粗细实时更新，选中的选项同步更新。
5. 点击“显示弹幕”按钮，页面跳转并横屏展示弹幕内容，文本的显示与当前选中的各个选项一致，文本超长时滚动。
6. 点击右上角播报按钮，AI播报当前弹幕内容。
7. 点击左上角返回按钮，页面跳转回设置页面。

## 工程目录
```
├──1_UI                                   // 开发弹幕设置静态页面
├──2_Function                             // 开发弹幕设置页面交互
├──3_SecondPage                           // 开发弹幕展示页面
└──4_AI                                   // AI语音朗读
   ├──4_Start                             // 起始工程
   └──4_Complete                          // 完成工程
      ├──entry/src/main/ets               // 代码区
      │  ├──entryability
      │  │  └──EntryAbility.ets           // 程序入口类
      │  ├──entrybackupability
      │  │  └──EntryBackupAbility.ets
      │  ├──model
      │  │  └──Settings.ets               // 设置类
      │  ├──pages
      │  │  ├──Index.ets                  // 首页，即弹幕设置页
      │  │  └──Led.ets                    // 手持弹幕页
      │  └──utils
      │     └──Speaker.ets                // 语音朗读类
      └──entry/src/main/resources         // 应用静态资源目录
```

## 具体实现

1. 通过ArkTS基础能力实现基本页面效果。
2. 使用Navigation组件实现页面路由。
3. 使用AI文本转语音能力实现AI朗读播报。

## 相关权限

不涉及。

## 约束与限制

1. 本示例仅支持标准系统上运行，支持设备：模拟器、直板机。
2. HarmonyOS系统：HarmonyOS 6.0.0 Release及以上。
3. DevEco Studio版本：DevEco Studio 6.0.0 Release及以上。
4. HarmonyOS SDK版本：HarmonyOS 6.0.0 Release SDK及以上。