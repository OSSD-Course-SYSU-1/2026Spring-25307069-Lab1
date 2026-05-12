if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
import { Settings } from "@normalized:N&&&entry/src/main/ets/model/Settings&";
class Index extends ViewV2 {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda, extraInfo) {
        super(parent, elmtId, extraInfo);
        this.content = '欢迎学习鸿蒙开发';
        this.fontSize = 88;
        this.fontSizeFlag = '小';
        this.fontWeight = FontWeight.Regular;
        this.selectedIndex = 0;
        this.fontWeights = [FontWeight.Regular, FontWeight.Medium, FontWeight.Bold];
        this.pathInfos = new NavPathStack();
        this.finalizeConstruction();
    }
    public resetStateVarsOnReuse(params: Object): void {
        this.content = '欢迎学习鸿蒙开发';
        this.fontSize = 88;
        this.fontSizeFlag = '小';
        this.fontWeight = FontWeight.Regular;
        this.selectedIndex = 0;
    }
    // 1. 弹幕内容（字符串类型，默认文字）
    @Local
    content: string;
    // 2. 字号（数字类型，默认88）
    @Local
    fontSize: number;
    // 字号标识（小/中/大，同步显示给用户）
    @Local
    fontSizeFlag: string;
    // 3. 字体粗细（枚举类型，默认常规）
    @Local
    fontWeight: FontWeight;
    // 字体粗细选中项
    @Local
    selectedIndex: number;
    // 字体粗细数组（常规、中等、加粗）
    fontWeights: FontWeight[];
    // 导航控制器
    pathInfos: NavPathStack;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Navigation.create(this.pathInfos, { moduleName: "entry", pagePath: "entry/src/main/ets/pages/Index", isUserCreateStack: true });
            Navigation.mode(NavigationMode.Stack);
            Navigation.hideToolBar(true);
        }, Navigation);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.background('#F1F3F5');
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 1. 标题区
            Text.create('手持弹幕');
            // 1. 标题区
            Text.fontSize(26);
            // 1. 标题区
            Text.fontColor('#000000');
            // 1. 标题区
            Text.fontWeight(FontWeight.Bold);
            // 1. 标题区
            Text.margin({ left: 16 });
            // 1. 标题区
            Text.height(56);
        }, Text);
        // 1. 标题区
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 2. 预览区
            Column.create();
            // 2. 预览区
            Column.width('100%');
            // 2. 预览区
            Column.margin({ top: 28 });
            // 2. 预览区
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('预览');
            Text.fontSize(14);
            Text.fontColor('#99000000');
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ left: 28 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 弹幕展示框
            Column.create();
            // 弹幕展示框
            Column.width('100%');
            // 弹幕展示框
            Column.height(199);
            // 弹幕展示框
            Column.backgroundColor('#E5E5EA');
            // 弹幕展示框
            Column.padding({
                top: 24,
                right: 16,
                bottom: 24,
                left: 16
            });
            // 弹幕展示框
            Column.margin({ top: 8 });
            // 弹幕展示框
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 弹幕滚动区域
            Row.create();
            // 弹幕滚动区域
            Row.width('100%');
            // 弹幕滚动区域
            Row.height('100%');
            // 弹幕滚动区域
            Row.linearGradient({
                direction: GradientDirection.Right,
                colors: [
                    ['#013C9C', 0.0],
                    ['#3066E4', 0.5],
                    ['#43A1F4', 1.0]
                ]
            });
            // 弹幕滚动区域
            Row.borderRadius(16);
            // 弹幕滚动区域
            Row.justifyContent(FlexAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.content);
            Text.textOverflow({ overflow: TextOverflow.MARQUEE });
            Text.marqueeOptions({
                start: true // 关键：是否启动滚动。true：启动滚动；false：停止滚动
            });
            Text.fontSize(this.fontSize / 1.8);
            Text.fontWeight(this.fontWeight);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        // 弹幕滚动区域
        Row.pop();
        // 弹幕展示框
        Column.pop();
        // 2. 预览区
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 3. 操作区
            Column.create();
            // 3. 操作区
            Column.padding({
                left: 16,
                right: 16
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 弹幕内容区
            Column.create();
            // 弹幕内容区
            Column.width('100%');
            // 弹幕内容区
            Column.alignItems(HorizontalAlign.Start);
            // 弹幕内容区
            Column.margin({
                top: 28,
                bottom: 28
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('弹幕内容');
            Text.fontSize(14);
            Text.fontColor('#99000000');
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 输入框
            TextArea.create({ text: this.content });
            // 输入框
            TextArea.backgroundColor(Color.White);
            // 输入框
            TextArea.maxLength(50);
            // 输入框
            TextArea.showCounter(true, // 开启统计
            {
                thresholdPercentage: 1,
                highlightBorder: true // 输入快满时，边框会高亮提醒
            });
            // 输入框
            TextArea.height(72);
            // 输入框
            TextArea.padding({
                top: 8,
                right: 16,
                bottom: 8,
                left: 16
            });
            // 输入框
            TextArea.margin({ top: 8 });
            // 输入框
            TextArea.borderRadius(16);
            // 输入框
            TextArea.onChange((value: string) => {
                this.content = value; // 将当前值赋值给content
            });
        }, TextArea);
        // 弹幕内容区
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 设置区
            Column.create();
            // 设置区
            Column.width('100%');
            // 设置区
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标题
            Text.create('显示设置');
            // 标题
            Text.fontSize(14);
            // 标题
            Text.fontColor('#99000000');
            // 标题
            Text.fontWeight(FontWeight.Medium);
            // 标题
            Text.margin({
                bottom: 8,
                left: 12
            });
        }, Text);
        // 标题
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 4
            });
            Column.margin({ bottom: 12 });
            Column.backgroundColor(Color.White);
            Column.borderRadius(16);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 字号大小区
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height(48);
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('字体大小');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.fontSizeFlag);
            Text.fontSize(14);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Slider.create({
                value: this.fontSize,
                min: 88,
                max: 248,
                step: 80,
                style: SliderStyle.InSet
            });
            Slider.width('calc(100% + 12vp)');
            Slider.height(40);
            Slider.blockColor(Color.White);
            Slider.trackColor('#F1F3F5');
            Slider.selectedColor('#0A59F7');
            Slider.showSteps(true);
            Slider.onChange((value: number) => {
                this.fontSize = value;
                // 根据当前fontSize匹配fontSizeFlag
                if (this.fontSize === 88) {
                    this.fontSizeFlag = '小';
                }
                else if (this.fontSize === 248) {
                    this.fontSizeFlag = '大';
                }
                else {
                    this.fontSizeFlag = '中';
                }
            });
        }, Slider);
        // 字号大小区
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 字体粗细区
            Row.create();
            // 字体粗细区
            Row.width('100%');
            // 字体粗细区
            Row.height(48);
            // 字体粗细区
            Row.margin({ top: 12 });
            // 字体粗细区
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('字体粗细');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Select.create([
                { value: this.fontWeights[0].toString() },
                { value: this.fontWeights[1].toString() },
                { value: this.fontWeights[2].toString() }
            ]);
            Select.value(this.fontWeight.toString());
            Select.selected(this.selectedIndex);
            Select.backgroundColor('#FFFFFF');
            Select.fontColor('#99000000');
            Select.borderWidth(0);
            Select.onSelect((index: number) => {
                this.fontWeight = this.fontWeights[index]; // 将选中项赋值给fontWeight
                this.selectedIndex = index; // 将选中项的索引赋值给selectedIndex
            });
        }, Select);
        Select.pop();
        // 字体粗细区
        Row.pop();
        Column.pop();
        // 设置区
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('显示弹幕');
            Button.height(40);
            Button.backgroundColor('#0A59F7');
            Button.margin({ top: 32 });
            Button.width('100%');
            Button.onClick(() => {
                // 1. 把当前页面的设置项组装成Settings对象
                const settings = new Settings(this.content, this.fontSize, this.fontWeight);
                // 2. 跳转：第一个参数是路由表的name，第二个是传递的参数
                this.pathInfos.pushPathByName('Led', settings);
            });
        }, Button);
        Button.pop();
        // 3. 操作区
        Column.pop();
        Column.pop();
        Navigation.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.example.led", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
