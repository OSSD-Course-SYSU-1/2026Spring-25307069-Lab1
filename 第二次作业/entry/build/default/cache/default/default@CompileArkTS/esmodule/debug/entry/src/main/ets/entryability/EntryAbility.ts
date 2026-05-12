import type AbilityConstant from "@ohos:app.ability.AbilityConstant";
import ConfigurationConstant from "@ohos:app.ability.ConfigurationConstant";
import UIAbility from "@ohos:app.ability.UIAbility";
import type Want from "@ohos:app.ability.Want";
import hilog from "@ohos:hilog";
import window from "@ohos:window";
const DOMAIN = 0x0000;
const TAG = 'ENTRY';
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        try {
            this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
            hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
        }
        catch (error) {
            hilog.error(0x0000, TAG, `onCreate catch error, code: ${error.code}, message: ${error.message}`);
            return;
        }
    }
    onDestroy(): void {
        hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
                return;
            }
            hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
        });
        try {
            windowStage.on('windowStageEvent', (data) => {
                if (data === window.WindowStageEventType.RESUMED) {
                    this.context.eventHub.emit('onForeground');
                }
                else if (data === window.WindowStageEventType.PAUSED) {
                    this.context.eventHub.emit('onBackground');
                }
                else {
                    hilog.info(DOMAIN, TAG, 'The window stage is not paused or resume');
                }
            });
        }
        catch (error) {
            hilog.error(0x0000, TAG, `windowStageEvent catch error, code: ${error.code}, message: ${error.message}`);
            return;
        }
    }
    onWindowStageDestroy(): void {
        // Main window is destroyed, release UI related resources
        hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
    }
    onForeground(): void {
        // Ability has brought to foreground
        hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
    }
    onBackground(): void {
        // Ability has back to background
        hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
    }
}
