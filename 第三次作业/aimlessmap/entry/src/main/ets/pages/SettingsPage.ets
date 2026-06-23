import { router } from '@kit.ArkUI';
import picker from '@ohos.file.picker';
import { AppConstants } from '../constants/AppConstants';
import { BreakpointConstants, BreakpointType } from '../constants/BreakpointConstants';
import { Logger } from '../utils/Logger';
import { preferencesUtil, StoreKeys } from '../utils/PreferencesUtil';

@Entry
@Component
struct SettingsPage {
  @StorageProp(BreakpointConstants.BREAKPOINT_KEY) bp: string = BreakpointConstants.BREAKPOINT_SM_NAME;

  // 响应式配置
  private pagePadding = new BreakpointType({ sm: 0, md: 24, lg: 48 });
  private cardMaxWidth = new BreakpointType({ sm: '100%', md: '90%', lg: '80%' });
  private contentPadding = new BreakpointType({ sm: 0, md: 32, lg: 48 });
  @State soundEnabled: boolean = false;
  @State soundType: string = '无';
  @State customAudioName: string = '';

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    this.soundEnabled = await preferencesUtil.get(StoreKeys.SOUND_ENABLED, false) as boolean;
    this.soundType = await preferencesUtil.get(StoreKeys.SOUND_TYPE, '无') as string;
    this.customAudioName = await preferencesUtil.get(StoreKeys.CUSTOM_AUDIO_NAME, '') as string;
  }

  private async selectCustomAudio(): Promise<void> {
    try {
      const audioSelectOptions = new picker.AudioSelectOptions();
      const audioPicker = new picker.AudioViewPicker();
      const result: string[] = await audioPicker.select(audioSelectOptions) as string[];
      if (result && result.length > 0) {
        const uri: string = result[0];
        const parts: string[] = uri.split('/');
        const fileName: string = parts[parts.length - 1] ?? '自定义音频';
        this.soundType = '自定义';
        this.customAudioName = fileName;
        await preferencesUtil.put(StoreKeys.SOUND_TYPE, '自定义');
        await preferencesUtil.put(StoreKeys.CUSTOM_AUDIO_URI, uri);
        await preferencesUtil.put(StoreKeys.CUSTOM_AUDIO_NAME, fileName);
        Logger.info(`选择自定义音频: ${fileName}`);
      }
    } catch (e) {
      Logger.error(`选择音频失败: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(28).fontColor('#1A1A2E').width(44).height(44).textAlign(TextAlign.Center)
          .borderRadius(22)
          .stateStyles({
            pressed: {
              .backgroundColor('#F0F0F0')
            }
          })
          .onClick(() => { router.back(); })
        Text('设置')
          .fontSize(new BreakpointType({ sm: 20, md: 22, lg: 24 }).getValue(this.bp))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('').width(44)
      }
      .width('100%')
      .padding({
        left: new BreakpointType({ sm: 16, md: 16, lg: 24 }).getValue(this.bp),
        right: new BreakpointType({ sm: 16, md: 16, lg: 24 }).getValue(this.bp),
        top: 16,
        bottom: 16
      })

      Scroll() {
        Column({ space: new BreakpointType({ sm: 16, md: 20, lg: 24 }).getValue(this.bp) }) {
          // 音效设置
          Text('音效设置')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .padding({ left: 16 })
          Column() {
            Row() {
              Text('白噪音')
                .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                .fontColor('#333333')
                .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.soundEnabled })
                .onChange(async (isOn: boolean) => {
                  this.soundEnabled = isOn;
                  await preferencesUtil.put(StoreKeys.SOUND_ENABLED, isOn);
                })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            if (this.soundEnabled) {
              Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
              // 预设音效
              Column({ space: 10 }) {
                Text('音效类型')
                  .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                  .fontColor('#333333')
                  .width('100%')
                Row({ space: 6 }) {
                  ForEach(AppConstants.SOUND_TYPES, (type: string) => {
                    Text(type)
                      .fontSize(12)
                      .fontColor(this.soundType === type ? '#FFFFFF' : '#4A6FA5')
                      .backgroundColor(this.soundType === type ? '#4A6FA5' : '#E8EDF5')
                      .borderRadius(12)
                      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
                      .onClick(async () => {
                        this.soundType = type;
                        await preferencesUtil.put(StoreKeys.SOUND_TYPE, type);
                      })
                  })
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })

              // 自定义音频
              Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
              Row() {
                Column() {
                  Text('自定义音频')
                    .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                    .fontColor('#333333')
                  if (this.customAudioName) {
                    Text(this.customAudioName)
                      .fontSize(12)
                      .fontColor('#4A6FA5')
                      .margin({ top: 4 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .constraintSize({ maxWidth: 200 })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Text('选择文件')
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#FF9800')
                  .borderRadius(16)
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .onClick(() => this.selectCustomAudio())
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })
              .alignItems(VerticalAlign.Center)
            }
          }
          .width('100%')
          .margin({ left: 0, right: 0 })
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 16, md: 18, lg: 20 }).getValue(this.bp))

          // 关于
          Text('关于')
            .fontSize(14)
            .fontColor('#999999')
            .width('100%')
            .padding({ left: 16 })
            .margin({ top: 8 })
          Column() {
            Row() {
              Text('应用名称')
                .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                .fontColor('#333333')
                .layoutWeight(1);
              Text(AppConstants.APP_NAME).fontSize(14).fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
            Row() {
              Text('版本')
                .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                .fontColor('#333333')
                .layoutWeight(1);
              Text('v1.0.0').fontSize(14).fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            Divider().color('#F0F0F0').margin({ left: 20, right: 20 })
            Row() {
              Text('包名')
                .fontSize(new BreakpointType({ sm: 16, md: 17, lg: 18 }).getValue(this.bp))
                .fontColor('#333333')
                .layoutWeight(1);
              Text('com.kangpk.aimlessmap').fontSize(12).fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          }
          .width('100%')
          .margin({ left: 0, right: 0, bottom: 32 })
          .backgroundColor('#FFFFFF')
          .borderRadius(new BreakpointType({ sm: 16, md: 18, lg: 20 }).getValue(this.bp))
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: this.pagePadding.getValue(this.bp), right: this.pagePadding.getValue(this.bp) })
    .backgroundColor('#F5F7FA')
  }
}
