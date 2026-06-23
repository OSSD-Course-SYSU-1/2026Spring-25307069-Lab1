import { router } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { preferencesUtil, StoreKeys } from '../utils/PreferencesUtil';
import { WalkRecord, TrailPoint } from '../model/WalkRecord';
import { Logger } from '../utils/Logger';
import { QuoteConstants } from '../constants/QuoteConstants';
import { BreakpointConstants, BreakpointType } from '../constants/BreakpointConstants';

@Entry
@Component
struct WalkSummaryPage {
  @StorageProp(BreakpointConstants.BREAKPOINT_KEY) bp: string = BreakpointConstants.BREAKPOINT_SM_NAME;
  @State duration: number = 0;
  @State walkDirection: string = '';
  @State redirectCount: number = 0;
  @State feeling: string = '';
  @State photos: string[] = [];
  @State showComplete: boolean = false;
  @State randomPlaceholder: string = '';
  @State randomTitle: string = '';
  private trail: TrailPoint[] = [];

  private maxPhotos: number = 3;

  // 响应式配置
  private pagePadding = new BreakpointType({ sm: 24, md: 32, lg: 48 });
  private cardPadding = new BreakpointType({ sm: 16, md: 20, lg: 24 });
  private dialogWidth = new BreakpointType({ sm: '100%', md: '90%', lg: '70%' });
  private statsFontSize = new BreakpointType({ sm: 24, md: 26, lg: 28 });



  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.duration = (params['duration'] as number) ?? 0;
      this.walkDirection = (params['direction'] as string) ?? '';
      this.redirectCount = (params['redirectCount'] as number) ?? 0;
      const trailStr = (params['trail'] as string) ?? '[]';
      try {
        this.trail = JSON.parse(trailStr) as TrailPoint[];
      } catch (e) {
        this.trail = [];
      }
    }
    // 随机选择标题和placeholder
    this.randomTitle = QuoteConstants.getRandomTitle();
    this.randomPlaceholder = QuoteConstants.getRandomFeeling();
  }

  private async pickFromAlbum(): Promise<void> {
    if (this.photos.length >= this.maxPhotos) {
      return;
    }
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = this.maxPhotos - this.photos.length;
      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoViewPicker.select(photoSelectOptions);
      if (result.photoUris && result.photoUris.length > 0) {
        for (const uri of result.photoUris) {
          if (this.photos.length < this.maxPhotos) {
            const savedPath = await this.copyPhotoToApp(uri);
            if (savedPath) {
              this.photos.push(savedPath);
            }
          }
        }
      }
    } catch (e) {
      Logger.error(`选择照片失败: ${JSON.stringify(e)}`);
    }
  }

  private async copyPhotoToApp(uri: string): Promise<string | null> {
    try {
      const fileName = `walk_photo_${Date.now()}.jpg`;
      const destPath = `${getContext().filesDir}/${fileName}`;
      fileIo.copyFileSync(uri, destPath);
      return destPath;
    } catch (e) {
      Logger.error(`复制照片失败: ${JSON.stringify(e)}`);
      return null;
    }
  }

  private removePhoto(index: number): void {
    if (index >= 0 && index < this.photos.length) {
      try {
        fileIo.unlinkSync(this.photos[index]);
      } catch (e) {
        Logger.error(`删除照片文件失败: ${JSON.stringify(e)}`);
      }
      this.photos.splice(index, 1);
    }
  }

  private async saveRecord(): Promise<void> {
    // 如果用户没有输入感受，自动填充随机语句
    let finalFeeling = this.feeling.trim();
    if (finalFeeling.length === 0) {
      finalFeeling = this.randomPlaceholder;
    }
    const record = new WalkRecord(this.duration, this.walkDirection, this.redirectCount, finalFeeling, this.photos, this.trail);
    const recordsStr = await preferencesUtil.get(StoreKeys.WALK_RECORDS, '[]') as string;
    const records: string[] = JSON.parse(recordsStr);
    records.unshift(record.toJSON());
    if (records.length > 100) records.length = 100;
    await preferencesUtil.put(StoreKeys.WALK_RECORDS, JSON.stringify(records));
    const count = await preferencesUtil.get(StoreKeys.WALK_COUNT, 0) as number;
    const total = await preferencesUtil.get(StoreKeys.TOTAL_DURATION, 0) as number;
    await preferencesUtil.put(StoreKeys.WALK_COUNT, count + 1);
    await preferencesUtil.put(StoreKeys.TOTAL_DURATION, total + this.duration);
    this.showComplete = true;
  }

  private skip(): void {
    this.saveRecord();
  }

  private formatDuration(): string {
    const m = Math.floor(this.duration / 60);
    const s = this.duration % 60;
    return s > 0 ? `${m}分${s}秒` : `${m}分钟`;
  }

  private controller: TextAreaController = new TextAreaController()

  build() {
    Stack() {
      Scroll() {
        Column() {
          // 标题栏
          Row() {
            Text('').width(44)
            Text('漫步完成')
              .fontSize(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A2E')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text('跳过')
              .fontSize(new BreakpointType({ sm: 16, md: 16, lg: 16 }).getValue(this.bp))
              .fontColor('#4A6FA5')
              .width(50)
              .onClick(() => { this.skip(); })
          }
          .width('100%')
          .padding({
            left: this.pagePadding.getValue(this.bp),
            right: this.pagePadding.getValue(this.bp),
            top: 16,
            bottom: 16
          })

          // 统计信息
          Row() {
            Column() {
              Text(this.walkDirection)
                .fontSize(this.statsFontSize.getValue(this.bp))
                .fontWeight(FontWeight.Bold)
                .fontColor('#4A6FA5')
              Text('最终方向')
                .fontSize(new BreakpointType({ sm: 12, md: 13, lg: 14 }).getValue(this.bp))
                .fontColor('#888888')
                .margin({ top: 4 })
            }.layoutWeight(1)
            Column() {
              Text(this.formatDuration())
                .fontSize(this.statsFontSize.getValue(this.bp))
                .fontWeight(FontWeight.Bold)
                .fontColor('#4A6FA5')
              Text('时长')
                .fontSize(new BreakpointType({ sm: 12, md: 13, lg: 14 }).getValue(this.bp))
                .fontColor('#888888')
                .margin({ top: 4 })
            }.layoutWeight(1)
            Column() {
              Text(`${this.redirectCount}`)
                .fontSize(this.statsFontSize.getValue(this.bp))
                .fontWeight(FontWeight.Bold)
                .fontColor('#4A6FA5')
              Text('换向')
                .fontSize(new BreakpointType({ sm: 12, md: 13, lg: 14 }).getValue(this.bp))
                .fontColor('#888888')
                .margin({ top: 4 })
            }.layoutWeight(1)
          }
          .width('100%')
          .padding(this.cardPadding.getValue(this.bp))
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 16, md: 18, lg: 20 }).getValue(this.bp))
          .margin({
            left: this.pagePadding.getValue(this.bp),
            right: this.pagePadding.getValue(this.bp),
            bottom: new BreakpointType({ sm: 16, md: 20, lg: 24 }).getValue(this.bp)
          })

          // 感受记录
          Column() {
            Text(this.randomTitle)
              .fontSize(new BreakpointType({ sm: 18, md: 19, lg: 20 }).getValue(this.bp))
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A2E')
              .width('100%')
              .margin({ bottom: 12 })

            TextArea({ placeholder: this.randomPlaceholder, text: $$this.feeling, controller: this.controller })
              .width('100%')
              .height(new BreakpointType({ sm: 200, md: 180, lg: 160 }).getValue(this.bp))
              .backgroundColor('#F5F7FA')
              .borderRadius(12)
              .padding(16)
          }
          .width('100%')
          .padding(this.cardPadding.getValue(this.bp))
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 16, md: 18, lg: 20 }).getValue(this.bp))
          .margin({
            left: this.pagePadding.getValue(this.bp),
            right: this.pagePadding.getValue(this.bp),
            bottom: new BreakpointType({ sm: 16, md: 20, lg: 24 }).getValue(this.bp)
          })

          // 照片上传
          Column() {
            Row() {
              Text('添加照片')
                .fontSize(new BreakpointType({ sm: 18, md: 19, lg: 20 }).getValue(this.bp))
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A2E')
              Text(`(${this.photos.length}/${this.maxPhotos})`)
                .fontSize(14)
                .fontColor('#888888')
                .margin({ left: 8 })
              Blank()
              if (this.photos.length < this.maxPhotos) {
                Text('+')
                  .fontSize(24)
                  .fontColor('#4A6FA5')
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .onClick(() => { this.pickFromAlbum(); })
              }
            }
            .width('100%')
            .margin({ bottom: 12 })

            if (this.photos.length > 0) {
              // sm: 横向排列；md/lg: 使用 Grid 自适应列数
              if (this.bp === BreakpointConstants.BREAKPOINT_SM_NAME) {
                Row({ space: 8 }) {
                  ForEach(this.photos, (photo: string, index: number) => {
                    Stack() {
                      Image(photo).width(80).height(80).borderRadius(8).objectFit(ImageFit.Cover)
                      Text('×').fontSize(16).fontColor('#FFFFFF').width(20).height(20).textAlign(TextAlign.Center)
                        .backgroundColor('#FF6B6B').borderRadius(10)
                        .position({ x: 70, y: -5 })
                        .onClick(() => { this.removePhoto(index); })
                    }
                  })
                }
                .width('100%')
              } else {
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(this.photos, (photo: string, index: number) => {
                    Stack() {
                      Image(photo)
                        .width(new BreakpointType({ sm: 80, md: 90, lg: 100 }).getValue(this.bp))
                        .height(new BreakpointType({ sm: 80, md: 90, lg: 100 }).getValue(this.bp))
                        .borderRadius(8)
                        .objectFit(ImageFit.Cover)
                        .margin(6)
                      Text('×')
                        .fontSize(16)
                        .fontColor('#FFFFFF')
                        .width(20)
                        .height(20)
                        .textAlign(TextAlign.Center)
                        .backgroundColor('#FF6B6B')
                        .borderRadius(10)
                        .position({
                          x: new BreakpointType({ sm: 70, md: 80, lg: 90 }).getValue(this.bp),
                          y: -5
                        })
                        .onClick(() => { this.removePhoto(index); })
                    }
                  })
                }
                .width('100%')
              }
            }
          }
          .width('100%')
          .padding(this.cardPadding.getValue(this.bp))
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 16, md: 18, lg: 20 }).getValue(this.bp))
          .margin({
            left: this.pagePadding.getValue(this.bp),
            right: this.pagePadding.getValue(this.bp)
          })

          // 保存按钮
          Button('保存记录')
            .width(new BreakpointType({ sm: '90%', md: '80%', lg: '60%' }).getValue(this.bp) as string)
            .height(new BreakpointType({ sm: 52, md: 54, lg: 56 }).getValue(this.bp))
            .fontSize(new BreakpointType({ sm: 18, md: 19, lg: 20 }).getValue(this.bp))
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#4A6FA5')
            .borderRadius(new BreakpointType({ sm: 26, md: 27, lg: 28 }).getValue(this.bp))
            .margin({
              top: new BreakpointType({ sm: 24, md: 32, lg: 40 }).getValue(this.bp),
              bottom: new BreakpointType({ sm: 32, md: 40, lg: 48 }).getValue(this.bp)
            })
            .onClick(() => { this.saveRecord(); })
        }
        .width('100%')
        .backgroundColor('#F5F7FA')
      }
      .width('100%')
      .height('100%')
      .onClick(() => {
        // 点击空白处收起键盘
        this.controller.stopEditing()
      })

      // 撒花完成弹窗
      if (this.showComplete) {
        Column() {
          Column() {
            Text('🎉').fontSize(56).margin({ bottom: 12 })
            Text('漫步完成').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1A1A2E').margin({ bottom: 6 })
            Text('记录已保存').fontSize(15).fontColor('#888888').margin({ bottom: 24 })
            Button('返回首页')
              .width(new BreakpointType({ sm: '85%', md: '75%', lg: '55%' }).getValue(this.bp) as string)
              .height(44)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor('#4A6FA5')
              .borderRadius(22)
              .onClick(() => { router.back({ url: 'pages/HomePage' }); })
          }
          .width(this.dialogWidth.getValue(this.bp) as string)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding({ top: 28, bottom: 24 })
          .shadow({ radius: 16, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 8 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
