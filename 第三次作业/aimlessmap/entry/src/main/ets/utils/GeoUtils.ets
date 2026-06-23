const EARTH_RADIUS = 6371000;
const deg2rad = (d: number) => d * Math.PI / 180;
const rad2deg = (r: number) => r * 180 / Math.PI;

export interface GeoResult {
  latitude: number;
  longitude: number;
}

export class GeoUtils {
  static calculateDestination(lat: number, lon: number, dist: number, bearing: number): GeoResult {
    const lat1 = deg2rad(lat), lon1 = deg2rad(lon), brng = deg2rad(bearing);
    const d = dist / EARTH_RADIUS;
    const lat2 = Math.asin(Math.sin(lat1) * Math.cos(d) + Math.cos(lat1) * Math.sin(d) * Math.cos(brng));
    const lon2 = lon1 + Math.atan2(Math.sin(brng) * Math.sin(d) * Math.cos(lat1), Math.cos(d) - Math.sin(lat1) * Math.sin(lat2));
    const result: GeoResult = { latitude: rad2deg(lat2), longitude: rad2deg(lon2) };
    return result;
  }

  static bearingToDirection(bearing: number): string {
    // 以用户面向为前方（0度），转换为前后左右方向
    // bearing: 0=前方, 45=右前方, 90=右方, 135=右后方, 180=后方, 225=左后方, 270=左方, 315=左前方
    const dirs = ['前方', '右前方', '右方', '右后方', '后方', '左后方', '左方', '左前方'];
    return dirs[Math.round(bearing / 45) % 8];
  }

  static calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const dLat = deg2rad(lat2 - lat1), dLon = deg2rad(lon2 - lon1);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) ** 2;
    return EARTH_RADIUS * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
