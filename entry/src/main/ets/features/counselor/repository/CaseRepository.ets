import { DatabaseHelper, CaseRow, RecordRow } from '../../../common/utils/DatabaseHelper';
import { CaseData, CommunicationRecord } from '../model/CaseData';
import { scheduleNotification } from '../../../common/utils/NotificationHelper';

// 定义一个明确的接口用于 getCaseTimeline 的返回值
export interface CaseTimelineResult {
  caseInfo: CaseData | null;
  records: CommunicationRecord[];
}

export class CaseRepository {
  static async getCaseTimeline(caseId: string): Promise<CaseTimelineResult> {
    const db = DatabaseHelper.getInstance();
    const caseInfo = await db.getCaseById(caseId);
    const rawRecords: RecordRow[] = await db.getRecordsByCaseId(caseId);

    // 将数据库层对象(RecordRow)转换为业务对象(CommunicationRecord)
    const records: CommunicationRecord[] = rawRecords.map((row: RecordRow) => {
      let record = new CommunicationRecord();
      record.id = row.id;
      record.caseId = row.caseId;
      record.content = row.content;
      record.type = row.type;
      record.time = row.timestamp;
      return record;
    });

    return { caseInfo: caseInfo, records: records };
  }

  static async createNewCase(c: CaseData): Promise<void> {
    const db = DatabaseHelper.getInstance();

    // 🌟 彻底解决第 33 行报错：
    // 创建一个明确符合 CaseRow 接口规范的对象字面量，断开 Class 到 Interface 的直接赋值
    let rowData: CaseRow = {
      id: c.id,
      studentName: c.studentName,
      parentPhone: c.parentPhone,
      deadline: c.deadline,
      status: c.status,
      // ⚠️ 踩坑注意：如果你的 CaseData 类里字段名依然是 createTime，请将下面改为 c.createTime
      createdAt: c.createdAt
    };

    // 此时传入明确声明为 CaseRow 类型的 rowData，ArkTS 检查直接通过
    await db.addCase(rowData);

    scheduleNotification(c.id, `个案到期提醒: ${c.studentName}`, c.deadline);
  }
}