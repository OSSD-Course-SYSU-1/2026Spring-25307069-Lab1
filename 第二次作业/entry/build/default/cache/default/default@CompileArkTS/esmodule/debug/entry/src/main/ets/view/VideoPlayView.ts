if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface VideoPlayView_Params {
    viewModel?: VideoPlayViewModel;
    videoSources?: resourceManager.RawFileDescriptor[];
    isFullScreen?: boolean;
}
import hilog from "@ohos:hilog";
import type resourceManager from "@ohos:resourceManager";
import window from "@ohos:window";
import { getShowTime } from "@normalized:N&&&entry/src/main/ets/common/TimeUtils&";
import { PlayerState } from "@normalized:N&&&entry/src/main/ets/model/PlayerStateModel&";
import { CommonConstants as Const } from "@normalized:N&&&entry/src/main/ets/common/CommonConstants&";
import type { VideoPlayViewModel } from '../viewmodel/VideoPlayViewModel';
const DOMAIN = 0xFF00;
const TAG = 'VideoPlayView';
const FULL_SIZE = '100%';
const NORMAL_SIZE = '100%';
const WIDTH_SIZE = '100%';
export class VideoPlayView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__viewModel = new SynchedPropertyNesedObjectPU(params.viewModel, this, "viewModel");
        this.__videoSources = new SynchedPropertyObjectTwoWayPU(params.videoSources, this, "videoSources");
        this.__isFullScreen = new SynchedPropertySimpleTwoWayPU(params.isFullScreen, this, "isFullScreen");
        this.setInitiallyProvidedValue(params);
        this.declareWatch("isFullScreen", this.fullScreenSet);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: VideoPlayView_Params) {
        this.__viewModel.set(params.viewModel);
    }
    updateStateVars(params: VideoPlayView_Params) {
        this.__viewModel.set(params.viewModel);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__viewModel.purgeDependencyOnElmtId(rmElmtId);
        this.__videoSources.purgeDependencyOnElmtId(rmElmtId);
        this.__isFullScreen.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__viewModel.aboutToBeDeleted();
        this.__videoSources.aboutToBeDeleted();
        this.__isFullScreen.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __viewModel: SynchedPropertyNesedObjectPU<VideoPlayViewModel>;
    get viewModel() {
        return this.__viewModel.get();
    }
    private __videoSources: SynchedPropertySimpleOneWayPU<resourceManager.RawFileDescriptor[]>;
    get videoSources() {
        return this.__videoSources.get();
    }
    set videoSources(newValue: resourceManager.RawFileDescriptor[]) {
        this.__videoSources.set(newValue);
    }
    // [Start isFullScreen]
    // The horizontal full-screen playback state flag.
    private __isFullScreen: SynchedPropertySimpleTwoWayPU<boolean>;
    get isFullScreen() {
        return this.__isFullScreen.get();
    }
    set isFullScreen(newValue: boolean) {
        this.__isFullScreen.set(newValue);
    }
    // [End isFullScreen]
    aboutToAppear(): void {
        this.viewModel.videoSources = this.videoSources;
        this.viewModel.setUIContext(this.getUIContext());
        this.viewModel.initialize();
    }
    aboutToDisappear(): void {
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
                hilog.error(DOMAIN, TAG, `Failed to setWindowLayoutFullScreen. Cause: ${error.code}, message: ${error.message}`);
            });
        }).catch((error: BusinessError) => {
            hilog.error(DOMAIN, TAG, `Failed to getLastWindow. Cause: ${error.code}, message: ${error.message}`);
        });
    }
    // [End fullScreenSet]
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.height('100%');
            Column.width('100%');
            Column.backgroundColor(Color.Black);
            Column.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create({ alignContent: Alignment.Center });
            Stack.width('100%');
            Stack.height(this.isFullScreen ? '100%' : '35%');
        }, Stack);
        this.XComponentView.bind(this)();
        this.ControlOverlay.bind(this)();
        this.SpeedListOverlay.bind(this)();
        Stack.pop();
        this.VideoSelectionView.bind(this)();
        this.VideoPlaceholderView.bind(this)();
        Column.pop();
    }
    XComponentView(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // [Start XComponent]
            XComponent.create({
                id: 'playerXC',
                type: XComponentType.SURFACE,
                libraryname: 'player'
            }, "com.example.decodeplaycontrol/entry");
            // [Start XComponent]
            XComponent.width(WIDTH_SIZE);
            // [Start XComponent]
            XComponent.height(this.isFullScreen ? NORMAL_SIZE : FULL_SIZE);
        }, XComponent);
    }
    ControlOverlay(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.justifyContent(FlexAlign.End);
            Column.padding({ left: '16vp', right: '16vp' });
            Column.visibility(this.viewModel.isUse ? Visibility.Visible : Visibility.Hidden);
        }, Column);
        this.FullScreenHeaderView.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.width('100%');
            Blank.height('60%');
        }, Blank);
        Blank.pop();
        this.PlaybackControls.bind(this)();
        Column.pop();
    }
    FullScreenHeaderView(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height('24%');
            Row.justifyContent(FlexAlign.Start);
            Row.padding({ left: '36vp' });
            Row.visibility(this.isFullScreen ? Visibility.Visible : Visibility.Hidden);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777229, "type": 20000, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
            Image.width('40vp');
            Image.height('40vp');
            Image.onClick(() => {
                this.isFullScreen = false;
            });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create({ "id": 16777224, "type": 10003, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
            Text.fontColor(Color.White);
            Text.fontSize('20fp');
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ left: '12vp' });
        }, Text);
        Text.pop();
        Row.pop();
    }
    PlaybackControls(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height('16%');
            Row.padding(this.isFullScreen ? { left: '36vp', right: '36vp' } : 0);
            Row.justifyContent(FlexAlign.SpaceBetween);
            Row.visibility(this.viewModel.isSpeedListVisible ? Visibility.Hidden : Visibility.Visible);
        }, Row);
        this.PlayPauseButton.bind(this)();
        this.TimeSlider.bind(this)();
        this.SpeedButton.bind(this)();
        this.FullScreenButton.bind(this)();
        Row.pop();
    }
    PlayPauseButton(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('25vp');
            Row.height('100%');
            Row.justifyContent(FlexAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create(this.viewModel.playState === PlayerState.PLAYING ? { "id": 16777234, "type": 20000, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" } : { "id": 16777235, "type": 20000, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
            Image.width('25vp');
            Image.height('25vp');
            Image.onClick(() => {
                this.viewModel.playState = this.viewModel.togglePlayPause(this.viewModel.playState);
            });
        }, Image);
        Row.pop();
    }
    TimeSlider(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width(this.isFullScreen ? '90%' : '70%');
            Row.height('100%');
            Row.justifyContent(FlexAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(getShowTime(this.viewModel.currentTime));
            Text.fontColor(Color.White);
            Text.fontSize('12fp');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Slider.create({
                value: this.viewModel.currentTime,
                min: 0,
                max: this.viewModel.durationTime
            });
            Slider.width(this.isFullScreen ? '90%' : '70%');
            Slider.selectedColor('#F67609');
            Slider.trackColor('#464642');
            Slider.enabled(!this.viewModel.isSeek);
            Slider.onChange((value: number, mode: SliderChangeMode) => {
                this.viewModel.onSliderChange(value, mode);
            });
        }, Slider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(getShowTime(this.viewModel.durationTime));
            Text.fontColor(Color.White);
            Text.fontSize('12fp');
        }, Text);
        Text.pop();
        Row.pop();
    }
    SpeedButton(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width(this.isFullScreen ? '5%' : '14%');
            Row.height('100%');
            Row.justifyContent(FlexAlign.Center);
            Row.onClick(() => {
                this.viewModel.toggleSpeedList();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.viewModel.speedText);
            Text.fontColor(Color.White);
            Text.fontSize('14fp');
        }, Text);
        Text.pop();
        Row.pop();
    }
    FullScreenButton(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (!this.isFullScreen) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('8%');
                        Row.height('100%');
                        Row.justifyContent(FlexAlign.Center);
                        Row.onClick(() => {
                            this.isFullScreen = !this.isFullScreen;
                        });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create({ "id": 16777233, "type": 20000, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
                        Image.width('25vp');
                        Image.height('25vp');
                    }, Image);
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    SpeedListOverlay(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height('100%');
            Row.justifyContent(FlexAlign.End);
            Row.visibility(this.viewModel.isSpeedListVisible ? Visibility.Visible : Visibility.Hidden);
            Row.onClick(() => {
                this.viewModel.hideSpeedList();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(this.isFullScreen ? '180vp' : '120vp');
            Column.height('100%');
            Column.padding({ top: '16vp', bottom: '36vp' });
            Column.justifyContent(FlexAlign.End);
            Column.backgroundColor('#08ffffff');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            List.create({ space: 0, initialIndex: 2 });
            List.width('100%');
            List.height('100%');
            List.stackFromEnd(true);
            List.divider({
                strokeWidth: 0.1,
                color: '#EEEEEE',
                endMargin: 16,
                startMargin: 16
            });
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const item = _item;
                {
                    const itemCreation = (elmtId, isInitialRender) => {
                        ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                        ListItem.create(deepRenderFunction, true);
                        if (!isInitialRender) {
                            ListItem.pop();
                        }
                        ViewStackProcessor.StopGetAccessRecording();
                    };
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        ListItem.create(deepRenderFunction, true);
                    };
                    const deepRenderFunction = (elmtId, isInitialRender) => {
                        itemCreation(elmtId, isInitialRender);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.width('100%');
                            Column.height('50vp');
                            Column.justifyContent(FlexAlign.Center);
                            Column.alignItems(HorizontalAlign.Center);
                            Column.onClick(() => {
                                this.viewModel.onSpeedSelected(item, index);
                            });
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(Const.VIDEO_SPEED_TEXT_ARR[index]);
                            Text.fontSize('16fp');
                            Text.fontColor(this.viewModel.chooseSpeed === item ? '#F67609' : '#FFFFFF');
                        }, Text);
                        Text.pop();
                        Column.pop();
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, Const.VIDEO_SPEED_ARR, forEachItemGenFunction, (item: number, index: number) => {
                return 'item: ' + item.toString() + 'index: ' + index.toString();
            }, true, true);
        }, ForEach);
        ForEach.pop();
        List.pop();
        Column.pop();
        Row.pop();
    }
    VideoSelectionView(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('35%');
            Column.linearGradient({
                direction: GradientDirection.Bottom,
                colors: [[0x1b1a1c, 0], [0x000000, 0.5]]
            });
            Column.visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height('25%');
            Row.justifyContent(FlexAlign.Start);
            Row.padding({ left: '20vp', right: '20vp' });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create({ "id": 16777224, "type": 10003, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
            Text.fontSize('24fp');
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Color.White);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height('20%');
            Row.padding({ left: '20vp', right: '20vp' });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create({ "id": 16777223, "type": 10003, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
            Text.fontSize('16fp');
            Text.fontWeight(FontWeight.Regular);
            Text.fontColor(Color.White);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height('30%');
            Row.padding({ left: '20vp', right: '20vp' });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            List.create({ space: '16vp', initialIndex: 0 });
            List.width('100%');
            List.height('100%');
            List.listDirection(Axis.Horizontal);
            List.enabled(this.viewModel.isSwitchEnable);
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const item = _item;
                {
                    const itemCreation = (elmtId, isInitialRender) => {
                        ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                        ListItem.create(deepRenderFunction, true);
                        if (!isInitialRender) {
                            ListItem.pop();
                        }
                        ViewStackProcessor.StopGetAccessRecording();
                    };
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        ListItem.create(deepRenderFunction, true);
                    };
                    const deepRenderFunction = (elmtId, isInitialRender) => {
                        itemCreation(elmtId, isInitialRender);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.width(40);
                            Column.height(40);
                            Column.backgroundColor('#3B3A37');
                            Column.borderRadius({ "id": 125830910, "type": 10002, params: [], "bundleName": "com.example.decodeplaycontrol", "moduleName": "entry" });
                            Column.justifyContent(FlexAlign.Center);
                            Column.alignItems(HorizontalAlign.Center);
                            Column.borderColor(this.viewModel.chooseNumber === index && this.viewModel.isUse ? '#F67609' : '#3B3A37');
                            Column.borderWidth(1);
                            Column.onClick(() => {
                                this.onVideoSelected(index, item);
                            });
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create((index + 1).toString());
                            Text.fontSize('20fp');
                            Text.fontColor(this.viewModel.chooseNumber === index && this.viewModel.isUse ? '#F67609' : '#FFFFFF');
                        }, Text);
                        Text.pop();
                        Column.pop();
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, this.videoSources, forEachItemGenFunction, (item: resourceManager.RawFileDescriptor, index: number) => {
                return 'item: ' + item.toString() + 'index: ' + index.toString();
            }, true, true);
        }, ForEach);
        ForEach.pop();
        List.pop();
        Row.pop();
        Column.pop();
    }
    VideoPlaceholderView(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.width('100%');
            Blank.height('55%');
            Blank.backgroundColor(Color.Black);
            Blank.visibility(this.isFullScreen ? Visibility.Hidden : Visibility.Visible);
        }, Blank);
        Blank.pop();
    }
    private async onVideoSelected(index: number, rawDes: resourceManager.RawFileDescriptor): Promise<void> {
        const newState = await this.viewModel.onVideoSelected(index, rawDes);
        if (newState !== null) {
            this.viewModel.playState = newState;
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
