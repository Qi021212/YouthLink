// features/counselor/service/CounselorService.ets

import { ClassHeatData, DormHeatData, RiskStudent } from '../model/RiskStudent'
import { TimelineNode, WarningEvent } from '../model/WarningEvent'

const MOCK_DELAY = 300

function delay(ms: number): Promise<void> {
  return new Promise((resolve: () => void) => setTimeout(resolve, ms))
}

// ===== 定义班级数据类 =====
class ClassStudentData {
  students: RiskStudent[]
  dorms: DormHeatData[]

  constructor(students: RiskStudent[], dorms: DormHeatData[]) {
    this.students = students
    this.dorms = dorms
  }
}

export class CounselorService {

  // ===== 获取热力图数据（班级概览） =====
  async fetchHeatmapData(): Promise<ClassHeatData[]> {
    await delay(MOCK_DELAY)

    const result: ClassHeatData[] = []
    result.push({ classId: 'C1', className: '计算机2401', riskLevel: 0, studentCount: 38, riskRatio: 5 })
    result.push({ classId: 'C2', className: '计算机2402', riskLevel: 1, studentCount: 36, riskRatio: 14 })
    result.push({ classId: 'C3', className: '软件2401', riskLevel: 2, studentCount: 40, riskRatio: 22 })
    result.push({ classId: 'C4', className: '软件2402', riskLevel: 0, studentCount: 35, riskRatio: 8 })
    result.push({ classId: 'C5', className: '网络2401', riskLevel: 3, studentCount: 32, riskRatio: 31 })
    result.push({ classId: 'C6', className: '网络2402', riskLevel: 1, studentCount: 37, riskRatio: 16 })
    return result
  }

  // ===== 获取班级详情（学生列表 + 宿舍列表） =====
  async fetchClassDetail(classId: string): Promise<ClassDetailResult> {
    await delay(MOCK_DELAY)

    let data: ClassStudentData

    if (classId === 'C1') {
      const students: RiskStudent[] = []
      students.push({
        studentId: 'S001',
        name: '张明',
        classId: 'C1',
        className: '计算机2401',
        dormId: 'D1',
        dormName: '5201',
        riskLevel: 0,
        moodScore: 7.5,
        lastUpdate: '2026-06-17 10:00',
        followUpCount: 0,
        phone: '138****0001',
        gender: '男'
      })
      students.push({
        studentId: 'S002',
        name: '李华',
        classId: 'C1',
        className: '计算机2401',
        dormId: 'D1',
        dormName: '5201',
        riskLevel: 0,
        moodScore: 8.2,
        lastUpdate: '2026-06-17 09:30',
        followUpCount: 0,
        phone: '138****0002',
        gender: '男'
      })
      students.push({
        studentId: 'S003',
        name: '王芳',
        classId: 'C1',
        className: '计算机2401',
        dormId: 'D2',
        dormName: '5202',
        riskLevel: 0,
        moodScore: 6.8,
        lastUpdate: '2026-06-16 16:00',
        followUpCount: 0,
        phone: '138****0003',
        gender: '女'
      })

      const dorms: DormHeatData[] = []
      dorms.push({ dormId: 'D1', dormName: '5201', riskLevel: 0, riskStudentIds: [] })
      dorms.push({ dormId: 'D2', dormName: '5202', riskLevel: 0, riskStudentIds: [] })

      data = new ClassStudentData(students, dorms)

    } else if (classId === 'C2') {
      const students: RiskStudent[] = []
      students.push({
        studentId: 'S004',
        name: '赵强',
        classId: 'C2',
        className: '计算机2402',
        dormId: 'D3',
        dormName: '5301',
        riskLevel: 1,
        moodScore: 5.3,
        lastUpdate: '2026-06-17 08:00',
        followUpCount: 1,
        phone: '138****0004',
        gender: '男'
      })
      students.push({
        studentId: 'S005',
        name: '孙丽',
        classId: 'C2',
        className: '计算机2402',
        dormId: 'D3',
        dormName: '5301',
        riskLevel: 0,
        moodScore: 7.1,
        lastUpdate: '2026-06-17 11:00',
        followUpCount: 0,
        phone: '138****0005',
        gender: '女'
      })
      students.push({
        studentId: 'S006',
        name: '周伟',
        classId: 'C2',
        className: '计算机2402',
        dormId: 'D4',
        dormName: '5302',
        riskLevel: 1,
        moodScore: 4.8,
        lastUpdate: '2026-06-16 14:30',
        followUpCount: 2,
        phone: '138****0006',
        gender: '男',
        riskReason: '近期情绪波动较大，需关注'
      })

      const dorms: DormHeatData[] = []
      dorms.push({ dormId: 'D3', dormName: '5301', riskLevel: 1, riskStudentIds: ['S004'] })
      dorms.push({ dormId: 'D4', dormName: '5302', riskLevel: 1, riskStudentIds: ['S006'] })

      data = new ClassStudentData(students, dorms)

    } else if (classId === 'C3') {
      const students: RiskStudent[] = []
      students.push({
        studentId: 'S007',
        name: '吴静',
        classId: 'C3',
        className: '软件2401',
        dormId: 'D5',
        dormName: '5401',
        riskLevel: 2,
        moodScore: 3.8,
        lastUpdate: '2026-06-17 07:30',
        followUpCount: 3,
        phone: '138****0007',
        gender: '女',
        riskReason: '学业压力大，出现焦虑症状'
      })
      students.push({
        studentId: 'S008',
        name: '郑浩',
        classId: 'C3',
        className: '软件2401',
        dormId: 'D5',
        dormName: '5401',
        riskLevel: 0,
        moodScore: 6.5,
        lastUpdate: '2026-06-16 18:00',
        followUpCount: 0,
        phone: '138****0008',
        gender: '男'
      })
      students.push({
        studentId: 'S009',
        name: '陈雪',
        classId: 'C3',
        className: '软件2401',
        dormId: 'D6',
        dormName: '5402',
        riskLevel: 2,
        moodScore: 2.9,
        lastUpdate: '2026-06-17 12:00',
        followUpCount: 4,
        phone: '138****0009',
        gender: '女',
        riskReason: '人际关系紧张，需心理干预'
      })

      const dorms: DormHeatData[] = []
      dorms.push({ dormId: 'D5', dormName: '5401', riskLevel: 2, riskStudentIds: ['S007'] })
      dorms.push({ dormId: 'D6', dormName: '5402', riskLevel: 2, riskStudentIds: ['S009'] })

      data = new ClassStudentData(students, dorms)

    } else if (classId === 'C4') {
      const students: RiskStudent[] = []
      students.push({
        studentId: 'S010',
        name: '林峰',
        classId: 'C4',
        className: '软件2402',
        dormId: 'D7',
        dormName: '5501',
        riskLevel: 0,
        moodScore: 7.8,
        lastUpdate: '2026-06-17 09:00',
        followUpCount: 0,
        phone: '138****0010',
        gender: '男'
      })
      students.push({
        studentId: 'S011',
        name: '黄蕾',
        classId: 'C4',
        className: '软件2402',
        dormId: 'D7',
        dormName: '5501',
        riskLevel: 0,
        moodScore: 8.5,
        lastUpdate: '2026-06-17 10:30',
        followUpCount: 0,
        phone: '138****0011',
        gender: '女'
      })

      const dorms: DormHeatData[] = []
      dorms.push({ dormId: 'D7', dormName: '5501', riskLevel: 0, riskStudentIds: [] })

      data = new ClassStudentData(students, dorms)

    } else if (classId === 'C5') {
      const students: RiskStudent[] = []
      students.push({
        studentId: 'S012',
        name: '马超',
        classId: 'C5',
        className: '网络2401',
        dormId: 'D8',
        dormName: '5601',
        riskLevel: 3,
        moodScore: 1.5,
        lastUpdate: '2026-06-17 06:00',
        followUpCount: 5,
        phone: '138****0012',
        gender: '男',
        riskReason: '自伤倾向，需紧急干预'
      })
      students.push({
        studentId: 'S013',
        name: '朱婷',
        classId: 'C5',
        className: '网络2401',
        dormId: 'D8',
        dormName: '5601',
        riskLevel: 3,
        moodScore: 1.9,
        lastUpdate: '2026-06-16 22:00',
        followUpCount: 4,
        phone: '138****0013',
        gender: '女',
        riskReason: '严重抑郁倾向，已联系家长'
      })
      students.push({
        studentId: 'S014',
        name: '许阳',
        classId: 'C5',
        className: '网络2401',
        dormId: 'D9',
        dormName: '5602',
        riskLevel: 0,
        moodScore: 6.2,
        lastUpdate: '2026-06-17 08:45',
        followUpCount: 0,
        phone: '138****0014',
        gender: '男'
      })

      const dorms: DormHeatData[] = []
      dorms.push({ dormId: 'D8', dormName: '5601', riskLevel: 3, riskStudentIds: ['S012', 'S013'] })
      dorms.push({ dormId: 'D9', dormName: '5602', riskLevel: 0, riskStudentIds: [] })

      data = new ClassStudentData(students, dorms)

    } else if (classId === 'C6') {
      const students: RiskStudent[] = []
      students.push({
        studentId: 'S015',
        name: '何欣',
        classId: 'C6',
        className: '网络2402',
        dormId: 'D10',
        dormName: '5701',
        riskLevel: 1,
        moodScore: 4.2,
        lastUpdate: '2026-06-17 11:30',
        followUpCount: 2,
        phone: '138****0015',
        gender: '女',
        riskReason: '家庭变故，情绪低落'
      })
      students.push({
        studentId: 'S016',
        name: '刘洋',
        classId: 'C6',
        className: '网络2402',
        dormId: 'D10',
        dormName: '5701',
        riskLevel: 1,
        moodScore: 4.6,
        lastUpdate: '2026-06-16 20:00',
        followUpCount: 1,
        phone: '138****0016',
        gender: '男'
      })
      students.push({
        studentId: 'S017',
        name: '杨雪',
        classId: 'C6',
        className: '网络2402',
        dormId: 'D11',
        dormName: '5702',
        riskLevel: 0,
        moodScore: 7.0,
        lastUpdate: '2026-06-17 13:00',
        followUpCount: 0,
        phone: '138****0017',
        gender: '女'
      })

      const dorms: DormHeatData[] = []
      dorms.push({ dormId: 'D10', dormName: '5701', riskLevel: 1, riskStudentIds: ['S015', 'S016'] })
      dorms.push({ dormId: 'D11', dormName: '5702', riskLevel: 0, riskStudentIds: [] })

      data = new ClassStudentData(students, dorms)

    } else {
      // 默认空数据
      data = new ClassStudentData([], [])
    }

    return {
      dormList: data.dorms,
      riskStudents: data.students
    }
  }

  // ===== 获取预警事件列表 =====
  async fetchWarningEvents(): Promise<WarningEvent[]> {
    await delay(MOCK_DELAY)

    const result: WarningEvent[] = []
    result.push({
      eventId: 'W001',
      studentId: 'S012',
      studentName: '马超',
      eventType: '自伤风险',
      riskLevel: 3,
      timestamp: '2026-06-17 06:00',
      description: '检测到自伤倾向关键词，需紧急干预',
      status: 0
    })
    result.push({
      eventId: 'W002',
      studentId: 'S013',
      studentName: '朱婷',
      eventType: '严重抑郁',
      riskLevel: 3,
      timestamp: '2026-06-16 22:00',
      description: '半月报可信度评分仅28分，情绪持续低迷',
      status: 0
    })
    result.push({
      eventId: 'W003',
      studentId: 'S007',
      studentName: '吴静',
      eventType: '学业焦虑',
      riskLevel: 2,
      timestamp: '2026-06-17 07:30',
      description: '期中考试挂科3门，出现严重焦虑症状',
      status: 1
    })
    result.push({
      eventId: 'W004',
      studentId: 'S009',
      studentName: '陈雪',
      eventType: '人际关系',
      riskLevel: 2,
      timestamp: '2026-06-17 12:00',
      description: '与室友发生冲突，已持续一周冷战',
      status: 1
    })
    result.push({
      eventId: 'W005',
      studentId: 'S006',
      studentName: '周伟',
      eventType: '情绪波动',
      riskLevel: 1,
      timestamp: '2026-06-16 14:30',
      description: '近三天情绪从7.8骤降至4.8',
      status: 2
    })
    return result
  }

  // ===== 获取预警时间线 =====
  async fetchWarningTimeline(eventId: string): Promise<TimelineNode[]> {
    await delay(MOCK_DELAY)

    const result: TimelineNode[] = []
    result.push({
      stepId: 'T1',
      stepName: 'AI系统预警',
      timestamp: '2026-06-17 06:00',
      handler: 'AI监测系统',
      result: '检测到异常行为',
      isCompleted: true,
      isCurrent: false
    })
    result.push({
      stepId: 'T2',
      stepName: '辅导员确认',
      timestamp: '2026-06-17 08:30',
      handler: '王老师',
      result: '确认为高风险事件',
      isCompleted: true,
      isCurrent: false
    })
    result.push({
      stepId: 'T3',
      stepName: '启动干预',
      timestamp: '2026-06-17 10:00',
      handler: '心理咨询中心',
      result: '已安排紧急面谈',
      isCompleted: true,
      isCurrent: false
    })
    result.push({
      stepId: 'T4',
      stepName: '家校沟通',
      timestamp: '2026-06-17 14:00',
      handler: '王老师',
      result: '等待家长反馈',
      isCompleted: false,
      isCurrent: true
    })
    result.push({
      stepId: 'T5',
      stepName: '持续跟踪',
      timestamp: '',
      handler: '王老师',
      result: '等待中',
      isCompleted: false,
      isCurrent: false
    })
    result.push({
      stepId: 'T6',
      stepName: '结案评估',
      timestamp: '',
      handler: '心理咨询中心',
      result: '等待中',
      isCompleted: false,
      isCurrent: false
    })
    return result
  }

  // ===== 更新预警状态 =====
  async updateWarningStatus(eventId: string, newStatus: number): Promise<boolean> {
    await delay(MOCK_DELAY)
    console.info(`[CounselorService] 更新预警状态: ${eventId} -> ${newStatus}`)
    return true
  }
}

export interface ClassDetailResult {
  dormList: DormHeatData[]
  riskStudents: RiskStudent[]
}

export default CounselorService