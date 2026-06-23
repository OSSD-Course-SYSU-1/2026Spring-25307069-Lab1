import { router } from '@kit.ArkUI';
import { AppConstants } from '../constants/AppConstants';
import { QuoteConstants } from '../constants/QuoteConstants';
import { BreakpointConstants, BreakpointType } from '../constants/BreakpointConstants';
import { Logger } from '../utils/Logger';
import { preferencesUtil, StoreKeys } from '../utils/PreferencesUtil';
import { PermissionUtil } from '../utils/PermissionUtil';
import { LocationService } from '../service/LocationService';

@Entry
@Component
struct HomePage {
  @StorageProp(BreakpointConstants.BREAKPOINT_KEY) bp: string = BreakpointConstants.BREAKPOINT_SM_NAME;
  @State quote: string = '';
  @State walkCount: number = 0;
  @State totalDuration: number = 0;
  @State locationReady: boolean = false;
  @State usingDefaultLocation: boolean = false;
  @State selectedDuration: number = AppConstants.DEFAULT_TIMER;
  @State showCustomDurationDialog: boolean = false;
  @State customDurationInput: string = '30';
  @State showGuide: boolean = false;
  @State guideIndex: number = 0;
  private startLat: number = AppConstants.DEFAULT_LAT;
  private startLon: number = AppConstants.DEFAULT_LON;

  // 响应式间距配置
  private pagePadding = new BreakpointType({ sm: 16, md: 32, lg: 48 });
  private cardPadding = new BreakpointType({ sm: 12, md: 20, lg: 24 });
  private buttonWidth = new BreakpointType({ sm: '80%', md: '70%', lg: '60%' });
  private dialogWidth = new BreakpointType({ sm: '92%', md: '80%', lg: '60%' });
  private statsHeight = new BreakpointType({ sm: 90, md: 100, lg: 110 });
  private statsNumberSize = new BreakpointType({ sm: 32, md: 36, lg: 40 });
  private durationNumberSize = new BreakpointType({ sm: 22, md: 24, lg: 26 });
  private sliderMin: number = 5;
  private sliderMax: number = 120;
  private sliderStep: number = 5;

  private guideImages: Resource[] = [$r('app.media.guide_home'), $r('app.media.guide_walk'), $r('app.media.guide_summary')];
  private guideTitles: string[] = ['选择漫步时长', '跟随方向指引', '记录美好瞬间'];
  private guideDescs: string[] = ['选择你想要的漫步时间，点击开始漫步', '根据地图上的方向指引，自由探索城市', '漫步结束后，记录你的感受和添加照片'];

  aboutToAppear(): void {
    this.quote = QuoteConstants.getRandomQuote();
    this.loadStats();
    this.initLocation();
    this.checkFirstLaunch();
  }

  private async checkFirstLaunch(): Promise<void> {
    const hasLaunched = await preferencesUtil.get('has_launched', false) as boolean;
    if (!hasLaunched) {
      this.showGuide = true;
      await preferencesUtil.put('has_launched', true);
    }
  }

  private async loadStats(): Promise<void> {
    this.walkCount = await preferencesUtil.get(StoreKeys.WALK_COUNT, 0) as number;
    this.totalDuration = await preferencesUtil.get(StoreKeys.TOTAL_DURATION, 0) as number;
  }

  private async initLocation(): Promise<void> {
    this.startLat = AppConstants.DEFAULT_LAT;
    this.startLon = AppConstants.DEFAULT_LON;
    this.locationReady = true;

    const granted: boolean = await PermissionUtil.requestLocationPermissions();
    if (!granted) {
      this.usingDefaultLocation = true;
      Logger.warn('定位权限未授予，使用默认坐标');
      return;
    }
    if (!LocationService.isLocationEnabled()) {
      this.usingDefaultLocation = true;
      Logger.warn('定位服务未开启，使用默认坐标');
      return;
    }
    try {
      const loc = await LocationService.getCurrentLocation();
      this.startLat = loc.latitude;
      this.startLon = loc.longitude;
      this.usingDefaultLocation = false;
      Logger.info('已获取真实位置');
    } catch (e) {
      this.usingDefaultLocation = true;
      Logger.warn('定位失败，使用默认坐标');
    }
  }

  private formatDuration(): string {
    const h = Math.floor(this.totalDuration / 3600);
    const m = Math.floor((this.totalDuration % 3600) / 60);
    return h > 0 ? `${h}小时${m}分钟` : `${m}分钟`;
  }

  private onDurationSelect(dur: number): void {
    this.selectedDuration = dur;
  }

  build() {
    Stack() {
      Column() {
        // 顶部标题栏
        Row() {
          Text('无目的地图')
            .fontSize(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          Blank()
          Button({ type: ButtonType.Circle }) {
            Text('⚙').fontSize(18)
          }
          .width(40)
          .height(40)
          .backgroundColor('#F0F0F0')
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsPage' });
          })
        }
        .width('100%')
        .padding({
          left: this.pagePadding.getValue(this.bp),
          right: this.pagePadding.getValue(this.bp),
          top: new BreakpointType({ sm: 64, md: 48, lg: 40 }).getValue(this.bp)
        })

        // 引言区域
        Text(`「${this.quote}」`)
          .fontSize(15)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .lineHeight(26)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('85%')
          .padding({ top: 8, bottom: 8 })

        // 统计卡片
        Row({ space: new BreakpointType({ sm: 12, md: 16, lg: 20 }).getValue(this.bp) }) {
          Column() {
            Text(`${this.walkCount}`)
              .fontSize(this.statsNumberSize.getValue(this.bp))
              .fontWeight(FontWeight.Bold)
              .fontColor('#4A6FA5')
            Text('次漫步')
              .fontSize(new BreakpointType({ sm: 13, md: 14, lg: 15 }).getValue(this.bp))
              .fontColor('#888888')
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .height(this.statsHeight.getValue(this.bp))
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 4 })
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(this.formatDuration())
              .fontSize(this.durationNumberSize.getValue(this.bp))
              .fontWeight(FontWeight.Bold)
              .fontColor('#4A6FA5')
            Text('累计时长')
              .fontSize(new BreakpointType({ sm: 13, md: 14, lg: 15 }).getValue(this.bp))
              .fontColor('#888888')
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .height(this.statsHeight.getValue(this.bp))
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 4 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: this.pagePadding.getValue(this.bp), right: this.pagePadding.getValue(this.bp) })
        .margin({ top: new BreakpointType({ sm: 16, md: 20, lg: 24 }).getValue(this.bp) })

        // 时长选择卡片
        Column() {
          // 漫步时长标签
          Text('漫步时长')
            .fontSize(new BreakpointType({ sm: 13, md: 14, lg: 15 }).getValue(this.bp))
            .fontColor('#4A6FA5')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 4 })

          // 当前选择的时间显示
          Text(this.selectedDuration < 0 ? '自定义' : `${this.selectedDuration}分钟`)
            .fontSize(new BreakpointType({ sm: 24, md: 26, lg: 28 }).getValue(this.bp))
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A6FA5')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: new BreakpointType({ sm: 10, md: 12, lg: 14 }).getValue(this.bp) })

          // 滑动式时长选择按钮列表
          Scroll() {
            Row({ space: 8 }) {
              ForEach(AppConstants.TIMER_OPTIONS, (dur: number) => {
                Text(`${dur}分钟`)
                  .fontSize(13)
                  .fontWeight(this.selectedDuration === dur ? FontWeight.Medium : FontWeight.Normal)
                  .fontColor(this.selectedDuration === dur ? '#FFFFFF' : '#4A6FA5')
                  .backgroundColor(this.selectedDuration === dur ? '#4A6FA5' : '#E8F4F8')
                  .borderRadius(18)
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .onClick(() => this.onDurationSelect(dur))
              })
              // 自定义时长按钮
              Text('自定义')
                .fontSize(13)
                .fontWeight(this.selectedDuration < 0 ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.selectedDuration < 0 ? '#FFFFFF' : '#4A6FA5')
                .backgroundColor(this.selectedDuration < 0 ? '#4A6FA5' : '#E8F4F8')
                .borderRadius(18)
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .onClick(() => {
                  this.customDurationInput = this.selectedDuration < 0 ? '30' : `${this.selectedDuration}`;
                  this.showCustomDurationDialog = true;
                })
            }
            .padding({ left: 4, right: 4 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .padding(this.cardPadding.getValue(this.bp))
        .backgroundColor('#FFFFFF')
        .borderRadius(new BreakpointType({ sm: 16, md: 18, lg: 20 }).getValue(this.bp))
        .shadow({ radius: 6, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 3 })
        .margin({
          top: new BreakpointType({ sm: 16, md: 20, lg: 24 }).getValue(this.bp),
          left: this.pagePadding.getValue(this.bp),
          right: this.pagePadding.getValue(this.bp)
        })

        // 开始按钮
        Button('开始漫步')
          .width(this.buttonWidth.getValue(this.bp) as string)
          .height(new BreakpointType({ sm: 52, md: 54, lg: 56 }).getValue(this.bp))
          .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(this.locationReady ? '#4A6FA5' : '#CCCCCC')
          .borderRadius(new BreakpointType({ sm: 26, md: 27, lg: 28 }).getValue(this.bp))
          .enabled(this.locationReady)
          .shadow({
            radius: this.locationReady ? 12 : 0,
            color: 'rgba(74,111,165,0.3)',
            offsetX: 0,
            offsetY: 4
          })
          .margin({ top: new BreakpointType({ sm: 36, md: 40, lg: 48 }).getValue(this.bp) })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WalkPage',
              params: {
                duration: this.selectedDuration,
                startLat: this.startLat,
                startLon: this.startLon
              }
            });
          })

        // 默认位置提示
        if (this.usingDefaultLocation) {
          Text('📍 当前使用默认位置')
            .fontSize(12)
            .fontColor('#C9A227')
            .margin({ top: 12 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: new BreakpointType({ sm: 80, md: 90, lg: 100 }).getValue(this.bp) })
      .alignItems(HorizontalAlign.Center)

      // 底部导航栏 - 固定在最底部
      Row() {
        Column() {
          Text('🏠').fontSize(new BreakpointType({ sm: 22, md: 24, lg: 26 }).getValue(this.bp))
          Text('首页')
            .fontSize(new BreakpointType({ sm: 11, md: 12, lg: 13 }).getValue(this.bp))
            .fontColor('#4A6FA5')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .padding(new BreakpointType({ sm: 8, md: 10, lg: 12 }).getValue(this.bp))

        Column() {
          Text('📋').fontSize(new BreakpointType({ sm: 22, md: 24, lg: 26 }).getValue(this.bp))
          Text('记录')
            .fontSize(new BreakpointType({ sm: 11, md: 12, lg: 13 }).getValue(this.bp))
            .fontColor('#888888')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .padding(new BreakpointType({ sm: 8, md: 10, lg: 12 }).getValue(this.bp))
        .onClick(() => {
          router.pushUrl({ url: 'pages/RecordPage' });
        })
      }
      .width('100%')
      .height(new BreakpointType({ sm: 64, md: 72, lg: 80 }).getValue(this.bp))
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: -4 })
      .position({ x: '0%', y: '100%' })
      .translate({ y: '-100%' })

      // 首次使用引导弹窗
      if (this.showGuide) {
        Column() {
          Column() {
            Text('欢迎来到无目的漫步').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A2E').margin({ bottom: 16 })

            Swiper() {
              ForEach(this.guideImages, (img: Resource, index: number) => {
                Column({ space: 12 }) {
                  Image(img).width('100%').height(200).objectFit(ImageFit.Contain).borderRadius(12)
                  Text(this.guideTitles[index]).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#4A6FA5')
                  Text(this.guideDescs[index]).fontSize(14).fontColor('#888888').textAlign(TextAlign.Center)
                }
                .width('100%').padding(8)
              })
            }
            .index(this.guideIndex)
            .width('100%')
            .height(300)
            .indicator(true)
            .loop(false)
            .onChange((index: number) => {
              this.guideIndex = index;
            })

            Button('我知道了').width('100%').height(44).fontSize(16).fontColor('#FFFFFF').backgroundColor('#4A6FA5').borderRadius(22)
              .margin({ top: 16 })
              .onClick(() => { this.showGuide = false; })
          }
          .width(this.dialogWidth.getValue(this.bp) as string).padding(24)
          .backgroundColor('#FFFFFF').borderRadius(20)
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 8 })
        }
        .width('100%').height('100%').backgroundColor('#000000B3')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 })
      }

      // 自定义时长弹窗
      if (this.showCustomDurationDialog) {
        Column() {
          Column({ space: 20 }) {
            Text('自定义漫步时长').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#1A1A2E')

            Text('输入漫步时长（分钟）').fontSize(14).fontColor('#888888')

            TextInput({ text: this.customDurationInput, placeholder: '请输入分钟数' })
              .type(InputType.Number)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4A6FA5')
              .textAlign(TextAlign.Center)
              .height(56)
              .backgroundColor('#F0F4F8')
              .borderRadius(16)
              .onChange((value: string) => {
                this.customDurationInput = value;
              })

            Text('建议范围：5 - 120 分钟').fontSize(12).fontColor('#AAAAAA')

            Row({ space: 12 }) {
              Button('取消')
                .layoutWeight(1)
                .height(44).fontSize(15).fontColor('#4A6FA5')
                .backgroundColor('#E8EDF5').borderRadius(22)
                .onClick(() => { this.showCustomDurationDialog = false; })
              Button('确定')
                .layoutWeight(1)
                .height(44).fontSize(15).fontColor('#FFFFFF')
                .backgroundColor('#4A6FA5').borderRadius(22)
                .onClick(() => {
                  const val: number = parseInt(this.customDurationInput);
                  if (val > 0) {
                    const clamped: number = Math.min(Math.max(val, 1), 999);
                    this.selectedDuration = clamped;
                  }
                  this.showCustomDurationDialog = false;
                })
            }
            .width('100%')
          }
          .width(this.dialogWidth.getValue(this.bp) as string).padding(28)
          .backgroundColor('#FFFFFF').borderRadius(20)
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 8 })
        }
        .width('100%').height('100%').backgroundColor('#000000B3')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
