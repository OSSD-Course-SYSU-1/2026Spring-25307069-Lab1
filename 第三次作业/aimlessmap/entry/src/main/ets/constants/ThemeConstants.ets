export interface ShadowStyle {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class ThemeConstants {
  // 主色调
  static readonly PRIMARY = '#4A6FA5';
  static readonly PRIMARY_LIGHT = '#E8F4F8';
  static readonly PRIMARY_TRANSPARENT = 'rgba(74,111,165,0.35)';

  // 背景色
  static readonly BG = '#F5F7FA';
  static readonly CARD_BG = '#FFFFFF';
  static readonly OVERLAY = '#000000B3';

  // 文字色
  static readonly TEXT_PRIMARY = '#1A1A2E';
  static readonly TEXT_SECONDARY = '#888888';
  static readonly TEXT_MUTED = '#999999';
  static readonly TEXT_DANGER = '#FF6B6B';

  // 圆角
  static readonly RADIUS_LG = 24;
  static readonly RADIUS_MD = 20;
  static readonly RADIUS_SM = 16;
  static readonly RADIUS_XS = 12;
  static readonly RADIUS_FULL = 22;

  // 阴影
  static readonly SHADOW_CARD: ShadowStyle = { radius: 8, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 4 };
  static readonly SHADOW_MODAL: ShadowStyle = { radius: 16, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 8 };
  static readonly SHADOW_BAR: ShadowStyle = { radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: -4 };

  // 边框
  static readonly BORDER_LIGHT = '#E0E0E0';

  // 间距
  static readonly PADDING_PAGE = 24;
  static readonly PADDING_CARD = 16;
  static readonly MARGIN_SM = 8;
  static readonly MARGIN_MD = 12;
  static readonly MARGIN_LG = 16;
}
