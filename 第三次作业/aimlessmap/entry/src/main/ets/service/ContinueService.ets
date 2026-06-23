import { TrailPoint } from '../model/WalkRecord';
import { RandomPoint } from './RandomService';
import { Logger } from '../utils/Logger';

/**
 * 流转状态数据接口
 */
export interface ContinueState {
  page: string;              // 当前页面：'WalkPage' | 'HomePage' | ...
  duration: number;          // 总时长（分钟）
  remainingSeconds: number;  // 倒计时剩余秒数
  startLat: number;          // 起点纬度
  startLon: number;          // 起点经度
  redirectCount: number;     // 换向次数
  trailPoints: TrailPoint[]; // 轨迹点数组
  currentPoint: RandomPoint | null; // 当前目标点
  isPaused: boolean;         // 是否暂停
  startTime: number;         // 开始时间戳
  elapsedSeconds: number;    // 已进行秒数
  currentSoundType: string;  // 当前音效类型
  currentSoundUri: string;   // 自定义音效URI
}

/**
 * 自由流转服务
 * 管理跨设备迁移时的状态保存与恢复
 */
export class ContinueService {
  private static currentState: ContinueState | null = null;
  private static restoreState: ContinueState | null = null;

  /**
   * 获取当前状态（用于 onContinue 保存）
   */
  static getCurrentState(): ContinueState | null {
    return ContinueService.currentState;
  }

  /**
   * 设置当前状态（页面中定期更新）
   */
  static setCurrentState(state: ContinueState): void {
    ContinueService.currentState = state;
  }

  /**
   * 更新部分状态字段
   */
  static updateState(partial: Partial<ContinueState>): void {
    if (ContinueService.currentState) {
      const merged: ContinueState = {
        page: partial.page ?? ContinueService.currentState.page,
        duration: partial.duration ?? ContinueService.currentState.duration,
        remainingSeconds: partial.remainingSeconds ?? ContinueService.currentState.remainingSeconds,
        startLat: partial.startLat ?? ContinueService.currentState.startLat,
        startLon: partial.startLon ?? ContinueService.currentState.startLon,
        redirectCount: partial.redirectCount ?? ContinueService.currentState.redirectCount,
        trailPoints: partial.trailPoints ?? ContinueService.currentState.trailPoints,
        currentPoint: partial.currentPoint ?? ContinueService.currentState.currentPoint,
        isPaused: partial.isPaused ?? ContinueService.currentState.isPaused,
        startTime: partial.startTime ?? ContinueService.currentState.startTime,
        elapsedSeconds: partial.elapsedSeconds ?? ContinueService.currentState.elapsedSeconds,
        currentSoundType: partial.currentSoundType ?? ContinueService.currentState.currentSoundType,
        currentSoundUri: partial.currentSoundUri ?? ContinueService.currentState.currentSoundUri
      };
      ContinueService.currentState = merged;
    } else {
      ContinueService.currentState = partial as ContinueState;
    }
  }

  /**
   * 获取恢复状态（目标设备使用）
   */
  static getRestoreState(): ContinueState | null {
    const state = ContinueService.restoreState;
    // 获取后清空，避免重复恢复
    ContinueService.restoreState = null;
    return state;
  }

  /**
   * 设置恢复状态（EntryAbility 调用）
   */
  static setRestoreState(state: ContinueState): void {
    ContinueService.restoreState = state;
    Logger.info(`ContinueService: 设置恢复状态，页面=${state.page}`);
  }

  /**
   * 检查是否有待恢复的状态
   */
  static hasRestoreState(): boolean {
    return ContinueService.restoreState !== null;
  }

  /**
   * 清空所有状态
   */
  static clearState(): void {
    ContinueService.currentState = null;
    ContinueService.restoreState = null;
    Logger.info('ContinueService: 状态已清空');
  }

  /**
   * 创建 WalkPage 的初始状态
   */
  static createWalkState(
    duration: number,
    startLat: number,
    startLon: number,
    currentSoundType: string = '',
    currentSoundUri: string = ''
  ): ContinueState {
    return {
      page: 'WalkPage',
      duration,
      remainingSeconds: duration * 60,
      startLat,
      startLon,
      redirectCount: 0,
      trailPoints: [],
      currentPoint: null,
      isPaused: false,
      startTime: Date.now(),
      elapsedSeconds: 0,
      currentSoundType,
      currentSoundUri
    };
  }
}
