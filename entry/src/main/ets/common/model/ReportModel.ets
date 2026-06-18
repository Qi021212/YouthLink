// entry/src/main/ets/common/model/ReportModel.ts
import { util } from '@kit.ArkTS';

@Observed
export class ReportData {
  id: string = util.generateRandomUUID();
  studentName: string = '未知学生';
  className: string = '未知班级';
  submitTime: number = Date.now();

  // AI 预审核心字段
  aiScore: number = 85;
  aiCounselorSummary: string = '暂无摘要'; // 给老师看的客观风险诊断
  aiStudentPortrait: string = '暂无画像';  // 给学生看的温暖安慰信
  riskLevel: string = '低风险';

  // 状态：pending(待审), approved(已通过), rejected(已驳回)
  status: string = 'pending';

  // 🌟 直接接收学生端生成的 fullQaHistory
  qaHistory: string = '';
}