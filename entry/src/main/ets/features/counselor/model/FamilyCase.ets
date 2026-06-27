// ============================================================
// 1. Model层 - 数据模型定义（修复版）
// ============================================================
// features/counselor/model/FamilyCase.ets

/**
 * 家校协同个案模型
 */
export interface FamilyCase {
  caseId: string;           // 个案唯一标识
  studentId: string;        // 学生ID
  studentName: string;      // 学生姓名
  classInfo: string;        // 班级信息（如：计科2201班）
  dormInfo: string;         // 寝室信息（如：A3-514）
  contactTarget: string;    // 沟通目标/主题
  status: CaseStatus;       // 个案状态
  riskLevel: 0 | 1 | 2 | 3; // 关联风险等级 0绿 1黄 2橙 3红
  createdAt: string;        // 创建时间
  updatedAt: string;        // 更新时间
  nextFollowUpTime?: string; // 计划下次跟进时间
  isOverdue: boolean;       // 是否逾期
}

/**
 * 个案状态枚举
 */
export enum CaseStatus {
  PENDING = 'pending',       // 待沟通
  IN_PROGRESS = 'in_progress', // 进行中
  COMPLETED = 'completed',   // 已完成
  SUSPENDED = 'suspended'    // 暂停
}

/**
 * 沟通记录模型
 */
export interface CommunicationRecord {
  recordId: string;          // 记录唯一标识
  caseId: string;            // 关联个案ID
  studentId: string;         // 学生ID
  studentName: string;       // 学生姓名
  contactType: ContactType;  // 沟通方式
  contactTime: string;       // 沟通时间
  duration?: number;         // 沟通时长（分钟）
  content: string;           // 沟通内容
  actionTaken?: string;      // 采取的行动
  nextFollowUpTime?: string; // 下次跟进时间
  createdBy: string;         // 记录人
  createdAt: string;         // 创建时间
  attachments?: string[];    // 附件URL列表
}

/**
 * 沟通方式枚举
 */
export enum ContactType {
  PHONE = 'phone',           // 电话
  WECHAT = 'wechat',         // 微信
  FACE_TO_FACE = 'face_to_face', // 面谈
  HOME_VISIT = 'home_visit', // 家访
  EMAIL = 'email',           // 邮件
  OTHER = 'other'            // 其他
}

/**
 * 统计信息接口
 */
export interface CaseStatistics {
  total: number;
  pending: number;
  inProgress: number;
  completed: number;
  overdue: number;
}

/**
 * 个案筛选条件接口
 */
export interface CaseFilter {
  status?: CaseStatus;
  keyword?: string;
  showOnlyOverdue?: boolean;
}

/**
 * 创建个案表单数据接口
 */
export interface CreateCaseData {
  studentName: string;
  studentId: string;
  classInfo: string;
  dormInfo: string;
  contactTarget: string;
  riskLevel: 0 | 1 | 2 | 3;
  status: CaseStatus;
}

/**
 * 添加沟通记录数据接口
 */
export interface AddRecordData {
  caseId: string;
  studentId: string;
  studentName: string;
  contactType: ContactType;
  contactTime: string;
  duration?: number;
  content: string;
  actionTaken?: string;
  nextFollowUpTime?: string;
}

/**
 * 沟通方式标签映射（使用Record类型）
 */
export const ContactTypeLabel: Record<ContactType, string> = {
  [ContactType.PHONE]: '电话',
  [ContactType.WECHAT]: '微信',
  [ContactType.FACE_TO_FACE]: '面谈',
  [ContactType.HOME_VISIT]: '家访',
  [ContactType.EMAIL]: '邮件',
  [ContactType.OTHER]: '其他'
};

/**
 * 个案状态标签映射
 */
export const CaseStatusLabel: Record<CaseStatus, string> = {
  [CaseStatus.PENDING]: '待沟通',
  [CaseStatus.IN_PROGRESS]: '进行中',
  [CaseStatus.COMPLETED]: '已完成',
  [CaseStatus.SUSPENDED]: '暂停'
};

/**
 * 个案状态颜色映射
 */
export const CaseStatusColor: Record<CaseStatus, string> = {
  [CaseStatus.PENDING]: '#FF6B6B',      // 红色 - 紧急
  [CaseStatus.IN_PROGRESS]: '#4ECDC4',  // 青色 - 进行中
  [CaseStatus.COMPLETED]: '#95E1D3',    // 淡绿 - 已完成
  [CaseStatus.SUSPENDED]: '#F7DC6F'     // 黄色 - 暂停
};

/**
 * 风险等级标签
 */
export const RiskLevelLabel: Record<number, string> = {
  0: '绿',
  1: '黄',
  2: '橙',
  3: '红'
};

/**
 * 风险等级颜色
 */
export const RiskLevelColor: Record<number, string> = {
  0: '#4CAF50',
  1: '#FFC107',
  2: '#FF9800',
  3: '#F44336'
};