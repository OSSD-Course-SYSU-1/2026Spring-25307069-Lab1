import hilog from "@ohos:hilog";
import BackupExtensionAbility from "@ohos:application.BackupExtensionAbility";
import type { BundleVersion } from "@ohos:application.BackupExtensionAbility";
const TAG = 'testTag';
export default class EntryBackupAbility extends BackupExtensionAbility {
    async onBackup() {
        hilog.info(0x0000, TAG, 'onBackup ok');
        await Promise.resolve();
    }
    async onRestore(bundleVersion: BundleVersion) {
        hilog.info(0x0000, TAG, 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
        await Promise.resolve();
    }
}
