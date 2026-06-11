// entry/src/main/ets/features/counselor/service/CounselorStorage.ets
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class CounselorStorage {
  private static readonly PREF_NAME = 'CounselorPrefs';
  private static readonly KEY_CLASS = 'current_active_class';
  private static readonly KEY_LOCK = 'fingerprint_lock_state';
  private static pref: preferences.Preferences | null = null;

  private static async getPref(context: common.Context): Promise<preferences.Preferences> {
    if (CounselorStorage.pref) {
      return CounselorStorage.pref;
    }
    CounselorStorage.pref = await preferences.getPreferences(context, CounselorStorage.PREF_NAME);
    return CounselorStorage.pref;
  }

  // 持久化保存选中的班级
  static async saveClass(context: common.Context, classStr: string): Promise<void> {
    const pref = await CounselorStorage.getPref(context);
    await pref.put(CounselorStorage.KEY_CLASS, classStr);
    await pref.flush();
  }

  // 读取选中的班级
  static async getClass(context: common.Context): Promise<string> {
    const pref = await CounselorStorage.getPref(context);
    const res = await pref.get(CounselorStorage.KEY_CLASS, '软件工程 2301班');
    return res.toString();
  }

  // 持久化指纹锁状态
  static async saveLock(context: common.Context, isOpen: boolean): Promise<void> {
    const pref = await CounselorStorage.getPref(context);
    await pref.put(CounselorStorage.KEY_LOCK, isOpen);
    await pref.flush();
  }

  // 读取指纹锁状态
  static async getLock(context: common.Context): Promise<boolean> {
    const pref = await CounselorStorage.getPref(context);
    const res = await pref.get(CounselorStorage.KEY_LOCK, false);
    return res as boolean;
  }

  // 彻底擦除随访数据快照
  static async clearAll(context: common.Context): Promise<void> {
    const pref = await CounselorStorage.getPref(context);
    await pref.clear();
    await pref.flush();
  }
}