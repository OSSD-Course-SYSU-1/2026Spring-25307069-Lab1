if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
import window from "@ohos:window";
import { Settings } from "@normalized:N&&&entry/src/main/ets/model/Settings&";
import { Speaker } from "@normalized:N&&&entry/src/main/ets/utils/Speaker&";
export class Led extends ViewV2 {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda, extraInfo) {
        super(parent, elmtId, extraInfo);
        this.settings = new Settings('', 88, FontWeight.Regular);
        this.speaker = new Speaker();
        this.finalizeConstruction();
    }
    public resetStateVarsOnReuse(params: Object): void {
        this.settings = new Settings('', 88, FontWeight.Regular);
    }
    @Local
    settings: Settings;
    speaker: Speaker;
    aboutToDisappear(): void {
        this.speaker.stopSpeak();
        this.speaker.shutdownEngine();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            NavDestination.create(() => {
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.width('100%');
                    Column.height('100%');
                    Column.justifyContent(FlexAlign.Center);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(this.settings.content);
                    Text.textOverflow({ overflow: TextOverflow.MARQUEE });
                    Text.marqueeOptions({
                        start: true // 开启滚动功能
                    });
                    Text.fontSize(this.settings.fontSize);
                    Text.fontWeight(this.settings.fontWeight);
                    Text.fontColor('#FFFFFF');
                }, Text);
                Text.pop();
                Column.pop();
            }, { moduleName: "entry", pagePath: "entry/src/main/ets/pages/Led" });
            NavDestination.onReady((context: NavDestinationContext) => {
                this.settings = context.pathInfo.param as Settings;
            });
            NavDestination.width('100%');
            NavDestination.height('100%');
            NavDestination.menus([{
                    value: '',
                    icon: { "id": 16777226, "type": 20000, params: [], "bundleName": "com.example.led", "moduleName": "entry" },
                    action: () => {
                        this.speaker.startSpeak(this.settings.content);
                    } // 选项被选中后触发
                }]);
            NavDestination.backButtonIcon({ "id": 16777225, "type": 20000, params: [], "bundleName": "com.example.led", "moduleName": "entry" });
            NavDestination.preferredOrientation(window.Orientation.LANDSCAPE);
            NavDestination.linearGradient({
                direction: GradientDirection.Right,
                colors: [
                    ['#013C9C', 0.0],
                    ['#3066E4', 0.5],
                    ['#43A1F4', 1.0]
                ]
            });
        }, NavDestination);
        NavDestination.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
// 构建页面函数，配置在route_map.json5文件中，需要跳转至本页面时自动调用
export function LedBuilder(parent = null) {
    {
        (parent ? parent : this).observeComponentCreation2((elmtId, isInitialRender) => {
            if (isInitialRender) {
                let componentCall = new Led(parent ? parent : this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Led.ets", line: 74, col: 3 });
                ViewV2.create(componentCall);
                let paramsLambda = () => {
                    return {};
                };
                componentCall.paramsGenerator_ = paramsLambda;
            }
            else {
                (parent ? parent : this).updateStateVarsOfChildByElmtId(elmtId, {});
            }
        }, { name: "Led" });
    }
}
(function () {
    if (typeof NavigationBuilderRegister === "function") {
        NavigationBuilderRegister("Led", wrapBuilder(LedBuilder));
    }
})();
