import { preferences } from '@kit.ArkData';
import { VisitRecord, VisitRecordListItem, VisitStatistics } from '../model/VisitRecordModel';

const STORAGE_NAME: string = 'visit_records';
const RECORDS_KEY: string = 'all_visit_records';

// ================= 存储数据结构 =================
export class StoredVisitRecord {
  id: string = '';
  studentId: string = '';
  studentName: string = '';
  studentClass: string = '';
  consultationTime: string = '';
  duration: number = 0;
  room: string = '';
  riskLevel: string = '';
  sessionSummary: string = '';
  tags: string[] = [];
  createdAt: string = '';
  updatedAt: string = '';

  constructor() {}
}

// ================= 工具函数 =================
function generateId(): string {
  return Date.now().toString(36) + '_' + Math.random().toString(36).substring(2, 8);
}

function isSameMonth(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth();
}

function formatDate(d: Date): string {
  const year: string = d.getFullYear().toString();
  const month: string = (d.getMonth() + 1).toString().padStart(2, '0');
  const day: string = d.getDate().toString().padStart(2, '0');
  return year + '-' + month + '-' + day;
}

function formatDateTime(d: Date): string {
  const dateStr: string = formatDate(d);
  const hours: string = d.getHours().toString().padStart(2, '0');
  const minutes: string = d.getMinutes().toString().padStart(2, '0');
  return dateStr + ' ' + hours + ':' + minutes;
}

// ================= 来访记录服务 =================
export class VisitRecordService {

  private static instance: VisitRecordService;
  private dataPreferences?: preferences.Preferences;
  private records: VisitRecord[] = [];

  private constructor() {}

  static getInstance(): VisitRecordService {
    if (!VisitRecordService.instance) {
      VisitRecordService.instance = new VisitRecordService();
    }
    return VisitRecordService.instance;
  }

  // ========== 初始化 ==========
  async init(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, STORAGE_NAME);
      await this.loadRecords();
    } catch (e) {
      console.error('初始化来访记录服务失败', JSON.stringify(e));
      this.records = [];
    }
  }

  // ========== 加载数据 ==========
  private async loadRecords(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        this.records = [];
        return;
      }
      const jsonStr: string = await this.dataPreferences.get(RECORDS_KEY, '[]') as string;
      if (!jsonStr || jsonStr === '[]') {
        this.records = [];
        return;
      }
      const rawData: StoredVisitRecord[] = JSON.parse(jsonStr) as StoredVisitRecord[];
      const result: VisitRecord[] = [];
      for (const item of rawData) {
        const record: VisitRecord = new VisitRecord();
        record.id = item.id;
        record.studentId = item.studentId;
        record.studentName = item.studentName;
        record.studentClass = item.studentClass;
        record.consultationTime = new Date(item.consultationTime);
        record.duration = item.duration;
        record.room = item.room;
        record.riskLevel = item.riskLevel;
        record.sessionSummary = item.sessionSummary;
        record.tags = item.tags || [];
        record.createdAt = new Date(item.createdAt);
        record.updatedAt = new Date(item.updatedAt);
        result.push(record);
      }
      // 按时间倒序排列
      result.sort((a: VisitRecord, b: VisitRecord) => {
        return b.consultationTime.getTime() - a.consultationTime.getTime();
      });
      this.records = result;
    } catch (e) {
      console.error('加载来访记录失败', JSON.stringify(e));
      this.records = [];
    }
  }

  // ========== 保存数据 ==========
  private async saveRecords(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }
      const toStore: StoredVisitRecord[] = [];
      for (const r of this.records) {
        const stored: StoredVisitRecord = new StoredVisitRecord();
        stored.id = r.id;
        stored.studentId = r.studentId;
        stored.studentName = r.studentName;
        stored.studentClass = r.studentClass;
        stored.consultationTime = r.consultationTime.toISOString();
        stored.duration = r.duration;
        stored.room = r.room;
        stored.riskLevel = r.riskLevel;
        stored.sessionSummary = r.sessionSummary;
        stored.tags = r.tags;
        stored.createdAt = r.createdAt.toISOString();
        stored.updatedAt = r.updatedAt.toISOString();
        toStore.push(stored);
      }
      await this.dataPreferences.put(RECORDS_KEY, JSON.stringify(toStore));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('保存来访记录失败', JSON.stringify(e));
    }
  }

  // ========== 获取所有记录 ==========
  async getAllRecords(): Promise<VisitRecordListItem[]> {
    const result: VisitRecordListItem[] = [];
    for (const r of this.records) {
      const item: VisitRecordListItem = new VisitRecordListItem();
      item.id = r.id;
      item.studentName = r.studentName;
      item.studentClass = r.studentClass;
      item.consultationTime = r.consultationTime;
      item.duration = r.duration;
      item.room = r.room;
      item.riskLevel = r.riskLevel;
      item.sessionSummary = r.sessionSummary;
      item.tags = r.tags;
      result.push(item);
    }
    return result;
  }

  // ========== 搜索记录 ==========
  async searchRecords(keyword: string): Promise<VisitRecordListItem[]> {
    const result: VisitRecordListItem[] = [];
    const lowerKeyword: string = keyword.toLowerCase().trim();
    if (!lowerKeyword) {
      return this.getAllRecords();
    }
    for (const r of this.records) {
      const matchName: boolean = r.studentName.toLowerCase().includes(lowerKeyword);
      const matchClass: boolean = r.studentClass.toLowerCase().includes(lowerKeyword);
      const matchSummary: boolean = r.sessionSummary.toLowerCase().includes(lowerKeyword);
      const matchTags: boolean = r.tags.some((tag: string) => tag.toLowerCase().includes(lowerKeyword));
      if (matchName || matchClass || matchSummary || matchTags) {
        const item: VisitRecordListItem = new VisitRecordListItem();
        item.id = r.id;
        item.studentName = r.studentName;
        item.studentClass = r.studentClass;
        item.consultationTime = r.consultationTime;
        item.duration = r.duration;
        item.room = r.room;
        item.riskLevel = r.riskLevel;
        item.sessionSummary = r.sessionSummary;
        item.tags = r.tags;
        result.push(item);
      }
    }
    return result;
  }

  // ========== 获取单条记录详情 ==========
  async getRecordById(recordId: string): Promise<VisitRecord | null> {
    for (const r of this.records) {
      if (r.id === recordId) {
        return r;
      }
    }
    return null;
  }

  // ========== 获取某个学生的所有历史记录 ==========
  async getStudentHistory(studentName: string, excludeId?: string): Promise<VisitRecordListItem[]> {
    const result: VisitRecordListItem[] = [];
    for (const r of this.records) {
      if (r.studentName === studentName && r.id !== excludeId) {
        const item: VisitRecordListItem = new VisitRecordListItem();
        item.id = r.id;
        item.studentName = r.studentName;
        item.studentClass = r.studentClass;
        item.consultationTime = r.consultationTime;
        item.duration = r.duration;
        item.room = r.room;
        item.riskLevel = r.riskLevel;
        item.sessionSummary = r.sessionSummary;
        item.tags = r.tags;
        result.push(item);
      }
    }
    result.sort((a: VisitRecordListItem, b: VisitRecordListItem) => {
      return b.consultationTime.getTime() - a.consultationTime.getTime();
    });
    return result;
  }

  // ========== 创建记录 ==========
  async createRecord(data: VisitRecord): Promise<VisitRecord> {
    const record: VisitRecord = new VisitRecord();
    record.id = generateId();
    record.studentId = data.studentId || 'S' + Date.now().toString();
    record.studentName = data.studentName;
    record.studentClass = data.studentClass;
    record.consultationTime = data.consultationTime || new Date();
    record.duration = data.duration || 0;
    record.room = data.room || '';
    record.riskLevel = data.riskLevel || '无风险';
    record.sessionSummary = data.sessionSummary || '';
    record.tags = data.tags || [];
    record.createdAt = new Date();
    record.updatedAt = new Date();

    this.records.push(record);
    // 按时间倒序排列
    this.records.sort((a: VisitRecord, b: VisitRecord) => {
      return b.consultationTime.getTime() - a.consultationTime.getTime();
    });
    await this.saveRecords();
    return record;
  }

  // ========== 更新记录 ==========
  async updateRecord(recordId: string, data: VisitRecord): Promise<VisitRecord | null> {
    let targetIndex: number = -1;
    for (let i: number = 0; i < this.records.length; i++) {
      if (this.records[i].id === recordId) {
        targetIndex = i;
        break;
      }
    }
    if (targetIndex === -1) {
      return null;
    }

    const target: VisitRecord = this.records[targetIndex];
    target.studentName = data.studentName || target.studentName;
    target.studentClass = data.studentClass || target.studentClass;
    if (data.consultationTime) {
      target.consultationTime = data.consultationTime;
    }
    target.duration = data.duration || target.duration;
    target.room = data.room || target.room;
    target.riskLevel = data.riskLevel || target.riskLevel;
    target.sessionSummary = data.sessionSummary || target.sessionSummary;
    target.tags = data.tags || target.tags;
    target.updatedAt = new Date();

    this.records[targetIndex] = target;
    await this.saveRecords();
    return target;
  }

  // ========== 删除记录 ==========
  async deleteRecord(recordId: string): Promise<boolean> {
    const newList: VisitRecord[] = [];
    for (const r of this.records) {
      if (r.id !== recordId) {
        newList.push(r);
      }
    }
    if (newList.length === this.records.length) {
      return false;
    }
    this.records = newList;
    await this.saveRecords();
    return true;
  }

  // ========== 获取统计信息 ==========
  async getStatistics(): Promise<VisitStatistics> {
    const stats: VisitStatistics = new VisitStatistics();
    stats.totalCount = this.records.length;

    const now: Date = new Date();
    for (const r of this.records) {
      if (r.riskLevel === '高风险') stats.highRiskCount++;
      else if (r.riskLevel === '中风险') stats.mediumRiskCount++;
      else if (r.riskLevel === '低风险') stats.lowRiskCount++;
      else if (r.riskLevel === '无风险') stats.noRiskCount++;

      if (isSameMonth(r.consultationTime, now)) {
        stats.thisMonthCount++;
      }
    }
    return stats;
  }

  // ========== 获取风险等级标签颜色 ==========
  getRiskLevelColor(riskLevel: string): string {
    if (riskLevel === '高风险') return '#EF5350';
    if (riskLevel === '中风险') return '#FFA726';
    if (riskLevel === '低风险') return '#42A5F5';
    return '#4CAF50';
  }

  getRiskLevelText(riskLevel: string): string {
    return riskLevel || '无风险';
  }

  // ========== 清空数据 ==========
  async clearAllData(): Promise<void> {
    try {
      this.records = [];
      if (this.dataPreferences) {
        await this.dataPreferences.clear();
        await this.dataPreferences.flush();
      }
    } catch (e) {
      console.error('清除数据失败', JSON.stringify(e));
    }
  }
}