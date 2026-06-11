// entry/src/main/ets/common/model/CaseData.ts
import { util } from '@kit.ArkTS';

@Observed
export class CaseData {
  id: string = util.generateRandomUUID();
  studentName: string = '';
  parentPhone: string = '';
  status: string = '进行中';
  deadline: number = Date.now();
  createdAt: number = Date.now(); // 统一命名为 createdAt
  records: CommunicationRecord[] = [];
}

export class CommunicationRecord {
  id: string = util.generateRandomUUID();
  caseId: string = '';
  time: number = Date.now();
  content: string = '';
  type: string = '电话';
}