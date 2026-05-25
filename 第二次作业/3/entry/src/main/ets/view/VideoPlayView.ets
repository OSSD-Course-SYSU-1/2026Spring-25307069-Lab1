/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { window } from '@kit.ArkUI';
import { getShowTime } from '../common/TimeUtils';
import { PlayerState } from '../model/PlayerStateModel';
import { CommonConstants as Const } from '../common/CommonConstants';
import { VideoPlayViewModel, DanmakuItem } from '../viewmodel/VideoPlayViewModel';
import { AmbientLightView } from '../ambientlight/AmbientLightView';
import { AmbientLightControlPanel } from '../ambientlight/AmbientLightControlPanel';
import { ThemeColors } from '../common/ThemeColors';

const DOMAIN = 0xFF00;
const TAG = 'VideoPlayView';
const FULL_SIZE = '100%';
const NORMAL_SIZE = '100%';
const WIDTH_SIZE = '100%';
const ENTER_KEY_TYPE_DONE = 6;

@Component
export struct VideoPlayView {
  @ObjectLink viewModel: VideoPlayViewModel;
  @Link videoSources: resourceManager.RawFileDescriptor[];
  // [Start isFullScreen]
  // The horizontal full-screen playback state flag.
  @Watch('fullScreenSet') @Link isFullScreen: boolean;
  // [End isFullScreen]

  // Shared state for ambient light - enabled state only
  @Provide('ambientLightEnabled') ambientLightEnabled: boolean = false;
  @Consume('themeColors') themeColors: ThemeColors = new ThemeColors(true);
  @Consume('isDarkTheme') isDarkTheme: boolean = true;

  private toggleTheme(): void {
    this.isDarkTheme = !this.isDarkTheme;
    this.themeColors = new ThemeColors(this.isDarkTheme);
  }

  // Gesture state for seek
  private gestureStartX: number = 0;
  private gestureSeekDelta: number = 0;

  // Slider local state
  @State localSliderValue: number = 0;
  private isSliderDragging: boolean = false;
  private sliderSyncTimerId: number = -1;

  aboutToAppear(): void {
    this.viewModel.videoSources = this.videoSources;
    this.viewModel.setUIContext(this.getUIContext());
    this.viewModel.initialize();
    // Start slider sync timer
    this.sliderSyncTimerId = setInterval(() => {
      if (!this.isSliderDragging) {
        this.localSliderValue = this.viewModel.currentTime;
      }
    }, 100);
  }

  aboutToDisappear(): void {
    if (this.sliderSyncTimerId !== -1) {
      clearInterval(this.sliderSyncTimerId);
    }
    this.viewModel.cleanup();
  }

  // [Start fullScreenSet]
  fullScreenSet() {
    // Change window orientation and layout when setting full screen.
    window.getLastWindow(this.getUIContext().getHostContext()).then((topWindow) => {
      topWindow.setPreferredOrientation(this.isFullScreen ?
        window.Orientation.AUTO_ROTATION_LANDSCAPE : window.Orientation.PORTRAIT).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to setPreferredOrientation. Cause: ${error.code}, message: ${error.message}`);
      });
      topWindow.setWindowLayoutFullScreen(this.isFullScreen ? true : false).catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG,
          `Failed to setWindowLayoutFullScreen. Cause: ${error.code}, message: ${error.message}`);
      });
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to getLastWindow. Cause: ${error.code}, message: ${error.message}`);
    });
  }
  // [End fullScreenSet]

  build() {
    Column() {
      // Outer Stack: video + ambient glow (glow extends beyond video edges)
      Stack({ alignContent: Alignment.Center }) {
        this.AmbientLightOverlay()
        Stack({ alignContent: Alignment.Center }) {
          this.XComponentView()
          this.DanmakuOverlay()
          this.ControlOverlay()
          this.SpeedListOverlay()
        }
        .width('100%')
        .height(this.isFullScreen ? '100%' : '100%')
        .clip(true)
        .parallelGesture(
          TapGesture({ count: 1 })
            .onAction(() => {
              if (this.viewModel.isUse) {
                this.viewModel.toggleControls();
              }
            })
        )
        .parallelGesture(
          PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 20 })
            .onActionStart((event: GestureEvent) => {
              this.gestureStartX = event.fingerList[0].localX;
              this.gestureSeekDelta = 0;
            })
            .onActionUpdate((event: GestureEvent) => {
              const deltaX = event.fingerList[0].localX - this.gestureStartX;
              this.gestureSeekDelta = (deltaX / 100) * 30;
            })
            .onActionEnd(() => {
              if (Math.abs(this.gestureSeekDelta) > 0.5) {
                this.viewModel.seekByDelta(this.gestureSeekDelta);
              }
              this.gestureSeekDelta = 0;
            })
        )
      }
      .width('100%')
      .height(this.isFullScreen ? '100%' : '35%')
      .clip(false)

      // Ambient Light Control - placed right below video, before other content
      this.AmbientLightControlRow()

      this.VideoSelectionView()
      this.VideoPlaceholderView()
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  XComponentView() {
    // [Start XComponent]
    XComponent({
      id: 'playerXC',
      type: XComponentType.SURFACE,
      libraryname: 'player'
    })
      .width(WIDTH_SIZE)
      .height(this.isFullScreen ? NORMAL_SIZE : FULL_SIZE)
      .zIndex(0)
    // [End XComponent]
  }

  @Builder
  AmbientLightOverlay() {
    AmbientLightView({
      ambientLightColor: this.viewModel.ambientLightColor,
      isFullScreen: this.isFullScreen
    })
      .width('100%')
      .height(this.isFullScreen ? '100%' : '100%')
      .zIndex(1)
      .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  DanmakuOverlay() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.viewModel.danmakuList, (item: DanmakuItem, idx: number) => {
        Text(item.text)
          .fontSize('16fp')
          .fontColor(item.color)
          .fontWeight(FontWeight.Medium)
          .margin({ top: item.top + '%', left: item.left + '%' })
      }, (item: DanmakuItem, idx: number) => {
        return item.id + '_' + Math.round(item.left);
      })
    }
    .width('100%')
    .height(this.isFullScreen ? '100%' : '35%')
    .visibility(Visibility.Visible)
    .zIndex(2)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  ControlOverlay() {
    Column() {
      this.FullScreenHeaderView()
      Blank()
        .width('100%')
        .height('60%')
      this.PlaybackControls()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .padding({ left: '16vp', right: '16vp' })
    .visibility(this.viewModel.isUse && this.viewModel.controlsVisible ? Visibility.Visible : Visibility.Hidden)
    .zIndex(10)
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => {
          this.viewModel.playState = this.viewModel.togglePlayPause(this.viewModel.playState);
        })
    )
  }

  @Builder
  FullScreenHeaderView() {
    Row() {
      Image($r('app.media.back'))
        .width('40vp')
        .height('40vp')
        .onClick(() => {
          this.isFullScreen = false;
        })

      Text($r('app.string.Video_name'))
        .fontColor(Color.White)
        .fontSize('20fp')
        .fontWeight(FontWeight.Medium)
        .margin({ left: '12vp' })
    }
    .width('100%')
    .height('24%')
    .justifyContent(FlexAlign.Start)
    .padding({ left: '36vp' })
    .visibility(this.isFullScreen ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  PlaybackControls() {
    Row() {
      this.PlayPauseButton()
      this.TimeSlider()
      this.SpeedButton()
      this.FullScreenButton()
    }
    .width('100%')
    .height('16%')
    .padding(this.isFullScreen ? { left: '36vp', right: '36vp' } : 0)
    .justifyContent(FlexAlign.SpaceBetween)
    .visibility(this.viewModel.isSpeedListVisible ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  PlayPauseButton() {
    Row() {
      Image(this.viewModel.playState === PlayerState.PLAYING ?
        $r('app.media.ic_public_pause') : $r('app.media.ic_public_play'))
        .width('25vp')
        .height('25vp')
        .onClick(() => {
          this.viewModel.playState = this.viewModel.togglePlayPause(this.viewModel.playState);
        })
    }
    .width('25vp')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TimeSlider() {
    Row() {
      Text(getShowTime(this.isSliderDragging ? this.localSliderValue : this.viewModel.currentTime))
        .fontColor(Color.White)
        .fontSize('12fp')

      Slider({
        value: this.localSliderValue,
        min: 0,
        max: this.viewModel.durationTime
      })
        .width(this.isFullScreen ? '90%' : '70%')
        .selectedColor('#F67609')
        .trackColor('#464642')
        .enabled(!this.viewModel.isSeek)
        .onChange((value: number) => {
          this.localSliderValue = value;
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.isSliderDragging = true;
          } else if (event.type === TouchType.Up) {
            this.isSliderDragging = false;
            this.viewModel.currentTime = this.localSliderValue;
            this.viewModel.performSeek(this.localSliderValue);
          }
        })

      Text(getShowTime(this.viewModel.durationTime))
        .fontColor(Color.White)
        .fontSize('12fp')
    }
    .width(this.isFullScreen ? '90%' : '70%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SpeedButton() {
    Row() {
      Text(this.viewModel.speedText)
        .fontColor(Color.White)
        .fontSize('14fp')
    }
    .width(this.isFullScreen ? '5%' : '14%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.viewModel.toggleSpeedList();
    })
  }

  @Builder
  FullScreenButton() {
    if (!this.isFullScreen) {
      Row() {
        Image($r('app.media.ic_public_enlarge'))
          .width('25vp')
          .height('25vp')
      }
      .width('8%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.isFullScreen = !this.isFullScreen;
      })
    }
  }

  @Builder
  SpeedListOverlay() {
    Row() {
      Column() {
        List({ space: 0, initialIndex: 2 }) {
          ForEach(Const.VIDEO_SPEED_ARR, (item: number, index: number) => {
            ListItem() {
              Column() {
                Text(Const.VIDEO_SPEED_TEXT_ARR[index])
                  .fontSize('16fp')
                  .fontColor(this.viewModel.chooseSpeed === item ? '#F67609' : '#FFFFFF')
              }
              .width('100%')
              .height('50vp')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
            .onClick(() => {
              this.viewModel.onSpeedSelected(item, index);
            })
          }, (item: number, index: number) => {
            return 'item: ' + item.toString() + 'index: ' + index.toString();
          })
        }
        .width('100%')
        .height('100%')
        .stackFromEnd(true)
        .divider({
          strokeWidth: 0.1,
          color: '#EEEEEE',
          endMargin: 16,
          startMargin: 16
        })
      }
      .width(this.isFullScreen ? '180vp' : '120vp')
      .height('100%')
      .padding({ top: '16vp', bottom: '36vp' })
      .justifyContent(FlexAlign.End)
      .backgroundColor('#CC000000')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .visibility(this.viewModel.isSpeedListVisible ? Visibility.Visible : Visibility.Hidden)
    .zIndex(20)
    .onClick(() => {
      this.viewModel.hideSpeedList();
    })
  }

  @Builder
  VideoSelectionView() {
    Column() {
      Row() {
        Text($r('app.string.Video_name'))
          .fontSize('24fp')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.primaryText)
      }
      .width('100%')
      .height('20%')
      .alignItems(VerticalAlign.Center)

      Row() {
        TextInput({
          placeholder: '请输入弹幕内容',
          text: this.viewModel.danmakuInputText
        })
          .width('160vp')
          .height('40vp')
          .fontSize('14fp')
          .fontColor(this.themeColors.primaryText)
          .placeholderColor(this.themeColors.secondaryText)
          .backgroundColor(this.themeColors.inputBackground)
          .borderRadius('20vp')
          .margin({ right: '8vp' })
          .enterKeyType(ENTER_KEY_TYPE_DONE)
          .onChange((value: string) => {
            this.viewModel.danmakuInputText = value;
          })
          .onSubmit(() => {
            this.viewModel.sendDanmaku();
          })

        Column() {
          Text('A')
            .fontSize('18fp')
            .fontWeight(FontWeight.Bold)
            .fontColor(this.viewModel.selectedDanmakuColor)
        }
          .width('36vp')
          .height('36vp')
          .backgroundColor(this.themeColors.buttonBackground)
          .borderRadius('18vp')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: '8vp' })
          .borderWidth(1)
          .borderColor(this.themeColors.borderColor)
          .onClick(() => {
            this.viewModel.toggleColorPanel();
          })

        Column() {
          Text('发送')
            .fontSize('14fp')
            .fontColor(Color.White)
        }
          .width('62vp')
          .height('40vp')
          .backgroundColor(this.themeColors.accentColor)
          .borderRadius('20vp')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.viewModel.sendDanmaku();
          })
      }
      .width('100%')
      .height('40vp')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .padding({ left: '20vp', right: '20vp' })
      .margin({ top: '8vp' })

      Column() {
        Row({ space: '8vp' }) {
          ForEach(['#FFFFFF', '#000000', '#FF0000', '#FFF200', '#00AEEF', '#2ECC71', '#8A2BE2', '#FFC0CB', '#FF8C00'],
            (color: string, idx: number) => {
              Column() {
              }
                .width('28vp')
                .height('28vp')
                .borderRadius('14vp')
                .backgroundColor(color)
                .onClick(() => {
                  this.viewModel.selectDanmakuColor(color);
                })
            }, (color: string, idx: number) => {
              return 'color' + idx.toString();
            })
        }
      }
        .width('100%')
        .height('48vp')
        .visibility(this.viewModel.isColorPanelVisible ? Visibility.Visible : Visibility.Hidden)
        .backgroundColor(this.themeColors.cardBackground)
        .padding({ left: '20vp', right: '20vp', top: '10vp', bottom: '10vp' })
        .borderRadius('8vp')
        .margin({ top: '8vp' })

      Row() {
        Text($r('app.string.Episodes'))
          .fontSize('16fp')
          .fontWeight(FontWeight.Regular)
          .fontColor(this.themeColors.primaryText)
      }
      .width('100%')
      .height('20%')
      .padding({ left: '20vp', right: '20vp' })

      Row() {
        List({ space: '16vp', initialIndex: 0 }) {
          ForEach(this.videoSources, (item: resourceManager.RawFileDescriptor, index: number) => {
            ListItem() {
              Column() {
                Text((index + 1).toString())
                  .fontSize('20fp')
                  .fontColor(this.viewModel.chooseNumber === index && this.viewModel.isUse ?
                    this.themeColors.accentColor : this.themeColors.primaryText)
              }
              .width(40)
              .height(40)
              .backgroundColor(this.themeColors.buttonBackground)
              .borderRadius($r('sys.float.corner_radius_level5'))
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .borderColor(this.viewModel.chooseNumber === index && this.viewModel.isUse ?
                this.themeColors.accentColor : this.themeColors.borderColor)
              .borderWidth(1)
              .onClick(() => {
                this.onVideoSelected(index, item);
              })
            }
          }, (item: resourceManager.RawFileDescriptor, index: number) => {
            return index.toString();
          })
        }
        .width('100%')
        .height('100%')
        .listDirection(Axis.Horizontal)
        .enabled(this.viewModel.isSwitchEnable)
      }
      .width('100%')
      .height('30%')
      .padding({ left: '20vp', right: '20vp' })
    }
    .width('100%')
    .height('35%')
    .backgroundColor(this.themeColors.pageBackground)
    .visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  VideoPlaceholderView() {
    Blank()
      .width('100%')
      .height('55%')
      .backgroundColor(this.themeColors.pageBackground)
      .visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  AmbientLightControlRow() {
    Row() {
      AmbientLightControlPanel({
        ambientLightColor: this.viewModel.ambientLightColor
      })

      Blank().width('16vp')

      // Previous episode
      Text('◁')
        .fontSize('18fp')
        .fontColor(this.viewModel.chooseNumber <= 0 ? this.themeColors.disabledText : this.themeColors.primaryText)
        .width('28vp')
        .height('28vp')
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.viewModel.chooseNumber > 0 && this.videoSources.length > 0) {
            const prevIndex = this.viewModel.chooseNumber - 1;
            this.onVideoSelected(prevIndex, this.videoSources[prevIndex]);
          }
        })

      Blank().width('6vp')

      // Next episode
      Text('▷')
        .fontSize('18fp')
        .fontColor(this.viewModel.chooseNumber >= this.videoSources.length - 1 ? this.themeColors.disabledText : this.themeColors.primaryText)
        .width('28vp')
        .height('28vp')
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.viewModel.chooseNumber < this.videoSources.length - 1) {
            const nextIndex = this.viewModel.chooseNumber + 1;
            this.onVideoSelected(nextIndex, this.videoSources[nextIndex]);
          }
        })

      // Theme toggle button (right side)
      Row() {
        Text(this.themeColors.isDark ? '🌙' : '☀️')
          .fontSize('20fp')
      }
      .width('36vp')
      .height('36vp')
      .backgroundColor(this.themeColors.buttonBackground)
      .borderRadius('18vp')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.toggleTheme();
      })
    }
    .width('100%')
    .padding({ left: '20vp', right: '20vp', top: '8vp', bottom: '8vp' })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible)
    .backgroundColor(this.themeColors.controlBarBackground)
  }

  private async onVideoSelected(index: number, rawDes: resourceManager.RawFileDescriptor): Promise<void> {
    const newState = await this.viewModel.onVideoSelected(index, rawDes);
    if (newState !== null) {
      this.viewModel.playState = newState;
    }
  }
}