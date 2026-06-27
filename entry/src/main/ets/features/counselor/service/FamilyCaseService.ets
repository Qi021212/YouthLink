// ============================================================
// 2. Service层 - 数据服务（修复版）
// ============================================================
// features/counselor/service/FamilyCaseService.ets

import {
  FamilyCase,
  CommunicationRecord,
  CaseStatus,
  ContactType,
  CaseFilter,
  CaseStatistics,
  CreateCaseData,
  AddRecordData
} from '../model/FamilyCase';
import { promptAction } from '@kit.ArkUI';

/**
 * 模拟数据 - 个案列表
 */
const mockCases: FamilyCase[] = [
  {
    caseId: 'CASE-001',
    studentId: '20240101',
    studentName: '张明',
    classInfo: '计科2201班',
    dormInfo: 'A3-514',
    contactTarget: '近期情绪波动较大，需要家校协同关注',
    status: CaseStatus.PENDING,
    riskLevel: 2,
    createdAt: '2026-06-20 09:00:00',
    updatedAt: '2026-06-20 09:00:00',
    nextFollowUpTime: '2026-06-28 10:00:00',
    isOverdue: true
  },
  {
    caseId: 'CASE-002',
    studentId: '20240105',
    studentName: '李红',
    classInfo: '计科2201班',
    dormInfo: 'A3-508',
    contactTarget: '成绩下滑，疑似家庭因素影响',
    status: CaseStatus.IN_PROGRESS,
    riskLevel: 1,
    createdAt: '2026-06-18 14:30:00',
    updatedAt: '2026-06-22 16:00:00',
    nextFollowUpTime: '2026-06-30 15:00:00',
    isOverdue: false
  },
  {
    caseId: 'CASE-003',
    studentId: '20240112',
    studentName: '王芳',
    classInfo: '计科2202班',
    dormInfo: 'B2-201',
    contactTarget: '长期失眠，建议家长陪同就医',
    status: CaseStatus.COMPLETED,
    riskLevel: 2,
    createdAt: '2026-06-10 10:00:00',
    updatedAt: '2026-06-25 11:00:00',
    nextFollowUpTime: undefined,
    isOverdue: false
  },
  {
    caseId: 'CASE-004',
    studentId: '20240120',
    studentName: '赵强',
    classInfo: '计科2202班',
    dormInfo: 'B2-205',
    contactTarget: '宿舍关系紧张，需家长配合引导',
    status: CaseStatus.PENDING,
    riskLevel: 1,
    createdAt: '2026-06-24 08:30:00',
    updatedAt: '2026-06-24 08:30:00',
    nextFollowUpTime: '2026-07-01 09:00:00',
    isOverdue: false
  }
];

/**
 * 模拟数据 - 沟通记录
 */
const mockRecords: CommunicationRecord[] = [
  {
    recordId: 'REC-001',
    caseId: 'CASE-001',
    studentId: '20240101',
    studentName: '张明',
    contactType: ContactType.PHONE,
    contactTime: '2026-06-20 10:30:00',
    duration: 15,
    content: '与张明母亲沟通，了解到近期家中老人住院，学生心理压力较大。建议家长多给予情感支持，并关注学生睡眠情况。',
    actionTaken: '已建议家长每周至少通话2次，并鼓励学生参加学校心理活动',
    nextFollowUpTime: '2026-06-28 10:00:00',
    createdBy: '辅导员-李老师',
    createdAt: '2026-06-20 11:00:00'
  },
  {
    recordId: 'REC-002',
    caseId: 'CASE-002',
    studentId: '20240105',
    studentName: '李红',
    contactType: ContactType.WECHAT,
    contactTime: '2026-06-22 15:30:00',
    duration: 20,
    content: '通过微信与李红父亲沟通，了解到家庭近期经济压力较大。家长表示愿意配合学校工作，但希望了解具体帮扶政策。',
    actionTaken: '已向学生处申请临时困难补助，并安排李红参加勤工助学',
    nextFollowUpTime: '2026-06-30 15:00:00',
    createdBy: '辅导员-李老师',
    createdAt: '2026-06-22 16:00:00'
  },
  {
    recordId: 'REC-003',
    caseId: 'CASE-003',
    studentId: '20240112',
    studentName: '王芳',
    contactType: ContactType.FACE_TO_FACE,
    contactTime: '2026-06-25 10:00:00',
    duration: 30,
    content: '与王芳及母亲进行面对面沟通，详细了解失眠情况。母亲表示愿意带其就医，并配合调整作息。',
    actionTaken: '已转介学校心理中心，安排王芳每周进行心理咨询',
    nextFollowUpTime: undefined,
    createdBy: '辅导员-李老师',
    createdAt: '2026-06-25 11:00:00'
  }
];

/**
 * 家校协同服务类
 */
export class FamilyCaseService {
  private static instance: FamilyCaseService | null = null;

  private constructor() {
    // 私有构造函数
  }

  static getInstance(): FamilyCaseService {
    if (!FamilyCaseService.instance) {
      FamilyCaseService.instance = new FamilyCaseService();
    }
    return FamilyCaseService.instance;
  }

  /**
   * 获取个案列表（支持筛选）
   */
  async getCases(filter?: CaseFilter): Promise<FamilyCase[]> {
    // 模拟网络延迟
    await this.delay(300);

    let cases = [...mockCases];

    if (filter?.status !== undefined) {
      cases = cases.filter(c => c.status === filter.status);
    }

    if (filter?.keyword && filter.keyword.trim().length > 0) {
      const keyword = filter.keyword.toLowerCase().trim();
      cases = cases.filter(c =>
      c.studentName.toLowerCase().includes(keyword) ||
        c.studentId.includes(keyword) ||
        c.dormInfo.toLowerCase().includes(keyword) ||
        c.classInfo.toLowerCase().includes(keyword)
      );
    }

    if (filter?.showOnlyOverdue === true) {
      cases = cases.filter(c => c.isOverdue);
    }

    // 按逾期优先、创建时间降序排列
    return cases.sort((a, b) => {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });
  }

  /**
   * 获取单个个案详情
   */
  async getCaseDetail(caseId: string): Promise<FamilyCase | null> {
    await this.delay(200);
    const caseItem = mockCases.find(c => c.caseId === caseId);
    return caseItem || null;
  }

  /**
   * 获取个案的沟通记录
   */
  async getCommunicationRecords(caseId: string): Promise<CommunicationRecord[]> {
    await this.delay(200);
    return mockRecords
      .filter(r => r.caseId === caseId)
      .sort((a, b) =>
      new Date(b.contactTime).getTime() - new Date(a.contactTime).getTime()
      );
  }

  /**
   * 创建新个案
   */
  async createCase(data: CreateCaseData): Promise<FamilyCase> {
    await this.delay(500);

    const newCase: FamilyCase = {
      caseId: `CASE-${String(mockCases.length + 1).padStart(3, '0')}`,
      studentId: data.studentId,
      studentName: data.studentName,
      classInfo: data.classInfo,
      dormInfo: data.dormInfo,
      contactTarget: data.contactTarget,
      status: data.status,
      riskLevel: data.riskLevel,
      createdAt: this.getCurrentTime(),
      updatedAt: this.getCurrentTime(),
      isOverdue: false
    };

    mockCases.push(newCase);
    return newCase;
  }

  /**
   * 添加沟通记录
   */
  async addCommunicationRecord(data: AddRecordData): Promise<CommunicationRecord> {
    await this.delay(400);

    const newRecord: CommunicationRecord = {
      recordId: `REC-${String(mockRecords.length + 1).padStart(3, '0')}`,
      caseId: data.caseId,
      studentId: data.studentId,
      studentName: data.studentName,
      contactType: data.contactType,
      contactTime: data.contactTime,
      duration: data.duration,
      content: data.content,
      actionTaken: data.actionTaken,
      nextFollowUpTime: data.nextFollowUpTime,
      createdBy: '辅导员-李老师',
      createdAt: this.getCurrentTime()
    };

    mockRecords.push(newRecord);

    // 更新个案的更新时间
    const caseItem = mockCases.find(c => c.caseId === data.caseId);
    if (caseItem) {
      caseItem.updatedAt = newRecord.createdAt;
      if (data.nextFollowUpTime) {
        caseItem.nextFollowUpTime = data.nextFollowUpTime;
        caseItem.isOverdue = false;
      }
    }

    return newRecord;
  }

  /**
   * 更新个案状态
   */
  async updateCaseStatus(caseId: string, status: CaseStatus): Promise<boolean> {
    await this.delay(200);
    const caseItem = mockCases.find(c => c.caseId === caseId);
    if (caseItem) {
      caseItem.status = status;
      caseItem.updatedAt = this.getCurrentTime();
      return true;
    }
    return false;
  }

  /**
   * 获取统计概览
   */
  async getStatistics(): Promise<CaseStatistics> {
    await this.delay(200);
    const total = mockCases.length;
    const pending = mockCases.filter(c => c.status === CaseStatus.PENDING).length;
    const inProgress = mockCases.filter(c => c.status === CaseStatus.IN_PROGRESS).length;
    const completed = mockCases.filter(c => c.status === CaseStatus.COMPLETED).length;
    const overdue = mockCases.filter(c => c.isOverdue).length;

    return { total, pending, inProgress, completed, overdue };
  }

  /**
   * 获取当前时间字符串
   */
  private getCurrentTime(): string {
    const now = new Date();
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  }

  /**
   * 延迟函数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}