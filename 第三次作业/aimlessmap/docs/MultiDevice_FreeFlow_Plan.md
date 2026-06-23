# 无目的地图 - 多端部署与自由流转实施计划

> **目标**：在保持原有 UI 布局不变的前提下，实现大小屏自适应适配和跨设备自由流转功能。

---

## 一、技术方案概览

### 1.1 多端部署（大小屏适配）

HarmonyOS NEXT 的 "一次开发，多端部署" 依赖以下技术：

| 技术 | 说明 | 应用场景 |
|------|------|----------|
| **断点 (Breakpoint)** | 根据窗口宽度划分 xs/sm/md/lg 四个范围 | 手机/平板/折叠屏适配 |
| **媒体查询** | 监听窗口宽度、横竖屏、深浅色等 | 动态调整布局 |
| **栅格系统 (GridRow/GridCol)** | 12 列网格布局 | 内容对齐和排版 |
| **响应式组件** | Tabs、Swiper、Grid、List 等 | 自动适配不同尺寸 |

**断点定义标准：**
```
xs: 0-320vp    (智能手表 - 本应用不支持)
sm: 320-600vp   (手机竖屏)
md: 600-840vp   (手机横屏/小折叠)
lg: 840+ vp     (平板/大折叠)
```

### 1.2 自由流转（跨设备接续）

HarmonyOS 自由流转包含两种核心能力：

| 能力 | 说明 | 本应用使用场景 |
|------|------|--------------|
| **迁移 (Continue)** | 将应用从 A 设备完全迁移到 B 设备，A 端退出 | 手机上的漫步迁移到平板继续 |
| **多端协同 (Collaboration)** | 应用同时在多设备运行，状态实时同步 | 手机导航 + 平板看地图 |

**本方案选择：迁移 (Continue)** —— 最契合漫步场景，用户可以从手机开始漫步，迁移到平板/车机继续。

**核心 API：**
- `@ohos.app.ability.wantConstant` - 定义流转意图
- `UIAbility.onContinue()` - 保存迁移状态
- `UIAbility.onCreate()` / `onNewWant()` - 恢复迁移状态
- `distributedMissionManager` - 分布式任务管理

---

## 二、文件结构变更

### 新增文件
```
entry/src/main/ets/
├── constants/
│   └── BreakpointConstants.ets      # 断点常量定义
├── utils/
│   └── BreakpointUtil.ets           # 断点监听与状态管理
├── service/
│   └── ContinueService.ets          # 自由流转状态保存/恢复
```

### 修改文件
```
entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets             # 添加断点初始化 + 流转生命周期
├── pages/
│   ├── HomePage.ets                 # 响应式改造
│   ├── WalkPage.ets                 # 响应式改造 + 支持流转状态保存/恢复
│   ├── WalkSummaryPage.ets          # 响应式改造
│   ├── RecordPage.ets               # 响应式改造
│   └── SettingsPage.ets             # 响应式改造
├── module.json5                     # 添加多设备类型 + 流转配置
└── resources/base/profile/main_pages.json  # 添加流转入口页面
```

---

## 三、详细实施步骤

### 阶段一：基础设施搭建

#### Task 1: 创建 BreakpointConstants.ets

**文件：** `entry/src/main/ets/constants/BreakpointConstants.ets`

定义断点常量、BreakpointType 工具类（根据断点返回不同值）。

#### Task 2: 创建 BreakpointUtil.ets

**文件：** `entry/src/main/ets/utils/BreakpointUtil.ets`

- 单例模式管理断点状态
- 监听窗口尺寸变化（`window.on('windowSizeChange')`）
- 使用 `AppStorage` 同步断点状态（key: `'currentBreakpoint'`）
- 提供 `getBreakpointByWidth(width: number): string` 方法

#### Task 3: EntryAbility 初始化断点监听

**文件：** `entry/src/main/ets/entryability/EntryAbility.ets`

在 `onWindowStageCreate` 中：
1. 获取主窗口
2. 初始化 `BreakpointUtil`，传入窗口实例
3. 监听窗口尺寸变化，自动更新 `AppStorage` 中的断点状态

#### Task 4: module.json5 配置多设备支持

**文件：** `entry/src/main/module.json5`

- `deviceTypes` 添加 `"2in1"`（二合一设备）
- 添加 `continuable: true` 标记支持流转
- 确保已有 `phone`、`tablet`

---

### 阶段二：各页面响应式改造（保持原有UI布局）

**核心原则：**
1. **不改动原有UI布局结构** —— 手机竖屏（sm）下保持当前布局完全一致
2. **使用 `@StorageProp('currentBreakpoint')` 监听断点变化**
3. **仅调整以下响应式属性：**
   - 内边距（padding）随屏幕增大而增加
   - 卡片宽度/列数随屏幕增大而调整
   - 字体大小在 lg 断点下适当放大
   - 横屏/大屏下使用 Row 替代 Column 实现左右分栏

#### Task 5: HomePage 响应式改造

**文件：** `entry/src/main/ets/pages/HomePage.ets`

**改造点：**
- 引入 `@StorageProp('currentBreakpoint') bp: string = 'sm'`
- 统计卡片：sm 保持当前 Row 布局，md/lg 增加卡片内边距和圆角
- 时长选择器：sm 保持横向 Scroll，md/lg 改为 Grid 布局（2-3列）
- 开始按钮：sm 保持 80% 宽度，lg 改为 60% 宽度
- 底部导航栏：lg 下增加高度和图标尺寸
- 弹窗宽度：sm 保持 80%/85%，lg 改为 50%

**关键代码模式：**
```typescript
@StorageProp('currentBreakpoint') bp: string = 'sm'

// 根据断点调整内边距
.padding(this.getPaddingByBreakpoint())

private getPaddingByBreakpoint(): Padding {
  switch (this.bp) {
    case 'sm': return { left: 20, right: 20 };
    case 'md': return { left: 32, right: 32 };
    case 'lg': return { left: 48, right: 48 };
    default: return { left: 20, right: 20 };
  }
}
```

#### Task 6: WalkPage 响应式改造

**文件：** `entry/src/main/ets/pages/WalkPage.ets`

**改造点（重点页面）：**
- **sm（手机竖屏）**：保持现有布局 —— 全屏地图 + 顶部信息浮层 + 底部控制栏
- **md/lg（横屏/平板）**：左右分栏布局
  - 左侧：地图区域（占 60% 宽度）
  - 右侧：控制面板（占 40% 宽度），包含方向信息、倒计时、控制按钮
- 顶部信息栏：lg 下增加背景模糊效果（`backdropBlur`）
- 底部控制栏：md/lg 下改为右侧面板内的垂直按钮组

**布局切换逻辑：**
```typescript
if (this.bp === 'sm') {
  // 保持现有 Stack + 绝对定位布局
} else {
  // Row 左右分栏
  Row() {
    MapComponent() // 左侧
    ControlPanel() // 右侧
  }
}
```

#### Task 7: WalkSummaryPage 响应式改造

**文件：** `entry/src/main/ets/pages/WalkSummaryPage.ets`

**改造点：**
- sm：保持当前单列布局
- md/lg：统计信息改为横向 Grid（3列等分）
- 照片区域：sm 保持横向滚动，md/lg 改为 Grid（自适应列数）
- 弹窗宽度：lg 下改为 50%
- 增加 Scroll 容器，确保内容超出时可滚动

#### Task 8: RecordPage 响应式改造

**文件：** `entry/src/main/ets/pages/RecordPage.ets`

**改造点：**
- sm：保持当前列表布局
- md/lg：列表项增加内边距，卡片更宽
- 详情弹窗：lg 下宽度改为 50%，高度改为 60%
- 空状态：保持居中

#### Task 9: SettingsPage 响应式改造

**文件：** `entry/src/main/ets/pages/SettingsPage.ets`

**改造点：**
- sm：保持当前布局
- md/lg：设置项卡片最大宽度限制（如 600vp），居中显示
- 增加卡片间距

---

### 阶段三：自由流转功能实现

#### Task 10: 创建 ContinueService.ets

**文件：** `entry/src/main/ets/service/ContinueService.ets`

**职责：**
- 封装流转状态的序列化/反序列化
- 定义流转数据接口 `ContinueState`
- 提供 `saveWalkState()` 和 `restoreWalkState()` 方法

**流转状态数据结构：**
```typescript
interface ContinueState {
  page: string;              // 当前页面：'WalkPage' | 'HomePage' | ...
  duration: number;          // 剩余时长（秒）
  remainingSeconds: number;  // 倒计时剩余
  startLat: number;          // 起点纬度
  startLon: number;          // 起点经度
  redirectCount: number;     // 换向次数
  trailPoints: TrailPoint[]; // 轨迹点
  currentPoint: RandomPoint | null; // 当前目标点
  isPaused: boolean;         // 是否暂停
  startTime: number;         // 开始时间戳
  elapsedSeconds: number;    // 已进行秒数
}
```

#### Task 11: EntryAbility 添加流转生命周期

**文件：** `entry/src/main/ets/entryability/EntryAbility.ets`

**修改点：**
1. 实现 `onContinue()` 方法：
   - 判断当前页面是否为 WalkPage
   - 如果是，通过 `ContinueService` 保存当前漫步状态
   - 将状态数据放入 `want` 参数中返回

2. 修改 `onCreate()` 和 `onNewWant()`：
   - 检查 `want` 参数中是否包含流转状态
   - 如果包含，解析状态并判断目标页面
   - 如果是 WalkPage，恢复漫步状态并直接跳转

3. 添加 `onDestroy()` 清理逻辑

**关键代码：**
```typescript
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // 获取当前页面状态（通过 AppStorage 或全局状态管理）
  const continueState = ContinueService.getCurrentState();
  if (continueState) {
    wantParam['continueState'] = JSON.stringify(continueState);
    return AbilityConstant.OnContinueResult.AGREE;
  }
  return AbilityConstant.OnContinueResult.AGREE;
}
```

#### Task 12: WalkPage 支持流转状态保存/恢复

**文件：** `entry/src/main/ets/pages/WalkPage.ets`

**修改点：**
1. **保存状态：** 在页面中定期（或关键状态变化时）将当前状态写入 `AppStorage`
   - 倒计时剩余时间
   - 当前目标点
   - 轨迹数据
   - 换向次数
   - 暂停状态

2. **恢复状态：** 在 `aboutToAppear()` 中：
   - 先检查 `router.getParams()` 中是否包含 `continueState`
   - 如果包含，调用 `ContinueService.restoreWalkState()` 恢复所有状态
   - 恢复倒计时、地图标记、音频播放等

3. **添加 `onPageShow()` / `onPageHide()` 生命周期：**
   - 页面隐藏时保存状态到 `AppStorage`
   - 页面显示时检查是否需要恢复

#### Task 13: 其他页面流转适配

**文件：** `entry/src/main/ets/pages/HomePage.ets`、`WalkSummaryPage.ets`

- HomePage：支持从流转恢复后正确显示统计数据
- WalkSummaryPage：支持流转后保存记录到本地

---

### 阶段四：配置与测试

#### Task 14: module.json5 完整配置

**文件：** `entry/src/main/module.json5`

确保包含：
```json
{
  "deviceTypes": ["phone", "tablet", "2in1"],
  "continuable": true,
  "abilities": [{
    "continueType": "walk_ability"
  }]
}
```

#### Task 15: 权限检查

确保已有权限满足流转需求：
- `ohos.permission.INTERNET` - 已存在
- `ohos.permission.DISTRIBUTED_DATASYNC` - 如需分布式数据同步（可选）

---

## 四、各页面响应式改造对照表

| 页面 | sm (手机竖屏) | md (手机横屏/小折叠) | lg (平板/大折叠) |
|------|--------------|---------------------|-----------------|
| **HomePage** | 保持现有单列布局 | 内边距增大，卡片更宽 | 左右留白增加，按钮宽度减小 |
| **WalkPage** | 全屏地图+浮层 | 左右分栏：左地图右控制 | 左右分栏，右侧面板更宽 |
| **WalkSummaryPage** | 单列布局 | 统计信息横向排列 | 照片网格自适应列数 |
| **RecordPage** | 列表布局 | 列表项更宽 | 详情弹窗更窄更高 |
| **SettingsPage** | 单列布局 | 卡片最大宽度限制 | 居中显示，更大间距 |

---

## 五、自由流转时序图

```
设备 A (手机)                    设备 B (平板)
   |                                |
   |  用户点击"流转"按钮             |
   |------------迁移请求------------>|
   |                                |
   |  onContinue() 保存状态          |
   |  {duration, trail, ...}        |
   |------------状态数据------------>|
   |                                |
   |  应用退出                       |  onCreate(want)
   |                                |  解析 continueState
   |                                |  恢复 WalkPage 状态
   |                                |  倒计时继续
   |                                |  地图显示轨迹
   |                                |  音频继续播放
```

---

## 六、实施顺序建议

1. **先完成阶段一**（基础设施）：断点系统 + EntryAbility 初始化
2. **再完成阶段二**（页面改造）：按 HomePage → WalkPage → WalkSummaryPage → RecordPage → SettingsPage 顺序
3. **最后阶段三**（自由流转）：ContinueService → EntryAbility 生命周期 → WalkPage 状态保存/恢复
4. **阶段四**（配置验证）：module.json5 调整 + 多设备测试

---

## 七、注意事项

1. **保持原有UI布局**：只在 md/lg 断点下增加响应式调整，sm 下保持 100% 一致
2. **横竖屏切换**：WalkPage 在 sm 断点下横屏时会自动切换到 md 布局（左右分栏）
3. **状态同步**：流转时使用 `AppStorage` 作为临时状态存储，确保数据可序列化
4. **地图状态**：流转后需要重新初始化地图控制器，但标记点需要根据轨迹数据重新添加
5. **音频状态**：流转后音频需要重新播放，无法直接迁移音频会话
6. **计时器精度**：流转时使用 `Date.now()` 计算已进行时间，而非依赖定时器计数
