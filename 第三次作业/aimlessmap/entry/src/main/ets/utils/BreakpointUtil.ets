import { window } from '@kit.ArkUI';
import { BreakpointConstants, getBreakpointByWidth } from '../constants/BreakpointConstants';
import { Logger } from './Logger';

/**
 * 断点管理工具类（单例模式）
 * 负责监听窗口尺寸变化并同步断点状态到 AppStorage
 */
export class BreakpointUtil {
  private static instance: BreakpointUtil;
  private mainWindow?: window.Window;

  private constructor() {}

  static getInstance(): BreakpointUtil {
    if (!BreakpointUtil.instance) {
      BreakpointUtil.instance = new BreakpointUtil();
    }
    return BreakpointUtil.instance;
  }

  /**
   * 初始化断点监听
   * @param windowStage 窗口舞台实例
   */
  async init(windowStage: window.WindowStage): Promise<void> {
    try {
      this.mainWindow = windowStage.getMainWindowSync();
      const rect = this.mainWindow.getWindowProperties().windowRect;
      const width = rect.width;
      const bp = getBreakpointByWidth(width);

      // 初始化 AppStorage
      AppStorage.setOrCreate(BreakpointConstants.BREAKPOINT_KEY, bp);
      AppStorage.setOrCreate(BreakpointConstants.WINDOW_WIDTH_KEY, width);
      Logger.info(`BreakpointUtil 初始化: width=${width}, bp=${bp}`);

      // 监听窗口尺寸变化
      this.mainWindow.on('windowSizeChange', (data: window.Size) => {
        const newBp = getBreakpointByWidth(data.width);
        const currentBp = AppStorage.get<string>(BreakpointConstants.BREAKPOINT_KEY);
        if (currentBp !== newBp) {
          AppStorage.setOrCreate(BreakpointConstants.BREAKPOINT_KEY, newBp);
          Logger.info(`断点变化: ${currentBp} -> ${newBp}, width=${data.width}`);
        }
        AppStorage.setOrCreate(BreakpointConstants.WINDOW_WIDTH_KEY, data.width);
      });
    } catch (e) {
      Logger.error(`BreakpointUtil 初始化失败: ${JSON.stringify(e)}`);
      // 默认设置为 sm
      AppStorage.setOrCreate(BreakpointConstants.BREAKPOINT_KEY, BreakpointConstants.BREAKPOINT_SM_NAME);
      AppStorage.setOrCreate(BreakpointConstants.WINDOW_WIDTH_KEY, 400);
    }
  }

  /**
   * 获取当前断点
   */
  getCurrentBreakpoint(): string {
    return AppStorage.get<string>(BreakpointConstants.BREAKPOINT_KEY) ?? BreakpointConstants.BREAKPOINT_SM_NAME;
  }

  /**
   * 获取当前窗口宽度
   */
  getWindowWidth(): number {
    return AppStorage.get<number>(BreakpointConstants.WINDOW_WIDTH_KEY) ?? 400;
  }

  /**
   * 判断当前是否为大屏（md 或 lg）
   */
  isLargeScreen(): boolean {
    const bp = this.getCurrentBreakpoint();
    return bp === BreakpointConstants.BREAKPOINT_MD_NAME || bp === BreakpointConstants.BREAKPOINT_LG_NAME;
  }

  /**
   * 判断当前是否为平板/大屏（lg）
   */
  isExtraLargeScreen(): boolean {
    return this.getCurrentBreakpoint() === BreakpointConstants.BREAKPOINT_LG_NAME;
  }
}

export const breakpointUtil = BreakpointUtil.getInstance();
