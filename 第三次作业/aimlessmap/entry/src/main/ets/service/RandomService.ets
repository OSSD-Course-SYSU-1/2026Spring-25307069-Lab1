import { GeoUtils } from '../utils/GeoUtils';
import { AppConstants } from '../constants/AppConstants';

export class RandomPoint {
  latitude: number = 0;
  longitude: number = 0;
  bearing: number = 0;
  distance: number = 0;
  direction: string = '';
  walkTime: number = 0; // 随机行走时间（秒）
}

export class RandomService {
  static generateRandomPoint(lat: number, lon: number): RandomPoint {
    const bearing = Math.random() * 360;
    const distance = AppConstants.MIN_DISTANCE + Math.random() * (AppConstants.MAX_DISTANCE - AppConstants.MIN_DISTANCE);
    const dest = GeoUtils.calculateDestination(lat, lon, distance, bearing);
    // 生成随机行走时间（30秒~2分钟）
    const walkTime = AppConstants.MIN_WALK_TIME + Math.floor(Math.random() * (AppConstants.MAX_WALK_TIME - AppConstants.MIN_WALK_TIME + 1));
    const pt = new RandomPoint();
    pt.latitude = dest.latitude;
    pt.longitude = dest.longitude;
    pt.bearing = Math.round(bearing);
    pt.distance = Math.round(distance);
    pt.direction = GeoUtils.bearingToDirection(bearing);
    pt.walkTime = walkTime;
    return pt;
  }
}
