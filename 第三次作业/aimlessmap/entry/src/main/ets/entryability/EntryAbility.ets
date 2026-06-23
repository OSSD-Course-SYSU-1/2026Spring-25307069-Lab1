import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { preferencesUtil } from '../utils/PreferencesUtil';
import { breakpointUtil } from '../utils/BreakpointUtil';
import { ContinueService } from '../service/ContinueService';
import { Logger } from '../utils/Logger';

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    Logger.info('Application onCreate');
    await preferencesUtil.init(this.context);

    // 检查是否为流转恢复
    await this.handleContinueState(want);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    Logger.info('onWindowStageCreate');

    // 初始化断点监听
    await breakpointUtil.init(windowStage);

    await windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) { Logger.error(`加载失败: ${JSON.stringify(err)}`); return; }
      Logger.info('加载成功');
    });
  }

  /**
   * 自由流转：保存状态到目标设备
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    Logger.info('onContinue: 准备保存流转状态');
    const state = ContinueService.getCurrentState();
    if (state) {
      wantParam['continueState'] = JSON.stringify(state);
      Logger.info(`onContinue: 状态已保存，目标页面=${state.page}`);
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  /**
   * 处理流转恢复状态
   */
  private async handleContinueState(want: Want): Promise<void> {
    const params = want.parameters as Record<string, Object> | undefined;
    if (!params) return;
    const continueStateStr = params['continueState'] as string;
    if (continueStateStr) {
      try {
        const state = JSON.parse(continueStateStr) as import('../service/ContinueService').ContinueState;
        Logger.info(`handleContinueState: 恢复页面=${state.page}`);
        ContinueService.setRestoreState(state);
      } catch (e) {
        Logger.error(`解析流转状态失败: ${JSON.stringify(e)}`);
      }
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info('onNewWant');
    this.handleContinueState(want);
  }

  onForeground(): void { Logger.info('onForeground'); }
  onBackground(): void { Logger.info('onBackground'); }
  onDestroy(): void {
    Logger.info('onDestroy');
    ContinueService.clearState();
  }
}
