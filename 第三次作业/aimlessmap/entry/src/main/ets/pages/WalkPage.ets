import { router } from '@kit.ArkUI';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AppConstants } from '../constants/AppConstants';
import { BreakpointConstants, BreakpointType } from '../constants/BreakpointConstants';
import { Logger } from '../utils/Logger';
import { preferencesUtil, StoreKeys } from '../utils/PreferencesUtil';
import { RandomService, RandomPoint } from '../service/RandomService';
import { LocationService } from '../service/LocationService';
import { AudioService } from '../service/AudioService';
import { WalkRecord, TrailPoint } from '../model/WalkRecord';
import { ContinueService } from '../service/ContinueService';

@Entry
@Component
struct WalkPage {
  private mapController?: map.MapComponentController;
  private audioService = new AudioService();
  private currentSoundType: string = '';
  private currentSoundUri: string = '';
  private currentPoint: RandomPoint | null = null;
  private trailMarkers: map.Marker[] = [];
  private trailPoints: TrailPoint[] = [];

  @StorageProp(BreakpointConstants.BREAKPOINT_KEY) bp: string = BreakpointConstants.BREAKPOINT_SM_NAME;
  @State countdownText: string = '30:00';
  @State directionText: string = '';
  @State walkTimeText: string = '';
  @State redirectCount: number = 0;
  @State showComplete: boolean = false;

  private duration: number = 30;
  private remainingSeconds: number = 0;
  private walkTimeRemaining: number = 0;
  private startLat: number = 0;
  private startLon: number = 0;
  private startTime: number = 0;
  private countdownTimer: number = -1;
  @State private isPaused: boolean = false;

  // 响应式配置（仅用于字体微调）
  private infoFontSize = new BreakpointType({ sm: 32, md: 30, lg: 28 });
  private walkTimeFontSize = new BreakpointType({ sm: 18, md: 17, lg: 16 });

  aboutToAppear(): void {
    // 检查是否有流转恢复状态
    const restoredState = ContinueService.getRestoreState();
    if (restoredState && restoredState.page === 'WalkPage') {
      this.restoreFromContinueState(restoredState);
      return;
    }

    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.duration = (params['duration'] as number) ?? AppConstants.DEFAULT_TIMER;
      this.startLat = (params['startLat'] as number) ?? AppConstants.DEFAULT_LAT;
      this.startLon = (params['startLon'] as number) ?? AppConstants.DEFAULT_LON;
    }
    // 自定义时长时，默认使用30分钟
    if (this.duration < 0) {
      this.duration = AppConstants.DEFAULT_TIMER;
    }
    this.remainingSeconds = this.duration * 60;
    this.countdownText = this.formatTime(this.remainingSeconds);
    this.initWalk();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  onPageShow(): void {
    // 页面显示时，如果有恢复状态，需要重新初始化地图标记
    if (this.trailPoints.length > 0 && this.mapController) {
      this.restoreMapMarkers();
    }
  }

  onPageHide(): void {
    // 页面隐藏时保存当前状态到 ContinueService
    this.saveContinueState();
  }

  /**
   * 从流转状态恢复
   */
  private restoreFromContinueState(state: import('../service/ContinueService').ContinueState): void {
    Logger.info(`从流转状态恢复: 剩余${state.remainingSeconds}秒`);
    this.duration = state.duration;
    this.remainingSeconds = state.remainingSeconds;
    this.startLat = state.startLat;
    this.startLon = state.startLon;
    this.redirectCount = state.redirectCount;
    this.trailPoints = state.trailPoints ?? [];
    this.currentPoint = state.currentPoint;
    this.isPaused = state.isPaused;
    this.startTime = Date.now() - state.elapsedSeconds * 1000;
    this.currentSoundType = state.currentSoundType;
    this.currentSoundUri = state.currentSoundUri;

    // 恢复UI显示
    this.countdownText = this.formatTime(this.remainingSeconds);
    this.directionText = this.currentPoint?.direction ?? '';
    this.walkTimeText = this.currentPoint ? this.formatWalkTime(this.currentPoint.walkTime) : '';
    this.walkTimeRemaining = this.currentPoint?.walkTime ?? 0;

    // 恢复倒计时和音频
    this.startCountdown();
    this.restoreAudio();

    Logger.info('流转状态恢复完成');
  }

  /**
   * 保存当前状态到 ContinueService（用于自由流转）
   */
  private saveContinueState(): void {
    const elapsed = Math.round((Date.now() - this.startTime) / 1000);
    ContinueService.setCurrentState({
      page: 'WalkPage',
      duration: this.duration,
      remainingSeconds: this.remainingSeconds,
      startLat: this.startLat,
      startLon: this.startLon,
      redirectCount: this.redirectCount,
      trailPoints: this.trailPoints,
      currentPoint: this.currentPoint,
      isPaused: this.isPaused,
      startTime: this.startTime,
      elapsedSeconds: elapsed,
      currentSoundType: this.currentSoundType,
      currentSoundUri: this.currentSoundUri
    });
  }

  /**
   * 恢复地图标记（流转后重新添加）
   */
  private async restoreMapMarkers(): Promise<void> {
    if (!this.mapController) return;
    // 清除现有标记（通过设置不可见来模拟移除）
    for (const marker of this.trailMarkers) {
      marker.setVisible(false);
    }
    this.trailMarkers = [];

    // 重新添加历史标记
    for (let i = 0; i < this.trailPoints.length; i++) {
      const point = this.trailPoints[i];
      const isLast = i === this.trailPoints.length - 1;
      const marker = await this.mapController.addMarker({
        position: { latitude: point.latitude, longitude: point.longitude },
        draggable: false,
        flat: false,
        alpha: isLast ? 1 : 0.5,
        zIndex: point.index
      });
      if (marker) {
        this.trailMarkers.push(marker);
      }
    }
  }

  private async initWalk(): Promise<void> {
    try {
      let lat = this.startLat;
      let lon = this.startLon;
      try {
        const loc = await LocationService.getCurrentLocation();
        lat = loc.latitude;
        lon = loc.longitude;
      } catch (e) {
        Logger.warn('漫步中定位失败，使用传入坐标');
      }
      this.startLat = lat;
      this.startLon = lon;
      this.generateNewTarget(lat, lon);
      this.startTime = Date.now();
      this.startCountdown();
      const soundEnabled = await preferencesUtil.get(StoreKeys.SOUND_ENABLED, false) as boolean;
      if (soundEnabled) {
        const soundType = await preferencesUtil.get(StoreKeys.SOUND_TYPE, '无') as string;
        this.currentSoundType = soundType;
        if (soundType === '自定义') {
          const customUri = await preferencesUtil.get(StoreKeys.CUSTOM_AUDIO_URI, '') as string;
          this.currentSoundUri = customUri;
          if (customUri) { this.audioService.playByUri(customUri); }
        } else if (soundType !== '无') {
          this.audioService.play(soundType);
        }
      }
      Logger.info('漫步开始');
    } catch (e) { Logger.error(`初始化失败: ${JSON.stringify(e)}`); }
  }

  private async generateNewTarget(lat: number, lon: number): Promise<void> {
    // 将之前的标记变为历史标记（半透明）
    if (this.trailMarkers.length > 0) {
      const lastMarker = this.trailMarkers[this.trailMarkers.length - 1];
      lastMarker.setAlpha(0.5);
    }

    this.currentPoint = RandomService.generateRandomPoint(lat, lon);
    this.directionText = this.currentPoint.direction;
    this.walkTimeText = this.formatWalkTime(this.currentPoint.walkTime);
    this.walkTimeRemaining = this.currentPoint.walkTime;

    const markerIndex = this.trailMarkers.length + 1;
    const newMarker = await this.mapController?.addMarker({
      position: { latitude: this.currentPoint.latitude, longitude: this.currentPoint.longitude },
      draggable: false,
      flat: false,
      alpha: 1,
      zIndex: markerIndex
    });

    if (newMarker) {
      this.trailMarkers.push(newMarker);
      this.trailPoints.push({
        latitude: this.currentPoint.latitude,
        longitude: this.currentPoint.longitude,
        direction: this.currentPoint.direction,
        index: markerIndex
      });
    }

    Logger.info(`新目标[${markerIndex}]: ${this.directionText}, ${this.walkTimeText}`);
  }

  private startCountdown(): void {
    this.countdownTimer = setInterval(() => {
      if (!this.isPaused && this.remainingSeconds > 0) {
        this.remainingSeconds--;
        this.countdownText = this.formatTime(this.remainingSeconds);

        // 到达目标点自动换向
        if (this.walkTimeRemaining > 0) {
          this.walkTimeRemaining--;
          if (this.walkTimeRemaining <= 0) {
            this.redirectCount++;
            if (this.currentPoint) {
              this.generateNewTarget(this.currentPoint.latitude, this.currentPoint.longitude);
            }
          }
        }

        if (this.remainingSeconds <= 0) this.completeWalk();
      }
    }, 1000);
  }

  private formatTime(s: number): string {
    return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  }

  private formatWalkTime(s: number): string {
    if (s >= 60) {
      const m = Math.floor(s / 60);
      const sec = s % 60;
      return sec > 0 ? `${m}分${sec}秒` : `${m}分钟`;
    }
    return `${s}秒`;
  }

  private async completeWalk(): Promise<void> {
    this.cleanup();
    const dur = Math.round((Date.now() - this.startTime) / 1000);
    // 跳转到总结页面，传递轨迹数据
    router.replaceUrl({
      url: 'pages/WalkSummaryPage',
      params: {
        duration: dur,
        direction: this.currentPoint?.direction ?? '',
        redirectCount: this.redirectCount,
        trail: JSON.stringify(this.trailPoints)
      }
    });
  }

  private cleanup(): void {
    if (this.countdownTimer >= 0) clearInterval(this.countdownTimer);
    this.audioService.stop();
  }

  private restoreAudio(): void {
    if (this.isPaused) return;
    if (this.currentSoundType === '自定义' && this.currentSoundUri) {
      this.audioService.playByUri(this.currentSoundUri);
    } else if (this.currentSoundType && this.currentSoundType !== '无') {
      this.audioService.play(this.currentSoundType);
    }
  }

  // ==================== 控制面板构建器 ====================

  @Builder
  ControlPanelContent() {
    Column() {
      // 倒计时
      Text(this.countdownText)
        .fontSize(new BreakpointType({ sm: 32, md: 28, lg: 36 }).getValue(this.bp))
        .fontWeight(FontWeight.Bold)
        .fontColor('#4A6FA5')
        .margin({ bottom: 16 })

      // 方向 + 行走时间
      Column() {
        Text(this.directionText)
          .fontSize(new BreakpointType({ sm: 28, md: 24, lg: 26 }).getValue(this.bp))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
          .textAlign(TextAlign.Center)
        Text(`走 ${this.walkTimeText}`)
          .fontSize(new BreakpointType({ sm: 16, md: 14, lg: 15 }).getValue(this.bp))
          .fontColor('#888888')
          .margin({ top: 6 })
          .textAlign(TextAlign.Center)
      }
      .margin({ bottom: 16 })

      // 换向次数
      Text(`换向 ${this.redirectCount}次`)
        .fontSize(14)
        .fontColor('#888888')
        .margin({ bottom: 24 })

      // 控制按钮
      Column({ space: 12 }) {
        Button(this.isPaused ? '▶ 出发' : '⏸ 暂停')
          .fontSize(16)
          .fontColor('#4A6FA5')
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .width('80%')
          .height(48)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.isPaused = !this.isPaused;
            if (this.isPaused) {
              this.audioService.stop();
            } else if (this.currentSoundType === '自定义' && this.currentSoundUri) {
              this.audioService.playByUri(this.currentSoundUri);
            } else if (this.currentSoundType !== '无') {
              this.audioService.play(this.currentSoundType);
            }
          })

        Button('🔄 换方向')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#4A6FA5')
          .borderRadius(24)
          .width('80%')
          .height(48)
          .onClick(() => {
            if (this.currentPoint) {
              this.generateNewTarget(this.currentPoint.latitude, this.currentPoint.longitude);
              this.redirectCount++;
            }
          })

        Button('⏹ 结束')
          .fontSize(16)
          .fontColor('#FF6B6B')
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .width('80%')
          .height(48)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 })
          .onClick(() => { this.completeWalk(); })
      }
      .width('100%')

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .backgroundColor('#F5F7FA')
  }

  @Builder
  ControlPanel() {
    this.ControlPanelContent()
  }

  // ==================== sm 布局（手机竖屏 - 保持原有） ====================

  @Builder
  SmallScreenLayout() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 地图层（全屏底层）
      MapComponent({
        mapOptions: {
          position: { target: { latitude: this.startLat, longitude: this.startLon }, zoom: AppConstants.MAP_ZOOM },
          myLocationControlsEnabled: true,
          zoomControlsEnabled: false,
          compassControlsEnabled: false
        },
        mapCallback: (err, mapController) => {
          if (!err) { this.mapController = mapController; }
        }
      })
      .width('100%')
      .height('100%')

      // 顶部信息栏（绝对定位）
      Column() {
        Row() {
          Text('‹').fontSize(28).fontColor('#FFFFFF').width(44).height(44).textAlign(TextAlign.Center)
            .backgroundColor('#4A6FA580').borderRadius(22)
            .stateStyles({
              pressed: {
                .backgroundColor('#4A6FA5CC')
              }
            })
            .onClick(() => { this.cleanup(); router.back(); })
          Blank()
          Text(this.countdownText).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            .backgroundColor('#4A6FA5CC').borderRadius(24).padding({ left: 20, right: 20, top: 8, bottom: 8 })
        }
        .width('100%').padding({ left: 16, right: 16, top: 48, bottom: 8 })

        // 方向 + 行走时间
        Row() {
          Column() {
            Text(this.directionText)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .textShadow({ radius: 4, color: 'rgba(0,0,0,0.5)', offsetX: 0, offsetY: 2 })
            Text(`走 ${this.walkTimeText}`)
              .fontSize(18)
              .fontColor('#FFFFFFCC')
              .margin({ top: 6 })
              .textShadow({ radius: 3, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 1 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          Column() {
            Text(`换向 ${this.redirectCount}次`)
              .fontSize(14)
              .fontColor('#FFFFFFCC')
              .textShadow({ radius: 2, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: 1 })
          }.alignItems(HorizontalAlign.End)
        }
        .width('100%').padding({ left: 24, right: 24, top: 8, bottom: 8 })
      }
      .width('100%')
      .backgroundColor('#4A6FA510')
      .position({ x: 0, y: 0 })

      // 底部控制栏（绝对定位在底部）
      Column() {
        Row() {
          Button(this.isPaused ? '▶ 出发' : '⏸ 暂停').fontSize(16).fontColor('#4A6FA5').backgroundColor('#FFFFFF')
            .borderRadius(24).padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .onClick(() => {
              this.isPaused = !this.isPaused;
              if (this.isPaused) {
                this.audioService.stop();
              } else if (this.currentSoundType === '自定义' && this.currentSoundUri) {
                this.audioService.playByUri(this.currentSoundUri);
              } else if (this.currentSoundType !== '无') {
                this.audioService.play(this.currentSoundType);
              }
            })
          Blank()
          Button('🔄 换方向').fontSize(16).fontColor('#FFFFFF').backgroundColor('#4A6FA5')
            .borderRadius(24).padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .onClick(() => {
              if (this.currentPoint) { this.generateNewTarget(this.currentPoint.latitude, this.currentPoint.longitude); this.redirectCount++; }
            })
          Blank()
          Button('⏹ 结束').fontSize(16).fontColor('#FF6B6B').backgroundColor('#FFFFFF')
            .borderRadius(24).padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .onClick(() => { this.completeWalk(); })
        }
        .width('100%').padding({ left: 16, right: 16, bottom: 48, top: 16 })
        .backgroundColor('#FFFFFFF2')
        .borderRadius({ topLeft: 24, topRight: 24 })
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: -4 })
      }
      .width('100%')
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })

      // 完成弹窗（居中）
      if (this.showComplete) {
        Column() {
          Column() {
            Text('🎉').fontSize(64).margin({ bottom: 16 })
            Text('漫步完成').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#1A1A2E').margin({ bottom: 24 })
            Row() {
              Column() {
                Text(this.formatTime(Math.round((Date.now() - this.startTime) / 1000))).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#4A6FA5')
                Text('时长').fontSize(14).fontColor('#888888').margin({ top: 4 })
              }.layoutWeight(1)
              Column() {
                Text(`${this.redirectCount}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#4A6FA5')
                Text('换向').fontSize(14).fontColor('#888888').margin({ top: 4 })
              }.layoutWeight(1)
            }.width('100%').padding({ left: 24, right: 24 }).margin({ bottom: 32 })
            Button('返回首页').width('80%').height(48).fontSize(16).fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF').backgroundColor('#4A6FA5').borderRadius(24)
              .onClick(() => { router.replaceUrl({ url: 'pages/HomePage' }); })
          }
          .width('85%').backgroundColor('#FFFFFF').borderRadius(24).padding({ top: 40, bottom: 32 })
        }
        .width('100%').height('100%').backgroundColor('#00000066').justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E8F4F8')
  }

  // ==================== 主构建（统一使用全屏地图+底部控制栏） ====================

  build() {
    Stack() {
      this.SmallScreenLayout()
    }
    .width('100%')
    .height('100%')
  }
}
