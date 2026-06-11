// features/student/service/MoodService.ets

import { preferences } from '@kit.ArkData';
import { MoodRecord, MoodTag, WeeklyTrendPoint, StoredMoodRecord } from '../model/MoodRecord';

const STORAGE_NAME: string = 'mood_preferences';
const KEY_ALL_RECORDS: string = 'all_mood_records';


export class MoodService {
  private static instance: MoodService | null = null;
  private dataPreferences?: preferences.Preferences;
  private allRecords: MoodRecord[] = [];
  private isReady: boolean = false;  // 新增：标记是否初始化完成
  private pendingCallbacks: Array<() => void> = [];  // 新增：等待队列

  private constructor() {
    this.initPreferences();
  }

  static getInstance(): MoodService {
    if (!MoodService.instance) {
      MoodService.instance = new MoodService();
    }
    return MoodService.instance;
  }

  /**
   * 等待服务初始化完成
   */
  async waitForReady(): Promise<void> {
    if (this.isReady) {
      return;
    }
    return new Promise((resolve) => {
      this.pendingCallbacks.push(resolve);
    });
  }

  /**
   * 初始化首选项存储
   */
  private async initPreferences(): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(getContext(), STORAGE_NAME);
      await this.loadFromStorage();
      this.isReady = true;
      // 执行等待的回调
      for (const callback of this.pendingCallbacks) {
        callback();
      }
      this.pendingCallbacks = [];
    } catch (err) {
      console.error('初始化存储失败', JSON.stringify(err));
    }
  }

  /**
   * 从本地存储加载数据到内存
   */
  private async loadFromStorage(): Promise<void> {
    try {
      const jsonStr: string = this.dataPreferences?.getSync(KEY_ALL_RECORDS, '[]') as string;
      const rawArray: Object[] = JSON.parse(jsonStr) as Object[];

      // 显式转换，不使用对象字面量
      const storedRecords: StoredMoodRecord[] = [];
      for (const item of rawArray) {
        const obj = item as Record<string, Object>;
        const stored = StoredMoodRecord.fromJson(obj);
        storedRecords.push(stored);
      }

      // 转换为 MoodRecord
      this.allRecords = [];
      for (const stored of storedRecords) {
        this.allRecords.push(stored.toMoodRecord());
      }

      // 按时间倒序排序（最新的在前）
      this.allRecords.sort(this.sortByTimestampDesc);
      console.info(`加载了 ${this.allRecords.length} 条情绪记录`);
    } catch (err) {
      console.error('加载数据失败', JSON.stringify(err));
      this.allRecords = [];
    }
  }

  /**
   * 排序函数：按时间戳倒序
   */
  private sortByTimestampDesc(a: MoodRecord, b: MoodRecord): number {
    return b.timestamp - a.timestamp;
  }

  /**
   * 保存所有记录到本地存储
   */
  private async saveToStorage(): Promise<void> {
    try {
      // 使用 StoredMoodRecord 类，避免对象字面量
      const recordsToStore: StoredMoodRecord[] = [];
      for (const record of this.allRecords) {
        recordsToStore.push(new StoredMoodRecord(record));
      }

      const jsonStr: string = JSON.stringify(recordsToStore);
      await this.dataPreferences?.put(KEY_ALL_RECORDS, jsonStr);
      await this.dataPreferences?.flush();
    } catch (err) {
      console.error('保存数据失败', JSON.stringify(err));
    }
  }

  /**
   * 新增情绪打卡记录
   * @returns 是否保存成功
   */
  async addMoodRecord(moodTag: MoodTag, content: string): Promise<boolean> {
    try {
      const timestamp: number = Date.now();
      const newRecord: MoodRecord = new MoodRecord(moodTag, content, timestamp);
      this.allRecords.unshift(newRecord);
      await this.saveToStorage();
      console.info(`情绪打卡成功: ${moodTag}, 内容长度: ${content.length}`);
      return true;
    } catch (err) {
      console.error('保存情绪记录失败', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 获取今日是否已打卡
   * @returns 今日是否有记录
   */
  hasTodayRecord(): boolean {
    const todayStart: Date = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayStartTime: number = todayStart.getTime();
    const todayEndTime: number = todayStartTime + 24 * 60 * 60 * 1000;

    for (const record of this.allRecords) {
      if (record.timestamp >= todayStartTime && record.timestamp < todayEndTime) {
        return true;
      }
    }
    return false;
  }

  /**
   * 获取今日的情绪记录（如果有）
   */
  getTodayRecord(): MoodRecord | null {
    const todayStart: Date = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayStartTime: number = todayStart.getTime();
    const todayEndTime: number = todayStartTime + 24 * 60 * 60 * 1000;

    for (const record of this.allRecords) {
      if (record.timestamp >= todayStartTime && record.timestamp < todayEndTime) {
        return record;
      }
    }
    return null;
  }

  /**
   * 获取最近7天的情绪趋势数据（用于折线图）
   */
  async getWeeklyTrend(): Promise<WeeklyTrendPoint[]> {
    const trend: WeeklyTrendPoint[] = [];
    const today: Date = new Date();

    for (let i: number = 6; i >= 0; i--) {
      const targetDate: Date = new Date(today);
      targetDate.setDate(today.getDate() - i);
      targetDate.setHours(0, 0, 0, 0);
      const dayStart: number = targetDate.getTime();
      const dayEnd: number = dayStart + 24 * 60 * 60 * 1000;

      // 查找当天的记录（取最新的）
      let finalScore: number = 70;
      let finalMoodTag: MoodTag | undefined = undefined;

      let latestRecord: MoodRecord | null = null;
      for (const record of this.allRecords) {
        if (record.timestamp >= dayStart && record.timestamp < dayEnd) {
          if (latestRecord === null || record.timestamp > latestRecord.timestamp) {
            latestRecord = record;
          }
        }
      }

      if (latestRecord !== null) {
        finalScore = latestRecord.score;
        finalMoodTag = latestRecord.moodTag;
      }

      const month: number = targetDate.getMonth() + 1;
      const date: number = targetDate.getDate();
      const dateStr: string = `${month}/${date}`;
      trend.push(new WeeklyTrendPoint(dateStr, dayStart, finalScore, finalMoodTag));
    }

    return trend;
  }

  /**
   * 获取所有历史记录（分页）
   */
  getAllRecords(limit: number = 30): MoodRecord[] {
    const result: MoodRecord[] = [];
    const count = Math.min(limit, this.allRecords.length);
    for (let i = 0; i < count; i++) {
      result.push(this.allRecords[i]);
    }
    return result;
  }

  /**
   * 根据日期获取某条具体记录
   */
  getRecordByTimestamp(timestamp: number): MoodRecord | undefined {
    for (const record of this.allRecords) {
      if (record.timestamp === timestamp) {
        return record;
      }
    }
    return undefined;
  }

  /**
   * 获取激励语（根据情绪）
   */
  getMotivationQuote(moodTag: MoodTag): string {
    let quotes: string[] = [];

    switch (moodTag) {
      case MoodTag.HAPPY:
        quotes = ['保持这份好心情，今天也很棒！', '你的笑容会感染身边的人~', '快乐的一天，记得分享给朋友！'];
        break;
      case MoodTag.NORMAL:
        quotes = ['平静也是一种力量', '今天情绪稳定，适合做些小规划', '继续保持，每一天都值得认真对待'];
        break;
      case MoodTag.CONFUSED:
        quotes = ['迷茫时停下来听听内心的声音', '每个人都有困惑的时候，给自己一点时间', '慢慢来，答案会在路上'];
        break;
      case MoodTag.DOWN:
        quotes = ['允许自己偶尔低落，明天会更好', '你已经做得很好了，休息一下再出发', '难过的时候，记得还有人在乎你'];
        break;
      case MoodTag.SAD:
        quotes = ['你的感受很重要，需要找人聊聊吗？', '悲伤会过去的，给自己一个温暖的拥抱', '如果很难受，可以找信任的人说一说'];
        break;
      default:
        quotes = ['记录此刻心情，让情绪被看见', '每一天都值得被认真对待', '看见情绪，就是照顾自己的开始'];
        break;
    }

    const randomIndex: number = Math.floor(Math.random() * quotes.length);
    return quotes[randomIndex];
  }
}