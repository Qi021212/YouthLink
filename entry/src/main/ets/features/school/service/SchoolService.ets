import {
  HotlineCall, CallStatus, RiskLevel,
  WorkOrder, WorkOrderStatus, OrderTimelineNode,
  Appointment, AppointmentStatus,
  ScheduleSlot,
  VisitRecord,
  FollowUpTask, FollowUpPriority,
  Activity, ActivityStatus,
  EfficiencyReport,
  DashboardSummary
} from '../model/SchoolModels'

export class SchoolService {
  private activeCalls: HotlineCall[] = [
    HotlineCall.of({
      callId: 'CALL-001',
      callerName: '张三',
      callerStudentId: '2021001',
      phoneNumber: '138****5678',
      startTime: '2025-01-15 14:30',
      duration: 680,
      status: CallStatus.ONGOING,
      riskLevel: RiskLevel.HIGH,
      tags: ['焦虑', '学业压力'],
      aiSummary: '来电者反映近期学业压力大，出现失眠、焦虑症状，建议安排面对面咨询。'
    }),
    HotlineCall.of({
      callId: 'CALL-002',
      callerName: '李四',
      callerStudentId: '2021002',
      phoneNumber: '139****1234',
      startTime: '2025-01-15 15:10',
      duration: 320,
      status: CallStatus.COMPLETED,
      riskLevel: RiskLevel.MEDIUM,
      tags: ['人际关系'],
      aiSummary: '咨询寝室人际关系问题，已给予初步建议并安排后续咨询。'
    })
  ]

  async fetchActiveCalls(): Promise<HotlineCall[]> {
    return this.activeCalls
  }

  async fetchWorkOrders(): Promise<WorkOrder[]> {
    const orders: WorkOrder[] = []
    const o1: WorkOrder = new WorkOrder()
    o1.orderId = 'WO-001'
    o1.relatedCallId = 'CALL-001'
    o1.studentName = '张三'
    o1.studentId = '2021001'
    o1.type = '危机干预'
    o1.description = '学生来电反映有自伤念头，已启动紧急干预流程'
    o1.status = WorkOrderStatus.PROCESSING
    o1.assignedTo = '王咨询师'
    o1.createdAt = '2025-01-15 14:40'
    o1.updatedAt = '2025-01-15 15:00'
    o1.riskLevel = RiskLevel.CRITICAL
    orders.push(o1)

    const o2: WorkOrder = new WorkOrder()
    o2.orderId = 'WO-002'
    o2.studentName = '王五'
    o2.studentId = '2021003'
    o2.type = '日常咨询'
    o2.description = '学业规划困惑，需要职业发展指导'
    o2.status = WorkOrderStatus.PENDING
    o2.assignedTo = ''
    o2.createdAt = '2025-01-15 10:00'
    o2.updatedAt = '2025-01-15 10:00'
    o2.riskLevel = RiskLevel.LOW
    orders.push(o2)

    const o3: WorkOrder = new WorkOrder()
    o3.orderId = 'WO-003'
    o3.studentName = '赵六'
    o3.studentId = '2021004'
    o3.type = '情绪疏导'
    o3.description = '考试失利情绪低落，需要心理疏导'
    o3.status = WorkOrderStatus.COMPLETED
    o3.assignedTo = '李咨询师'
    o3.createdAt = '2025-01-14 09:00'
    o3.updatedAt = '2025-01-14 17:00'
    o3.riskLevel = RiskLevel.MEDIUM
    orders.push(o3)

    return orders
  }

  async fetchOrderTimeline(orderId: string): Promise<OrderTimelineNode[]> {
    const timeline: OrderTimelineNode[] = []
    const n1: OrderTimelineNode = new OrderTimelineNode()
    n1.nodeId = 'TL-001'
    n1.orderId = orderId
    n1.time = '2025-01-15 14:40'
    n1.action = '创建工单'
    n1.operator = '系统'
    n1.remark = '根据CALL-001自动创建'
    timeline.push(n1)

    const n2: OrderTimelineNode = new OrderTimelineNode()
    n2.nodeId = 'TL-002'
    n2.orderId = orderId
    n2.time = '2025-01-15 14:45'
    n2.action = '分配咨询师'
    n2.operator = '管理员'
    n2.remark = '分配给王咨询师'
    timeline.push(n2)

    const n3: OrderTimelineNode = new OrderTimelineNode()
    n3.nodeId = 'TL-003'
    n3.orderId = orderId
    n3.time = '2025-01-15 15:00'
    n3.action = '咨询师接收'
    n3.operator = '王咨询师'
    n3.remark = '已开始处理'
    timeline.push(n3)

    return timeline
  }

  async fetchTodayAppointments(): Promise<Appointment[]> {
    const appointments: Appointment[] = []
    const a1: Appointment = new Appointment()
    a1.appointmentId = 'APT-001'
    a1.studentName = '张三'
    a1.studentId = '2021001'
    a1.counselor = '王咨询师'
    a1.date = '2025-01-15'
    a1.timeSlot = '09:00-09:50'
    a1.reason = '焦虑情绪咨询'
    a1.status = AppointmentStatus.BOOKED
    appointments.push(a1)

    const a2: Appointment = new Appointment()
    a2.appointmentId = 'APT-002'
    a2.studentName = '李四'
    a2.studentId = '2021002'
    a2.counselor = '张咨询师'
    a2.date = '2025-01-15'
    a2.timeSlot = '10:00-10:50'
    a2.reason = '人际关系咨询'
    a2.status = AppointmentStatus.IN_PROGRESS
    appointments.push(a2)

    return appointments
  }

  async fetchWeekSchedule(): Promise<ScheduleSlot[]> {
    const slots: ScheduleSlot[] = []
    const dates: string[] = ['01-13', '01-14', '01-15', '01-16', '01-17']
    const times: string[] = ['09:00-09:50', '10:00-10:50', '14:00-14:50', '15:00-15:50']
    const counselors: string[] = ['王咨询师', '张咨询师', '李咨询师']
    let slotIdx: number = 0
    for (let di: number = 0; di < dates.length; di++) {
      for (let ti: number = 0; ti < times.length; ti++) {
        const s: ScheduleSlot = new ScheduleSlot()
        s.date = dates[di]
        s.timeRange = times[ti]
        s.counselor = counselors[(di * times.length + ti) % counselors.length]
        if (slotIdx === 2 || slotIdx === 7) {
          s.isBooked = true
          s.studentName = slotIdx === 2 ? '张三' : '李四'
        } else {
          s.isBooked = false
        }
        slots.push(s)
        slotIdx++
      }
    }
    return slots
  }

  async fetchVisitRecords(): Promise<VisitRecord[]> {
    const records: VisitRecord[] = []
    const r1: VisitRecord = new VisitRecord()
    r1.recordId = 'VR-001'
    r1.studentName = '张三'
    r1.studentId = '2021001'
    r1.counselor = '王咨询师'
    r1.visitDate = '2025-01-15 14:00'
    r1.type = '初次面询'
    r1.summary = '学生表现出明显的焦虑症状，已建立初步信任关系，约定下周复诊'
    r1.riskLevel = RiskLevel.HIGH
    r1.nextPlan = '下周安排第二次面询，评估是否需要转介精神科'
    records.push(r1)

    const r2: VisitRecord = new VisitRecord()
    r2.recordId = 'VR-002'
    r2.studentName = '王五'
    r2.studentId = '2021003'
    r2.counselor = '张咨询师'
    r2.visitDate = '2025-01-14 10:00'
    r2.type = '回访复诊'
    r2.summary = '情绪状态较上次有明显改善，继续执行现有干预计划'
    r2.riskLevel = RiskLevel.LOW
    r2.nextPlan = '两周后回访'
    records.push(r2)

    return records
  }

  async fetchFollowUpTasks(): Promise<FollowUpTask[]> {
    const tasks: FollowUpTask[] = []
    const t1: FollowUpTask = new FollowUpTask()
    t1.taskId = 'FU-001'
    t1.studentName = '张三'
    t1.studentId = '2021001'
    t1.reason = '高危预警 - 自伤风险评估'
    t1.deadline = '2025-01-16'
    t1.priority = FollowUpPriority.URGENT
    t1.completed = false
    t1.riskLevel = RiskLevel.CRITICAL
    tasks.push(t1)

    const t2: FollowUpTask = new FollowUpTask()
    t2.taskId = 'FU-002'
    t2.studentName = '赵六'
    t2.studentId = '2021004'
    t2.reason = '抑郁情绪评估跟进'
    t2.deadline = '2025-01-18'
    t2.priority = FollowUpPriority.URGENT
    t2.completed = false
    t2.riskLevel = RiskLevel.HIGH
    tasks.push(t2)

    const t3: FollowUpTask = new FollowUpTask()
    t3.taskId = 'FU-003'
    t3.studentName = '孙七'
    t3.studentId = '2021005'
    t3.reason = '休学复学评估'
    t3.deadline = '2025-01-20'
    t3.priority = FollowUpPriority.NORMAL
    t3.completed = false
    t3.riskLevel = RiskLevel.MEDIUM
    tasks.push(t3)

    return tasks
  }

  async fetchActivities(): Promise<Activity[]> {
    const activities: Activity[] = []
    const a1: Activity = new Activity()
    a1.activityId = 'ACT-001'
    a1.title = '正念减压工作坊'
    a1.type = '团体辅导'
    a1.description = '为期四周的正念减压课程，帮助学生学习正念技巧应对压力'
    a1.status = ActivityStatus.IN_PROGRESS
    a1.startDate = '2025-01-10'
    a1.endDate = '2025-02-07'
    a1.organizer = '校级心理中心'
    a1.participants = 28
    a1.satisfaction = 4.5
    activities.push(a1)

    const a2: Activity = new Activity()
    a2.activityId = 'ACT-002'
    a2.title = '心理健康月开幕式'
    a2.type = '大型活动'
    a2.description = '年度心理健康月活动启动仪式，包括专家讲座和互动体验'
    a2.status = ActivityStatus.APPROVED
    a2.startDate = '2025-02-01'
    a2.endDate = '2025-02-01'
    a2.organizer = '学工部'
    a2.participants = 0
    a2.satisfaction = 0
    activities.push(a2)

    const a3: Activity = new Activity()
    a3.activityId = 'ACT-003'
    a3.title = '新生心理测评'
    a3.type = '测评筛查'
    a3.description = '2025级新生入学心理健康普查'
    a3.status = ActivityStatus.COMPLETED
    a3.startDate = '2024-09-15'
    a3.endDate = '2024-09-30'
    a3.organizer = '校级心理中心'
    a3.participants = 3500
    a3.satisfaction = 4.2
    activities.push(a3)

    const a4: Activity = new Activity()
    a4.activityId = 'ACT-004'
    a4.title = '寝室关系团体辅导'
    a4.type = '团体辅导'
    a4.description = '针对寝室矛盾进行团体辅导干预'
    a4.status = ActivityStatus.DRAFT
    a4.startDate = '2025-02-10'
    a4.endDate = '2025-02-28'
    a4.organizer = '校级心理中心'
    a4.participants = 0
    a4.satisfaction = 0
    activities.push(a4)

    return activities
  }

  async fetchEfficiencyReport(activityId: string): Promise<EfficiencyReport> {
    const report: EfficiencyReport = new EfficiencyReport()
    report.activityId = activityId
    report.totalParticipants = 28
    report.avgSatisfaction = 4.5
    report.completionRate = 0.92
    report.recommendationRate = 0.88
    report.peakIndex = 85
    report.createdAt = '2025-01-15'
    return report
  }

  async fetchDashboardSummary(): Promise<DashboardSummary> {
    const summary: DashboardSummary = new DashboardSummary()
    summary.activeCalls = 1
    summary.pendingOrders = 1
    summary.todayAppointments = 2
    summary.uncompletedFollowUps = 3
    summary.totalStudents = 3500
    summary.riskDistribution = [2800, 450, 200, 50]
    return summary
  }
}
