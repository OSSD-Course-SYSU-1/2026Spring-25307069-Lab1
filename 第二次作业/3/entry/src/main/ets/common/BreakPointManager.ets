import { window } from '@kit.ArkUI';
import { BreakPointConstants } from './BreakPointConstants';

export class BreakPointManager {
  private windowObj: window.Window | undefined = undefined;

  /**
   * 初始化断点监听
   * 在 EntryAbility.onWindowStageCreate 中调用
   */
  async init(windowStage: window.WindowStage): Promise<void> {
    try {
      this.windowObj = await windowStage.getMainWindow();
      // 获取初始窗口尺寸并设置断点
      const windowProperties = await this.windowObj.getWindowProperties();
      this.updateBreakPoint(windowProperties.windowRect.width);
      // 监听窗口尺寸变化
      this.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
        this.updateBreakPoint(windowSize.width);
      });
    } catch (error) {
      console.error(`BreakPointManager init failed: ${error.code}, ${error.message}`);
    }
  }

  private updateBreakPoint(windowWidth: number): void {
    let currentBreakpoint: string = BreakPointConstants.SM;
    if (windowWidth >= BreakPointConstants.MD_THRESHOLD) {
      currentBreakpoint = BreakPointConstants.LG;
    } else if (windowWidth >= BreakPointConstants.SM_THRESHOLD) {
      currentBreakpoint = BreakPointConstants.MD;
    }
    AppStorage.setOrCreate(BreakPointConstants.BREAK_POINT_KEY, currentBreakpoint);
  }

  /**
   * 释放监听
   */
  release(): void {
    if (this.windowObj) {
      this.windowObj.off('windowSizeChange');
    }
  }
}
