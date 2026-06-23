import { geoLocationManager } from '@kit.LocationKit';
import { Logger } from '../utils/Logger';

export interface LocationResult {
  latitude: number;
  longitude: number;
}

export class LocationService {
  static async getCurrentLocation(): Promise<LocationResult> {
    const location = await geoLocationManager.getCurrentLocation({
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario: geoLocationManager.LocationRequestScenario.UNSET,
      maxAccuracy: 0
    });
    Logger.info(`定位成功: ${location.latitude}, ${location.longitude}`);
    const result: LocationResult = { latitude: location.latitude, longitude: location.longitude };
    return result;
  }

  static isLocationEnabled(): boolean {
    return geoLocationManager.isLocationEnabled();
  }
}
