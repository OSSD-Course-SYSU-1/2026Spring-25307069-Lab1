import { router } from '@kit.ArkUI';
import { Logger } from '../utils/Logger';
import { preferencesUtil, StoreKeys } from '../utils/PreferencesUtil';
import { WalkRecord, TrailPoint } from '../model/WalkRecord';
import { ThemeConstants } from '../constants/ThemeConstants';
import { QuoteConstants } from '../constants/QuoteConstants';
import { BreakpointConstants, BreakpointType } from '../constants/BreakpointConstants';

@Entry
@Component
struct RecordPage {
  @StorageProp(BreakpointConstants.BREAKPOINT_KEY) bp: string = BreakpointConstants.BREAKPOINT_SM_NAME;
  @State walkCount: number = 0;
  @State totalDuration: number = 0;
  @State records: WalkRecord[] = [];
  @State isEmpty: boolean = true;
  @State showDeleteDialog: boolean = false;
  @State deleteIndex: number = -1;
  @State showDetailDialog: boolean = false;
  @State selectedRecord: WalkRecord | null = null;
  @State showPhotoPreview: boolean = false;
  @State previewPhotoIndex: number = 0;
  @State showShareCard: boolean = false;

  // 响应式配置
  private pagePadding = new BreakpointType({ sm: 24, md: 32, lg: 48 });
  private cardPadding = new BreakpointType({ sm: 16, md: 20, lg: 24 });
  private detailDialogWidth = new BreakpointType({ sm: '92%', md: '80%', lg: '65%' });
  private detailDialogHeight = new BreakpointType({ sm: '70%', md: '65%', lg: '60%' });

  aboutToAppear(): void {
    this.loadRecords();
  }

  private async loadRecords(): Promise<void> {
    this.walkCount = await preferencesUtil.get(StoreKeys.WALK_COUNT, 0) as number;
    this.totalDuration = await preferencesUtil.get(StoreKeys.TOTAL_DURATION, 0) as number;
    const recordsStr = await preferencesUtil.get(StoreKeys.WALK_RECORDS, '[]') as string;
    const arr: string[] = JSON.parse(recordsStr);
    this.records = arr.map((s: string) => WalkRecord.fromJSON(s));
    this.isEmpty = this.records.length === 0;
  }

  private formatDuration(): string {
    const h = Math.floor(this.totalDuration / 3600);
    const m = Math.floor((this.totalDuration % 3600) / 60);
    return h > 0 ? `${h}小时${m}分钟` : `${m}分钟`;
  }

  private async deleteRecord(index: number): Promise<void> {
    if (index < 0 || index >= this.records.length) return;
    // 删除记录
    this.records.splice(index, 1);
    const arr: string[] = this.records.map((r: WalkRecord) => r.toJSON());
    await preferencesUtil.put(StoreKeys.WALK_RECORDS, JSON.stringify(arr));
    // 重新计算统计数据
    this.walkCount = this.records.length;
    this.totalDuration = this.records.reduce((sum, r) => sum + r.duration, 0);
    await preferencesUtil.put(StoreKeys.WALK_COUNT, this.walkCount);
    await preferencesUtil.put(StoreKeys.TOTAL_DURATION, this.totalDuration);
    this.isEmpty = this.records.length === 0;
    this.showDeleteDialog = false;
    this.deleteIndex = -1;
  }

  private showDetail(record: WalkRecord): void {
    this.selectedRecord = record;
    this.showDetailDialog = true;
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('‹').fontSize(28).fontColor(ThemeConstants.TEXT_PRIMARY).width(44).height(44).textAlign(TextAlign.Center)
            .borderRadius(ThemeConstants.RADIUS_FULL)
            .stateStyles({
              pressed: {
                .backgroundColor('#F0F0F0')
              }
            })
            .onClick(() => { router.back(); })
          Text('漫步记录')
            .fontSize(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeConstants.TEXT_PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Text('').width(44)
        }
        .width('100%')
        .padding({
          left: new BreakpointType({ sm: 8, md: 16, lg: 24 }).getValue(this.bp),
          right: this.pagePadding.getValue(this.bp),
          top: 16,
          bottom: 16
        })

        if (this.isEmpty) {
          Column() {
            Text('🚶').fontSize(64).margin({ bottom: 16 })
            Text('还没有漫步记录').fontSize(18).fontColor(ThemeConstants.TEXT_SECONDARY)
            Text('开始你的第一次无目的漫步吧').fontSize(14).fontColor(ThemeConstants.TEXT_MUTED).margin({ top: 8 })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          Row() {
            Column() {
              Text(`${this.walkCount}`)
                .fontSize(new BreakpointType({ sm: 28, md: 30, lg: 32 }).getValue(this.bp))
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeConstants.PRIMARY);
              Text('总次数')
                .fontSize(new BreakpointType({ sm: 12, md: 13, lg: 14 }).getValue(this.bp))
                .fontColor(ThemeConstants.TEXT_SECONDARY)
                .margin({ top: 4 })
            }.layoutWeight(1)
            Column() {
              Text(this.formatDuration())
                .fontSize(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeConstants.PRIMARY);
              Text('总时长')
                .fontSize(new BreakpointType({ sm: 12, md: 13, lg: 14 }).getValue(this.bp))
                .fontColor(ThemeConstants.TEXT_SECONDARY)
                .margin({ top: 4 })
            }.layoutWeight(1)
          }
          .width('100%')
          .padding({ left: this.pagePadding.getValue(this.bp), right: this.pagePadding.getValue(this.bp), top: 16, bottom: 16 })
          .backgroundColor(ThemeConstants.CARD_BG)
          .borderRadius(ThemeConstants.RADIUS_SM)
          .margin({ left: this.pagePadding.getValue(this.bp), right: this.pagePadding.getValue(this.bp), bottom: 16 })

          List({ space: new BreakpointType({ sm: 12, md: 14, lg: 16 }).getValue(this.bp) }) {
            ForEach(this.records, (record: WalkRecord, index: number) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(record.date)
                      .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                    Text(`${record.direction} · ${record.formatDuration()} · 换向${record.redirectCount}次`)
                      .fontSize(new BreakpointType({ sm: 13, md: 14, lg: 14 }).getValue(this.bp))
                      .fontColor('#666666')
                      .margin({ top: 4 })
                    // 显示感受（如果有）
                    if (record.feeling && record.feeling.length > 0) {
                      Text(`💭 ${record.feeling}`)
                        .fontSize(12)
                        .fontColor(ThemeConstants.PRIMARY)
                        .margin({ top: 6 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    // 显示照片缩略图（如果有）
                    if (record.photos && record.photos.length > 0) {
                      Row({ space: 4 }) {
                        ForEach(record.photos.slice(0, 3), (photo: string) => {
                          Image(photo)
                            .width(new BreakpointType({ sm: 40, md: 44, lg: 48 }).getValue(this.bp))
                            .height(new BreakpointType({ sm: 40, md: 44, lg: 48 }).getValue(this.bp))
                            .borderRadius(4)
                            .objectFit(ImageFit.Cover)
                        })
                        if (record.photos.length > 3) {
                          Text(`+${record.photos.length - 3}`)
                            .fontSize(12)
                            .fontColor(ThemeConstants.TEXT_SECONDARY)
                            .width(new BreakpointType({ sm: 40, md: 44, lg: 48 }).getValue(this.bp))
                            .height(new BreakpointType({ sm: 40, md: 44, lg: 48 }).getValue(this.bp))
                            .textAlign(TextAlign.Center)
                            .backgroundColor(ThemeConstants.BG)
                            .borderRadius(4)
                        }
                      }
                      .width('100%')
                      .margin({ top: 6 })
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .onClick(() => { this.showDetail(record); })

                  // 删除按钮
                  Text('🗑')
                    .fontSize(20)
                    .width(40)
                    .height(40)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.deleteIndex = index;
                      this.showDeleteDialog = true;
                    })
                }
                .width('100%')
                .padding({
                  left: this.cardPadding.getValue(this.bp),
                  right: 8,
                  top: this.cardPadding.getValue(this.bp),
                  bottom: this.cardPadding.getValue(this.bp)
                })
                .backgroundColor(ThemeConstants.CARD_BG)
                .borderRadius(ThemeConstants.RADIUS_XS)
              }
            })
          }
          .layoutWeight(1)
          .padding({ left: this.pagePadding.getValue(this.bp), right: this.pagePadding.getValue(this.bp) })
          .margin({ top: 8 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeConstants.BG)

      // 删除确认弹窗
      if (this.showDeleteDialog) {
        Column() {
          Column() {
            Text('删除记录').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ThemeConstants.TEXT_PRIMARY).margin({ bottom: 16 })
            Text('确定要删除这条漫步记录吗？').fontSize(16).fontColor(ThemeConstants.TEXT_SECONDARY).margin({ bottom: 24 })
            Row() {
              Button('取消').width('45%').height(44).fontSize(16).fontColor(ThemeConstants.TEXT_SECONDARY).backgroundColor(ThemeConstants.BG).borderRadius(ThemeConstants.RADIUS_FULL)
                .onClick(() => { this.showDeleteDialog = false; this.deleteIndex = -1; })
              Button('删除').width('45%').height(44).fontSize(16).fontColor(ThemeConstants.CARD_BG).backgroundColor(ThemeConstants.TEXT_DANGER).borderRadius(ThemeConstants.RADIUS_FULL)
                .onClick(() => { this.deleteRecord(this.deleteIndex); })
            }.width('100%').justifyContent(FlexAlign.SpaceBetween)
          }
          .width('80%').backgroundColor(ThemeConstants.CARD_BG).borderRadius(ThemeConstants.RADIUS_MD).padding(24)
            .shadow(ThemeConstants.SHADOW_MODAL)
        }
        .width('100%').height('100%').backgroundColor(ThemeConstants.OVERLAY).justifyContent(FlexAlign.Center)
      }

      // 详情弹窗
      if (this.showDetailDialog && this.selectedRecord) {
        Column() {
          Scroll() {
            Column() {
              Text('漫步详情').fontSize(20).fontWeight(FontWeight.Bold).fontColor(ThemeConstants.TEXT_PRIMARY).margin({ bottom: 16 })
              
              Column() {
                Text(this.selectedRecord.date).fontSize(16).fontColor(ThemeConstants.TEXT_SECONDARY).margin({ bottom: 8 })
                Text(`${this.selectedRecord.direction} · ${this.selectedRecord.formatDuration()} · 换向${this.selectedRecord.redirectCount}次`).fontSize(14).fontColor(ThemeConstants.TEXT_SECONDARY)
              }
              .width('100%').margin({ bottom: 16 })

              if (this.selectedRecord.feeling && this.selectedRecord.feeling.length > 0) {
                Column() {
                  Text('感受').fontSize(14).fontColor(ThemeConstants.TEXT_SECONDARY).margin({ bottom: 8 })
                  Text(this.selectedRecord.feeling).fontSize(16).fontColor(ThemeConstants.TEXT_PRIMARY).width('100%')
                }
                .width('100%').padding(12).backgroundColor(ThemeConstants.BG).borderRadius(8).margin({ bottom: 16 })
              }

              if (this.selectedRecord.photos && this.selectedRecord.photos.length > 0) {
                Column() {
                  Text('照片').fontSize(14).fontColor(ThemeConstants.TEXT_SECONDARY).margin({ bottom: 8 })
                  Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                    ForEach(this.selectedRecord.photos, (photo: string, index: number) => {
                      Image(photo).width(80).height(80).borderRadius(8).objectFit(ImageFit.Cover).margin({ right: 8, bottom: 8 })
                        .onClick(() => {
                          this.previewPhotoIndex = index;
                          this.showPhotoPreview = true;
                        })
                    })
                  }
                }
                .width('100%').margin({ bottom: 16 })
              }

              Row({ space: 12 }) {
                Button('分享')
                  .layoutWeight(1)
                  .height(44).fontSize(15).fontColor(ThemeConstants.PRIMARY)
                  .backgroundColor(ThemeConstants.BG).borderRadius(ThemeConstants.RADIUS_FULL)
                  .onClick(() => { this.showShareCard = true; })
                Button('关闭')
                  .layoutWeight(1)
                  .height(44).fontSize(15).fontColor(ThemeConstants.CARD_BG)
                  .backgroundColor(ThemeConstants.PRIMARY).borderRadius(ThemeConstants.RADIUS_FULL)
                  .onClick(() => { this.showDetailDialog = false; this.selectedRecord = null; })
              }
              .width('100%')
            }
            .width('100%').padding(24)
          }
          .width(this.detailDialogWidth.getValue(this.bp) as string)
          .height(this.detailDialogHeight.getValue(this.bp) as string)
          .backgroundColor(ThemeConstants.CARD_BG)
          .borderRadius(ThemeConstants.RADIUS_MD)
          .border({ width: 1, color: ThemeConstants.BORDER_LIGHT })
          .shadow(ThemeConstants.SHADOW_MODAL)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeConstants.OVERLAY)
        .justifyContent(FlexAlign.Center)
      }

      // 照片全屏预览
      if (this.showPhotoPreview && this.selectedRecord) {
        Stack() {
          Swiper() {
            ForEach(this.selectedRecord.photos, (photo: string) => {
              Image(photo).objectFit(ImageFit.Contain).width('100%').height('100%')
            })
          }
          .index(this.previewPhotoIndex)
          .width('100%').height('100%')
          .indicator(false)
          .loop(false)
          .onChange((index: number) => {
            this.previewPhotoIndex = index;
          })

          // 关闭按钮
          Text('✕').fontSize(24).fontColor('#FFFFFF').width(48).height(48).textAlign(TextAlign.Center)
            .borderRadius(24)
            .backgroundColor('#00000066')
            .onClick(() => { this.showPhotoPreview = false; })
            .position({ x: '90%', y: '5%' })

          // 页码指示
          if (this.selectedRecord.photos.length > 1) {
            Text(`${this.previewPhotoIndex + 1} / ${this.selectedRecord.photos.length}`)
              .fontSize(14).fontColor('#FFFFFF')
              .position({ x: '50%', y: '95%' })
              .translate({ x: '-50%' })
          }
        }
        .width('100%').height('100%').backgroundColor('#000000')
        .onClick(() => { this.showPhotoPreview = false; })
      }

      // 分享卡片弹窗
      if (this.showShareCard && this.selectedRecord) {
        Column() {
          Column() {
            // 卡片内容
            Column({ space: 12 }) {
              Text('🚶 无目的漫步').fontSize(14).fontColor(ThemeConstants.TEXT_SECONDARY)
              Text(this.selectedRecord.date).fontSize(12).fontColor(ThemeConstants.TEXT_MUTED)
              
              Column({ space: 8 }) {
                Text(this.selectedRecord.direction).fontSize(24).fontWeight(FontWeight.Bold).fontColor(ThemeConstants.PRIMARY)
                Text(`${this.selectedRecord.formatDuration()} · 换向${this.selectedRecord.redirectCount}次`).fontSize(14).fontColor(ThemeConstants.TEXT_SECONDARY)
              }
              
              if (this.selectedRecord.feeling) {
                Text(`"${this.selectedRecord.feeling}"`).fontSize(16).fontColor(ThemeConstants.TEXT_PRIMARY).fontStyle(FontStyle.Italic)
                  .textAlign(TextAlign.Center).width('100%')
              }
              
              Text(QuoteConstants.getRandomQuote()).fontSize(12).fontColor(ThemeConstants.TEXT_MUTED)
                .textAlign(TextAlign.Center).width('100%').margin({ top: 8 })
            }
            .width('100%').padding(24)
            .backgroundColor(ThemeConstants.BG)
            .borderRadius(ThemeConstants.RADIUS_MD)
            
            // 按钮
            Row({ space: 12 }) {
              Button('关闭').width('45%').height(40).fontSize(14).fontColor(ThemeConstants.TEXT_SECONDARY)
                .backgroundColor(ThemeConstants.CARD_BG).borderRadius(ThemeConstants.RADIUS_FULL)
                .onClick(() => { this.showShareCard = false; })
              Button('保存到相册').width('45%').height(40).fontSize(14).fontColor('#FFFFFF')
                .backgroundColor(ThemeConstants.PRIMARY).borderRadius(ThemeConstants.RADIUS_FULL)
                .onClick(() => { this.saveShareCard(); })
            }
            .width('100%').margin({ top: 16 })
          }
          .width('80%').padding(24)
          .backgroundColor(ThemeConstants.CARD_BG)
          .borderRadius(ThemeConstants.RADIUS_MD)
          .shadow(ThemeConstants.SHADOW_MODAL)
        }
        .width('100%').height('100%').backgroundColor(ThemeConstants.OVERLAY)
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.showShareCard = false; })
        .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%').height('100%')
  }

  private saveShareCard(): void {
    // TODO: 使用截图API将卡片保存为图片
    Logger.info('保存分享卡片');
    this.showShareCard = false;
  }
}
