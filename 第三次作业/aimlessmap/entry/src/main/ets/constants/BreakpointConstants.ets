/**
 * 断点常量定义
 * 用于多端部署时根据窗口宽度切换布局
 */

export class BreakpointConstants {
  // 断点边界值（单位：vp）
  static readonly BREAKPOINT_XS = 320;   // 智能手表
  static readonly BREAKPOINT_SM = 600;   // 手机竖屏
  static readonly BREAKPOINT_MD = 840;   // 手机横屏/小折叠
  // lg: 840+ 平板/大折叠

  // 断点名称
  static readonly BREAKPOINT_XS_NAME = 'xs';
  static readonly BREAKPOINT_SM_NAME = 'sm';
  static readonly BREAKPOINT_MD_NAME = 'md';
  static readonly BREAKPOINT_LG_NAME = 'lg';

  // AppStorage 中存储断点状态的 key
  static readonly BREAKPOINT_KEY = 'currentBreakpoint';

  // 窗口宽度 key
  static readonly WINDOW_WIDTH_KEY = 'windowWidth';
}

/**
 * BreakpointType 构造函数选项接口
 */
export interface BreakpointTypeOptions<T> {
  xs?: T;
  sm?: T;
  md?: T;
  lg?: T;
}

/**
 * 断点类型工具类
 * 根据当前断点返回对应的值
 */
export class BreakpointType<T> {
  private xs?: T;
  private sm?: T;
  private md?: T;
  private lg?: T;

  constructor(options: BreakpointTypeOptions<T>) {
    this.xs = options.xs;
    this.sm = options.sm;
    this.md = options.md;
    this.lg = options.lg;
  }

  /**
   * 根据断点名称获取对应值
   * 优先级：精确匹配 > sm 默认值
   */
  getValue(bp: string): T {
    switch (bp) {
      case BreakpointConstants.BREAKPOINT_XS_NAME:
        return this.xs ?? this.sm!;
      case BreakpointConstants.BREAKPOINT_SM_NAME:
        return this.sm!;
      case BreakpointConstants.BREAKPOINT_MD_NAME:
        return this.md ?? this.sm!;
      case BreakpointConstants.BREAKPOINT_LG_NAME:
        return this.lg ?? this.md ?? this.sm!;
      default:
        return this.sm!;
    }
  }
}

/**
 * 根据窗口宽度获取断点名称
 */
export function getBreakpointByWidth(width: number): string {
  if (width < BreakpointConstants.BREAKPOINT_XS) {
    return BreakpointConstants.BREAKPOINT_XS_NAME;
  } else if (width < BreakpointConstants.BREAKPOINT_SM) {
    return BreakpointConstants.BREAKPOINT_SM_NAME;
  } else if (width < BreakpointConstants.BREAKPOINT_MD) {
    return BreakpointConstants.BREAKPOINT_MD_NAME;
  } else {
    return BreakpointConstants.BREAKPOINT_LG_NAME;
  }
}
