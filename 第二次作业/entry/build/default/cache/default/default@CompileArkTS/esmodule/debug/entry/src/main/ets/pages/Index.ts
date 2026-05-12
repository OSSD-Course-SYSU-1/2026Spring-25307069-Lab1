if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Index_Params {
    videoResources?: resourceManager.RawFileDescriptor[];
    viewModel?: VideoPlayViewModel;
    isFullScreen?: boolean;
}
import type resourceManager from "@ohos:resourceManager";
import hilog from "@ohos:hilog";
import { VideoPlayView } from "@normalized:N&&&entry/src/main/ets/view/VideoPlayView&";
import { VideoPlayViewModel } from "@normalized:N&&&entry/src/main/ets/viewmodel/VideoPlayViewModel&";
const VIDEO_NAMES = ['1.mp4', '2.mp4', '3.mp4'];
const TAG = 'INDEX';
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__videoResources = new ObservedPropertyObjectPU([], this, "videoResources");
        this.__viewModel = new ObservedPropertyObjectPU(new VideoPlayViewModel(), this, "viewModel");
        this.__isFullScreen = new ObservedPropertySimplePU(false, this, "isFullScreen");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
        if (params.videoResources !== undefined) {
            this.videoResources = params.videoResources;
        }
        if (params.viewModel !== undefined) {
            this.viewModel = params.viewModel;
        }
        if (params.isFullScreen !== undefined) {
            this.isFullScreen = params.isFullScreen;
        }
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__videoResources.purgeDependencyOnElmtId(rmElmtId);
        this.__viewModel.purgeDependencyOnElmtId(rmElmtId);
        this.__isFullScreen.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__videoResources.aboutToBeDeleted();
        this.__viewModel.aboutToBeDeleted();
        this.__isFullScreen.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __videoResources: ObservedPropertyObjectPU<resourceManager.RawFileDescriptor[]>;
    get videoResources() {
        return this.__videoResources.get();
    }
    set videoResources(newValue: resourceManager.RawFileDescriptor[]) {
        this.__videoResources.set(newValue);
    }
    private __viewModel: ObservedPropertyObjectPU<VideoPlayViewModel>;
    get viewModel() {
        return this.__viewModel.get();
    }
    set viewModel(newValue: VideoPlayViewModel) {
        this.__viewModel.set(newValue);
    }
    private __isFullScreen: ObservedPropertySimplePU<boolean>;
    get isFullScreen() {
        return this.__isFullScreen.get();
    }
    set isFullScreen(newValue: boolean) {
        this.__isFullScreen.set(newValue);
    }
    aboutToAppear(): void {
        try {
            this.videoResources.length = 0;
            for (let i = 0; i < VIDEO_NAMES.length; i++) {
                let rawDes = this.getUIContext().getHostContext()?.resourceManager.getRawFdSync(VIDEO_NAMES[i]);
                if (rawDes) {
                    this.videoResources.push(rawDes);
                }
            }
        }
        catch (error) {
            hilog.error(0x0000, TAG, `aboutToAppear catch error, code: ${error.code}, message: ${error.message}`);
        }
    }
    aboutToDisappear(): void {
        try {
            for (let i = 0; i < VIDEO_NAMES.length; i++) {
                this.getUIContext().getHostContext()?.resourceManager.closeRawFdSync(VIDEO_NAMES[i]);
            }
        }
        catch (error) {
            hilog.error(0x0000, TAG, `aboutToDisappear catch error, code: ${error.code}, message: ${error.message}`);
        }
    }
    onBackPress(): boolean | void {
        if (this.isFullScreen) {
            this.isFullScreen = false;
            return true;
        }
        return false;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new VideoPlayView(this, {
                        viewModel: this.viewModel,
                        videoSources: this.__videoResources,
                        isFullScreen: this.__isFullScreen
                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 65, col: 7 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            viewModel: this.viewModel,
                            videoSources: this.videoResources,
                            isFullScreen: this.isFullScreen
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        viewModel: this.viewModel
                    });
                }
            }, { name: "VideoPlayView" });
        }
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.example.decodeplaycontrol", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
