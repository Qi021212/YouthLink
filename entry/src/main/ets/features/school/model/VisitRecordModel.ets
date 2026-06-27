// ================= 来访记录 =================
export class VisitRecord {
  id: string = '';
  studentId: string = '';
  studentName: string = '';
  studentClass: string = '';
  consultationTime: Date = new Date();
  duration: number = 0;              // 咨询时长（分钟）
  room: string = '';                 // 咨询室
  riskLevel: string = '';            // 无风险 | 低风险 | 中风险 | 高风险
  sessionSummary: string = '';       // 会话总结
  tags: string[] = [];               // 标签
  createdAt: Date = new Date();
  updatedAt: Date = new Date();

  constructor() {}
}

// ================= 记录列表项（用于列表展示） =================
export class VisitRecordListItem {
  id: string = '';
  studentName: string = '';
  studentClass: string = '';
  consultationTime: Date = new Date();
  duration: number = 0;
  room: string = '';
  riskLevel: string = '';
  sessionSummary: string = '';
  tags: string[] = [];

  constructor() {}
}

// ================= 统计信息 =================
export class VisitStatistics {
  totalCount: number = 0;
  highRiskCount: number = 0;
  mediumRiskCount: number = 0;
  lowRiskCount: number = 0;
  noRiskCount: number = 0;
  thisMonthCount: number = 0;

  constructor() {}
}