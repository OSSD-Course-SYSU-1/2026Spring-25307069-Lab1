export class AppConstants {
  static readonly APP_NAME = '无目的地图';
  static readonly CLIENT_ID = '6917606579894256020';
  static readonly MIN_DISTANCE = 300;
  static readonly MAX_DISTANCE = 800;
  static readonly TIMER_OPTIONS: number[] = [5, 15, 30, 45, 60];
  static readonly CUSTOM_TIMER = -1; // 自定义时长标识
  static readonly DEFAULT_TIMER = 30;

  static readonly MAP_ZOOM = 15;
  static readonly SOUND_TYPES = ['无', '雨声', '海浪', '森林', '风声'];
  // 默认坐标（北京天安门），定位失败时使用
  static readonly DEFAULT_LAT = 39.9042;
  static readonly DEFAULT_LON = 116.4074;
  // 随机行走时间范围（秒）
  static readonly MIN_WALK_TIME = 30;   // 最少30秒
  static readonly MAX_WALK_TIME = 120;  // 最多2分钟
}
