import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    console.info('onBackup ok');
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    console.info('onRestore ok');
    console.info(`bundleVersion: ${JSON.stringify(bundleVersion)}`);
  }
}
