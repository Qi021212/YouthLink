// entry/src/main/ets/features/counselor/model/FamilyCase.ets

/**
 * 家校协同单次沟通记录节点模型
 */
export interface CoopLog {
  logId: string;
  dateStr: string;     // 沟通日期
  method: string;      // 沟通方式：电话回访/家长到校/微信随访
  content: string;     // 沟通摘要
}

/**
 * 协同危机个案主表模型
 */
export interface FamilyCase {
  caseId: string;
  studentName: string;
  studentId: string;
  riskLevel: string;   // 风险等级：红/橙/黄/绿
  status: string;      // 处置状态：持续追踪/已暂缓/已闭环
  pendingDays: number; // 逾期未跟进天数
  logs: Array<CoopLog>; // 历史串联的时间轴沟通记录
}