import { ClassHeatData, DormHeatData, RiskStudent } from '../model/RiskStudent'
import { TimelineNode, WarningEvent } from '../model/WarningEvent'

const MOCK_DELAY = 400

class ClassHeatRow {
  classId: string
  className: string
  riskLevel: number
  studentCount: number
  riskRatio: number

  constructor(classId: string, className: string, riskLevel: number, studentCount: number, riskRatio: number) {
    this.classId = classId
    this.className = className
    this.riskLevel = riskLevel
    this.studentCount = studentCount
    this.riskRatio = riskRatio
  }
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve: () => void) => setTimeout(resolve, ms))
}

function toClassHeatData(row: ClassHeatRow): ClassHeatData {
  return {
    classId: row.classId,
    className: row.className,
    riskLevel: row.riskLevel,
    studentCount: row.studentCount,
    riskRatio: row.riskRatio
  }
}

export class CounselorService {

  async fetchHeatmapData(): Promise<ClassHeatData[]> {
    await delay(MOCK_DELAY)

    const rows: ClassHeatRow[] = [
      new ClassHeatRow('C1', '计算机2401', 0, 38, 5),
      new ClassHeatRow('C2', '计算机2402', 1, 36, 14),
      new ClassHeatRow('C3', '软件2401', 2, 40, 22),
      new ClassHeatRow('C4', '软件2402', 0, 35, 8),
      new ClassHeatRow('C5', '网络2401', 3, 32, 31),
      new ClassHeatRow('C6', '网络2402', 1, 37, 16),
      new ClassHeatRow('C7', '大数据2401', 0, 39, 3),
      new ClassHeatRow('C8', '人工智能2401', 2, 34, 19)
    ]

    const result: ClassHeatData[] = []
    for (let i = 0; i < rows.length; i++) {
      result.push(toClassHeatData(rows[i]))
    }
    return result
  }

  async fetchClassDetail(classId: string): Promise<ClassDetailResult> {
    await delay(MOCK_DELAY)

    const dormList: DormHeatData[] = []
    dormList.push({ dormId: 'D1', dormName: '5201', riskLevel: 2, riskStudentIds: ['S001', 'S004'] })
    dormList.push({ dormId: 'D2', dormName: '5202', riskLevel: 0, riskStudentIds: [] })
    dormList.push({ dormId: 'D3', dormName: '5203', riskLevel: 1, riskStudentIds: ['S008'] })
    dormList.push({ dormId: 'D4', dormName: '5204', riskLevel: 3, riskStudentIds: ['S003', 'S011', 'S015'] })
    dormList.push({ dormId: 'D5', dormName: '5205', riskLevel: 0, riskStudentIds: [] })
    dormList.push({ dormId: 'D6', dormName: '5206', riskLevel: 1, riskStudentIds: ['S020'] })

    const riskStudents: RiskStudent[] = []
    riskStudents.push({ studentId: 'S001', name: '张小明', classId: classId, dormId: '5201', riskLevel: 2, moodScore: 3.2, lastUpdate: '2026-06-03 14:30', followUpCount: 3 })
    riskStudents.push({ studentId: 'S003', name: '李雨涵', classId: classId, dormId: '5204', riskLevel: 3, moodScore: 1.8, lastUpdate: '2026-06-03 20:15', followUpCount: 5 })
    riskStudents.push({ studentId: 'S004', name: '王浩然', classId: classId, dormId: '5201', riskLevel: 2, moodScore: 2.5, lastUpdate: '2026-06-02 09:00', followUpCount: 2 })
    riskStudents.push({ studentId: 'S008', name: '赵文博', classId: classId, dormId: '5203', riskLevel: 1, moodScore: 4.6, lastUpdate: '2026-06-03 16:45', followUpCount: 1 })
    riskStudents.push({ studentId: 'S011', name: '陈思琪', classId: classId, dormId: '5204', riskLevel: 3, moodScore: 1.2, lastUpdate: '2026-06-03 22:00', followUpCount: 4 })
    riskStudents.push({ studentId: 'S015', name: '刘浩然', classId: classId, dormId: '5204', riskLevel: 2, moodScore: 2.8, lastUpdate: '2026-06-01 11:30', followUpCount: 2 })
    riskStudents.push({ studentId: 'S020', name: '周子涵', classId: classId, dormId: '5206', riskLevel: 1, moodScore: 5.1, lastUpdate: '2026-06-02 15:20', followUpCount: 1 })

    const result: ClassDetailResult = { dormList: dormList, riskStudents: riskStudents }
    return result
  }

  async fetchWarningEvents(): Promise<WarningEvent[]> {
    await delay(MOCK_DELAY)

    const result: WarningEvent[] = []
    result.push({ eventId: 'W001', studentId: 'S003', studentName: '李雨涵', eventType: '情绪异常', riskLevel: 3, timestamp: '2026-06-03 20:15', description: '连续7天情绪评分低于2.0，半月报可信度评分仅32分', status: 0 })
    result.push({ eventId: 'W002', studentId: 'S011', studentName: '陈思琪', eventType: '自伤风险', riskLevel: 3, timestamp: '2026-06-03 18:30', description: '近期提交的心事记录中包含多组风险关键词，需紧急干预', status: 0 })
    result.push({ eventId: 'W003', studentId: 'S001', studentName: '张小明', eventType: '社交孤立', riskLevel: 2, timestamp: '2026-06-02 09:00', description: '连续两周未参与任何社团活动，寝室室友反映交流减少', status: 1 })
    result.push({ eventId: 'W004', studentId: 'S004', studentName: '王浩然', eventType: '学业预警', riskLevel: 2, timestamp: '2026-06-02 10:30', description: '期中考试多门不及格，课堂出勤率下降至60%', status: 1 })
    result.push({ eventId: 'W005', studentId: 'S008', studentName: '赵文博', eventType: '情绪波动', riskLevel: 1, timestamp: '2026-06-01 14:00', description: '近三天情绪从7.2骤降至4.6，建议持续观察', status: 2 })
    return result
  }

  async fetchWarningTimeline(eventId: string): Promise<TimelineNode[]> {
    await delay(MOCK_DELAY)

    const result: TimelineNode[] = []
    result.push({ stepId: 'T1', stepName: 'AI系统预警', timestamp: '2026-06-03 20:15', handler: 'AI监测系统', result: '检测到异常情绪模式', isCompleted: true, isCurrent: false })
    result.push({ stepId: 'T2', stepName: '辅导员确认', timestamp: '2026-06-03 20:30', handler: '王老师', result: '确认为高风险事件', isCompleted: true, isCurrent: false })
    result.push({ stepId: 'T3', stepName: '启动干预', timestamp: '2026-06-03 21:00', handler: '心理咨询中心', result: '安排紧急咨询', isCompleted: true, isCurrent: false })
    result.push({ stepId: 'T4', stepName: '家校沟通', timestamp: '2026-06-04 09:00', handler: '王老师', result: '已联系家长', isCompleted: false, isCurrent: true })
    result.push({ stepId: 'T5', stepName: '持续跟踪', timestamp: '', handler: '王老师', result: '等待中', isCompleted: false, isCurrent: false })
    result.push({ stepId: 'T6', stepName: '结案评估', timestamp: '', handler: '心理咨询中心', result: '等待中', isCompleted: false, isCurrent: false })
    return result
  }

  async updateWarningStatus(eventId: string, newStatus: number): Promise<boolean> {
    await delay(MOCK_DELAY)
    return true
  }
}

export interface ClassDetailResult {
  dormList: DormHeatData[]
  riskStudents: RiskStudent[]
}
