import textToSpeech from "@hms:ai.textToSpeech";
import type { BusinessError } from "@ohos:base";
import hilog from "@ohos:hilog";
const TAG = 'Speaker';
export class Speaker {
    // 定义引擎参数
    initParamsInfo: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        online: 1,
        person: 13 // 聆小珊女声音色
    };
    // 定义引擎实例
    ttsEngine?: textToSpeech.TextToSpeechEngine;
    // 构造函数，创建引擎实例
    constructor() {
        // 调用创建引擎方法
        textToSpeech.createEngine(this.initParamsInfo, // 传入引擎参数
        (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
            // 判断是否出现异常
            if (!err) {
                // 无异常，赋值
                this.ttsEngine = textToSpeechEngine;
            }
            else {
                // 有异常，输出日志
                hilog.error(0x0000, TAG, `createEngine failed, error code: ${err.code}, message: ${err.message}.`);
            }
        });
    }
    // 播报函数，定义播报音频流参数，并调用speak方法进行播报
    startSpeak(content: string) {
        let speakParams: textToSpeech.SpeakParams = {
            // requestId用于区分不同的请求，故在同一个实例内只能使用一次，不允许重复
            requestId: Date.now().toString()
        };
        try {
            this.ttsEngine?.speak(content, speakParams); // 传入待播报文本和参数
        }
        catch (error) {
            this.ttsEngine?.stop();
            hilog.error(0x0000, TAG, `speak failed, error code: ${error.code}, message: ${error.message}.`);
        }
    }
    // 停止合成与播报
    stopSpeak() {
        this.ttsEngine?.stop();
    }
    // 关闭引擎，释放引擎资源
    shutdownEngine() {
        this.ttsEngine?.shutdown();
    }
}
