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

  // ===== 生成真实中文姓名 =====
  private getRealName(isMale: boolean, index: number): string {
    const surnames = ['赵','钱','孙','李','周','吴','郑','王','冯','陈','褚','卫','蒋','沈','韩','杨','朱','秦','尤','许','何','吕','施','张','孔','曹','严','华','金','魏','陶','姜','戚','谢','邹','喻','柏','水','窦','章','云','苏','潘','葛','奚','范','彭','郎']
    const maleNames = ['伟','强','磊','超','杰','涛','鹏','辉','飞','明','洋','勇','平','刚','波','峰','军','健','凯','浩','俊','智','宇','斌','震','东','宁','龙','达','翔']
    const femaleNames = ['芳','静','雪','婷','欣','丽','梅','敏','秀','英','娟','琴','兰','燕','佳','蓉','丹','萍','玲','芬','倩','欣','颖','悦','琪','瑶','怡','倩','欢','露']
    
    const surname = surnames[index % surnames.length]
    const name = isMale ? maleNames[index % maleNames.length] : femaleNames[index % femaleNames.length]
    return surname + name
  }

  // ===== 获取热力图数据（班级概览） =====
  async fetchHeatmapData(): Promise<ClassHeatData[]> {
    await delay(MOCK_DELAY)
    const result: ClassHeatData[] = []
    result.push({ classId: 'C1', className: '计算机2401', riskLevel: 0, studentCount: 32, riskRatio: 5 })
    result.push({ classId: 'C2', className: '计算机2402', riskLevel: 1, studentCount: 32, riskRatio: 14 })
    result.push({ classId: 'C3', className: '软件2401', riskLevel: 2, studentCount: 32, riskRatio: 22 })
    result.push({ classId: 'C4', className: '软件2402', riskLevel: 0, studentCount: 32, riskRatio: 8 })
    result.push({ classId: 'C5', className: '网络2401', riskLevel: 3, studentCount: 32, riskRatio: 31 })
    result.push({ classId: 'C6', className: '网络2402', riskLevel: 1, studentCount: 32, riskRatio: 16 })
    return result
  }

  // ===== 动态生成全班32名学生和8个寝室的数据 =====
  private generateClassData(classId: string, className: string, riskStudents: RiskStudent[]): ClassStudentData {
    const classNum = classId.replace('C', '')
    const dormPrefix = `5${classNum}`
    const dorms: DormHeatData[] = []
    const allStudents: RiskStudent[] = [...riskStudents]

    // Initialize 8 dorms (4 male: 01-04, 4 female: 05-08)
    for (let i = 1; i <= 8; i++) {
      const isMale = i <= 4
      const dormName = `${dormPrefix}0${i}`
      const genderStr = isMale ? 'Male' : 'Female'
      
      const dormStudents = allStudents.filter(s => s.dormName === dormName)
      const beds = [0, 0, 0, 0]
      let maxRisk = 0
      
      for (let j = 0; j < 4; j++) {
        if (j < dormStudents.length) {
          beds[j] = dormStudents[j].riskLevel
          if (beds[j] > maxRisk) maxRisk = beds[j]
        } else {
          // Add a safe student with a realistic name
          const newStudent: RiskStudent = {
            studentId: `${classId}_${dormName}_${j}`,
            name: this.getRealName(isMale, classNum.charCodeAt(0) * 10 + i * 4 + j),
            classId: classId,
            className: className,
            dormId: `${classId}_D${i}`,
            dormName: dormName,
            riskLevel: 0,
            moodScore: 7.5 + (j * 0.2),
            lastUpdate: '2026-06-17 12:00',
            followUpCount: 0,
            phone: `138${i}${j}000000`,
            gender: isMale ? '男' : '女'
          }
          allStudents.push(newStudent)
          beds[j] = 0
        }
      }
      
      dorms.push({
        dormId: `${classId}_D${i}`,
        dormName: dormName,
        riskLevel: maxRisk,
        riskStudentIds: allStudents.filter(s => s.dormName === dormName).map(s => s.studentId),
        gender: genderStr as 'Male' | 'Female',
        beds: beds
      })
    }

    return new ClassStudentData(allStudents, dorms)
  }

  // ===== 获取班级详情（学生列表 + 宿舍列表） =====
  async fetchClassDetail(classId: string): Promise<ClassDetailResult> {
    await delay(MOCK_DELAY)
    let data: ClassStudentData
    
    if (classId === 'C1' || classId === '计算机2401') {
      const students: RiskStudent[] = []
      students.push({ studentId: 'S001', name: '张明', classId: 'C1', className: '计算机2401', dormId: 'C1_D1', dormName: '5101', riskLevel: 0, moodScore: 7.5, lastUpdate: '2026-06-17 10:00', followUpCount: 0, phone: '138****0001', gender: '男' })
      students.push({ studentId: 'S002', name: '李华', classId: 'C1', className: '计算机2401', dormId: 'C1_D1', dormName: '5101', riskLevel: 0, moodScore: 8.2, lastUpdate: '2026-06-17 09:30', followUpCount: 0, phone: '138****0002', gender: '男' })
      students.push({ studentId: 'S003', name: '王芳', classId: 'C1', className: '计算机2401', dormId: 'C1_D5', dormName: '5105', riskLevel: 0, moodScore: 6.8, lastUpdate: '2026-06-16 16:00', followUpCount: 0, phone: '138****0003', gender: '女' })
      data = this.generateClassData('C1', '计算机2401', students)
    } else if (classId === 'C2' || classId === '计算机2402') {
      const students: RiskStudent[] = []
      students.push({ studentId: 'S004', name: '赵强', classId: 'C2', className: '计算机2402', dormId: 'C2_D1', dormName: '5201', riskLevel: 1, moodScore: 5.3, lastUpdate: '2026-06-17 08:00', followUpCount: 1, phone: '138****0004', gender: '男' })
      students.push({ studentId: 'S005', name: '孙丽', classId: 'C2', className: '计算机2402', dormId: 'C2_D5', dormName: '5205', riskLevel: 0, moodScore: 7.1, lastUpdate: '2026-06-17 11:00', followUpCount: 0, phone: '138****0005', gender: '女' })
      students.push({ studentId: 'S006', name: '周伟', classId: 'C2', className: '计算机2402', dormId: 'C2_D2', dormName: '5202', riskLevel: 1, moodScore: 4.8, lastUpdate: '2026-06-16 14:30', followUpCount: 2, phone: '138****0006', gender: '男', riskReason: '近期情绪波动较大，需关注' })
      data = this.generateClassData('C2', '计算机2402', students)
    } else if (classId === 'C3' || classId === '软件2401') {
      const students: RiskStudent[] = []
      students.push({ studentId: 'S007', name: '吴静', classId: 'C3', className: '软件2401', dormId: 'C3_D5', dormName: '5305', riskLevel: 2, moodScore: 3.8, lastUpdate: '2026-06-17 07:30', followUpCount: 3, phone: '138****0007', gender: '女', riskReason: '学业压力大，出现焦虑症状' })
      students.push({ studentId: 'S008', name: '郑浩', classId: 'C3', className: '软件2401', dormId: 'C3_D1', dormName: '5301', riskLevel: 0, moodScore: 6.5, lastUpdate: '2026-06-16 18:00', followUpCount: 0, phone: '138****0008', gender: '男' })
      students.push({ studentId: 'S009', name: '陈雪', classId: 'C3', className: '软件2401', dormId: 'C3_D6', dormName: '5306', riskLevel: 2, moodScore: 2.9, lastUpdate: '2026-06-17 12:00', followUpCount: 4, phone: '138****0009', gender: '女', riskReason: '人际关系紧张，需心理干预' })
      data = this.generateClassData('C3', '软件2401', students)
    } else if (classId === 'C4' || classId === '软件2402') {
      const students: RiskStudent[] = []
      students.push({ studentId: 'S010', name: '林峰', classId: 'C4', className: '软件2402', dormId: 'C4_D1', dormName: '5401', riskLevel: 0, moodScore: 7.8, lastUpdate: '2026-06-17 09:00', followUpCount: 0, phone: '138****0010', gender: '男' })
      students.push({ studentId: 'S011', name: '黄蕾', classId: 'C4', className: '软件2402', dormId: 'C4_D5', dormName: '5405', riskLevel: 0, moodScore: 8.5, lastUpdate: '2026-06-17 10:30', followUpCount: 0, phone: '138****0011', gender: '女' })
      data = this.generateClassData('C4', '软件2402', students)
    } else if (classId === 'C5' || classId === '网络2401') {
      const students: RiskStudent[] = []
      students.push({ studentId: 'S012', name: '马超', classId: 'C5', className: '网络2401', dormId: 'C5_D1', dormName: '5501', riskLevel: 3, moodScore: 1.5, lastUpdate: '2026-06-17 06:00', followUpCount: 5, phone: '138****0012', gender: '男', riskReason: '自伤倾向，需紧急干预' })
      students.push({ studentId: 'S013', name: '朱婷', classId: 'C5', className: '网络2401', dormId: 'C5_D5', dormName: '5505', riskLevel: 3, moodScore: 1.9, lastUpdate: '2026-06-16 22:00', followUpCount: 4, phone: '138****0013', gender: '女', riskReason: '严重抑郁倾向，已联系家长' })
      students.push({ studentId: 'S014', name: '许阳', classId: 'C5', className: '网络2401', dormId: 'C5_D2', dormName: '5502', riskLevel: 0, moodScore: 6.2, lastUpdate: '2026-06-17 08:45', followUpCount: 0, phone: '138****0014', gender: '男' })
      data = this.generateClassData('C5', '网络2401', students)
    } else if (classId === 'C6' || classId === '网络2402') {
      const students: RiskStudent[] = []
      students.push({ studentId: 'S015', name: '何欣', classId: 'C6', className: '网络2402', dormId: 'C6_D5', dormName: '5605', riskLevel: 1, moodScore: 4.2, lastUpdate: '2026-06-17 11:30', followUpCount: 2, phone: '138****0015', gender: '女', riskReason: '家庭变故，情绪低落' })
      students.push({ studentId: 'S016', name: '刘洋', classId: 'C6', className: '网络2402', dormId: 'C6_D1', dormName: '5601', riskLevel: 1, moodScore: 4.6, lastUpdate: '2026-06-16 20:00', followUpCount: 1, phone: '138****0016', gender: '男' })
      students.push({ studentId: 'S017', name: '杨雪', classId: 'C6', className: '网络2402', dormId: 'C6_D6', dormName: '5606', riskLevel: 0, moodScore: 7.0, lastUpdate: '2026-06-17 13:00', followUpCount: 0, phone: '138****0017', gender: '女' })
      data = this.generateClassData('C6', '网络2402', students)
    } else {
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

    const events = await this.fetchWarningEvents()
    const event = events.find(e => e.eventId === eventId)
    const status = event ? event.status : 0

    let currentStepIndex = 2 // 待处理
    if (status === 1) currentStepIndex = 3 // 处理中
    if (status === 2) currentStepIndex = 6 // 已结案

    const result: TimelineNode[] = []

    const createNode = (index: number, stepId: string, stepName: string, defaultTs: string, handler: string, defaultRes: string): TimelineNode => {
      let isCompleted = index < currentStepIndex
      let isCurrent = index === currentStepIndex

      if (status === 2) {
        isCompleted = true
        isCurrent = false
      }

      let ts = defaultTs
      let res = defaultRes

      if (!isCompleted && !isCurrent) {
        ts = ''
        res = '等待中'
      }

      if (isCurrent && status !== 2) {
        if (index === 2) { res = '待安排面谈'; ts = '' }
        if (index === 3) { res = '等待家长反馈' }
        if (index === 4) { res = '跟踪进行中'; ts = '' }
        if (index === 5) { res = '待评估'; ts = '' }
      }

      let node: TimelineNode = {
        stepId: stepId,
        stepName: stepName,
        timestamp: ts,
        handler: handler,
        result: res,
        isCompleted: isCompleted,
        isCurrent: isCurrent
      }
      return node
    }

    result.push(createNode(0, 'T1', 'AI系统预警', '2026-06-17 06:00', 'AI监测系统', '检测到异常行为'))
    result.push(createNode(1, 'T2', '辅导员确认', '2026-06-17 08:30', '王老师', '确认为高风险事件'))
    result.push(createNode(2, 'T3', '启动干预', '2026-06-17 10:00', '心理咨询中心', '已安排紧急面谈'))
    result.push(createNode(3, 'T4', '家校沟通', '2026-06-17 14:00', '王老师', '家校已沟通'))
    result.push(createNode(4, 'T5', '持续跟踪', '2026-06-18 09:00', '王老师', '情况稳定'))
    result.push(createNode(5, 'T6', '结案评估', '2026-06-19 10:00', '心理咨询中心', '符合结案标准'))

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