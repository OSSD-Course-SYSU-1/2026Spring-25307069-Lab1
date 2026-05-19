# DecodePlayControl 项目结构分析

## 项目概述

DecodePlayControl 是一个基于 HarmonyOS 的视频播放控制应用。该项目利用 AVCodec 能力实现 Surface 模式下的视频播控功能，通过调用 Native 侧解码器与解封装能力，完成视频播放、暂停、进度调整、资源切换及倍速播放等核心操作。该应用旨在帮助开发者理解并掌握 Surface 模式下视频解码能力及解码流程的开发方法。

## 整体架构

项目采用 HarmonyOS 应用架构，主要包括：

- **应用层 (ETS)**: 使用 ArkTS 语言开发的用户界面和业务逻辑
- **Native 层 (C++)**: 实现视频解码、音频解码、解封装等核心功能
- **构建配置**: 使用 Hvigor 构建工具和相关配置文件

## 各模块功能分析

### 1. 根目录配置

- `build-profile.json5`: 应用构建配置文件，定义构建参数和选项
- `hvigorfile.ts`: Hvigor 构建脚本文件
- `oh-package.json5`: 包管理配置文件
- `LICENSE`: 开源许可证文件
- `OAT.xml`: 应用安全配置文件
- `README.md`: 项目说明文档

### 2. AppScope 模块

- `app.json5`: 应用范围配置文件
- `resources/`: 应用级资源文件
  - `base/element/string.json`: 基础字符串资源
  - `base/media/layered_image.json`: 媒体资源配置

### 3. entry 模块 (主模块)

entry 模块是应用的核心模块，包含所有业务逻辑和用户界面。

#### 3.1 构建配置
- `build-profile.json5`: 模块构建配置
- `hvigorfile.ts`: 模块构建脚本
- `oh-package.json5`: 模块包配置
- `oh-package-lock.json5`: 包锁定文件
- `obfuscation-rules.txt`: 代码混淆规则

#### 3.2 ETS 层 (应用层)

##### 3.2.1 入口和生命周期
- `entryability/EntryAbility.ets`: 应用入口 Ability，负责应用生命周期管理
- `entrybackupability/EntryBackupAbility.ets`: 备份恢复 Ability

##### 3.2.2 用户界面
- `pages/Index.ets`: 主页面组件，实现视频选择和播放控制界面

##### 3.2.3 视图层
- `view/VideoPlayView.ets`: 视频播放视图组件，处理播放界面渲染和用户交互

##### 3.2.4 视图模型层
- `viewmodel/VideoPlayViewModel.ets`: 视频播放视图模型，管理播放状态、进度、速度等业务逻辑

##### 3.2.5 数据模型
- `model/PlayerStateModel.ets`: 播放状态枚举模型 (IDLE, PLAYING, PAUSE)

##### 3.2.6 公共工具
- `common/CommonConstants.ets`: 应用常量定义，包括播放速度数组、时间间隔等
- `common/TimeUtils.ets`: 时间格式化工具函数

#### 3.3 Native 层 (C++)

Native 层实现视频解码和播放的核心功能。

##### 3.3.1 系统解码能力
- `capabilities/include/AudioDecoder.h`: 音频解码能力接口
- `capabilities/include/VideoDecoder.h`: 视频解码能力接口
- `capabilities/include/Demuxer.h`: 解封装能力接口
- `capabilities/include/CodecCallback.h`: 解码回调接口
- `capabilities/src/`: 对应实现文件

##### 3.3.2 公共工具
- `common/include/`: 解码相关数据结构和工具
  - `AudioSampleInfo.h`: 音频解码数据信息
  - `VideoSampleInfo.h`: 视频解码数据信息
  - `SampleInfo.h`: 通用解码数据信息
  - `MediaError.h`: 媒体错误枚举
  - `MediaLog.h`: 日志宏定义

##### 3.3.3 播放器业务逻辑
- `player/include/Player.h`: 播放器接口，定义播放控制方法
- `player/include/playerNative.h`: Native 交互接口
- `player/src/Player.cpp`: 播放器实现，处理视频解码线程、音频解码线程等
- `player/src/PlayerNative.cpp`: Native 层与应用层的交互实现

##### 3.3.4 渲染上屏
- `render/include/XComponentManager.h`: 渲染管理接口
- `render/src/`: 渲染实现 (文件未完全列出)

##### 3.3.5 类型定义
- `types/libplayer/`: 播放器类型定义

#### 3.4 资源文件
- `resources/base/`: 基础资源
- `resources/en_US/`: 英文资源
- `resources/zh_CN/`: 中文资源
- `resources/rawfile/`: 原始文件资源 (包含视频文件 1.mp4, 2.mp4, 3.mp4)

### 4. 构建和依赖

- `hvigor/hvigor-config.json5`: Hvigor 全局配置
- `oh_modules/`: 依赖模块目录
- `build/`: 构建输出目录
  - `config/`: 构建配置
  - `default/`: 默认构建产物
    - `cache/`: 编译缓存
    - `generated/`: 生成文件
    - `intermediates/`: 中间产物
    - `outputs/`: 最终输出 (entry-default-unsigned.hap)

### 5. 文档和截图

- `docs/`: 项目文档目录
- `screenshots/device/`: 设备截图 (Index.png)

## 核心功能流程

1. **应用启动**: EntryAbility 加载 Index 页面
2. **视频选择**: 用户选择视频资源 (1.mp4, 2.mp4, 3.mp4)
3. **播放控制**: 通过 VideoPlayViewModel 调用 Native Player 进行播放/暂停/进度控制
4. **解码渲染**: Native 层使用 AVCodec 进行视频解码，通过 Surface 模式渲染到屏幕
5. **用户交互**: 支持倍速播放、全屏播放、进度拖拽等功能

## 技术特点

- **跨语言架构**: ETS (ArkTS) + C++ Native 开发
- **Surface 渲染**: 使用系统 Surface 进行高效视频渲染
- **多线程解码**: 视频和音频解码分别在独立线程处理
- **状态管理**: 使用 MVVM 模式管理播放状态
- **HarmonyOS 原生**: 充分利用 HarmonyOS AVCodec 和 UI 能力