import { abilityAccessCtrl, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './Logger';

export class PermissionUtil {
  static async requestPermissions(permissions: Permissions[]): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const context = getContext();
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, permissions);
      return result.authResults.every((authResult: number) => authResult === 0);
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(`权限申请失败: ${error.code}, ${error.message}`);
      return false;
    }
  }

  static async checkPermission(permission: Permissions): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const context = getContext();
      const result = await atManager.checkAccessToken(context.applicationInfo.accessTokenId, permission);
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(`权限检查失败: ${error.code}, ${error.message}`);
      return false;
    }
  }

  static async requestPhotoPermissions(): Promise<boolean> {
    // 只申请相机权限，相册选择使用系统Picker不需要额外权限
    const permissions: Permissions[] = ['ohos.permission.CAMERA' as Permissions];
    return await PermissionUtil.requestPermissions(permissions);
  }

  static async requestLocationPermissions(): Promise<boolean> {
    const permissions: Permissions[] = [
      'ohos.permission.APPROXIMATELY_LOCATION' as Permissions,
      'ohos.permission.LOCATION' as Permissions
    ];
    return await PermissionUtil.requestPermissions(permissions);
  }
}
