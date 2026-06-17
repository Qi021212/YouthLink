export enum CallStatus {
  ONGOING = 0,
  COMPLETED = 1,
  MISSED = 2
}

export enum RiskLevel {
  LOW = 0,
  MEDIUM = 1,
  HIGH = 2,
  CRITICAL = 3
}

export enum WorkOrderStatus {
  PENDING = 0,
  PROCESSING = 1,
  COMPLETED = 2,
  CLOSED = 3
}

export enum AppointmentStatus {
  BOOKED = 0,
  IN_PROGRESS = 1,
  COMPLETED = 2,
  CANCELLED = 3
}

export enum FollowUpPriority {
  NORMAL = 0,
  URGENT = 1
}

export enum ActivityStatus {
  DRAFT = 0,
  APPROVED = 1,
  IN_PROGRESS = 2,
  COMPLETED = 3
}

export class HotlineCall {
  callId: string = ''
  callerName: string = ''
  callerStudentId: string = ''
  phoneNumber: string = ''
  startTime: string = ''
  duration: number = 0
  status: CallStatus = CallStatus.ONGOING
  riskLevel: RiskLevel = RiskLevel.LOW
  tags: string[] = []
  aiSummary: string = ''

  static of(data: HotlineCall): HotlineCall {
    const c = new HotlineCall()
    c.callId = data.callId
    c.callerName = data.callerName
    c.callerStudentId = data.callerStudentId
    c.phoneNumber = data.phoneNumber
    c.startTime = data.startTime
    c.duration = data.duration
    c.status = data.status
    c.riskLevel = data.riskLevel
    c.tags = data.tags
    c.aiSummary = data.aiSummary
    return c
  }
}

export class WorkOrder {
  orderId: string = ''
  relatedCallId: string = ''
  studentName: string = ''
  studentId: string = ''
  type: string = ''
  description: string = ''
  status: WorkOrderStatus = WorkOrderStatus.PENDING
  assignedTo: string = ''
  createdAt: string = ''
  updatedAt: string = ''
  riskLevel: RiskLevel = RiskLevel.LOW

  static of(data: WorkOrder): WorkOrder {
    const o = new WorkOrder()
    o.orderId = data.orderId
    o.relatedCallId = data.relatedCallId
    o.studentName = data.studentName
    o.studentId = data.studentId
    o.type = data.type
    o.description = data.description
    o.status = data.status
    o.assignedTo = data.assignedTo
    o.createdAt = data.createdAt
    o.updatedAt = data.updatedAt
    o.riskLevel = data.riskLevel
    return o
  }
}

export class OrderTimelineNode {
  nodeId: string = ''
  orderId: string = ''
  time: string = ''
  action: string = ''
  operator: string = ''
  remark: string = ''

  static of(data: OrderTimelineNode): OrderTimelineNode {
    const n = new OrderTimelineNode()
    n.nodeId = data.nodeId
    n.orderId = data.orderId
    n.time = data.time
    n.action = data.action
    n.operator = data.operator
    n.remark = data.remark
    return n
  }
}

export class Appointment {
  appointmentId: string = ''
  studentName: string = ''
  studentId: string = ''
  counselor: string = ''
  date: string = ''
  timeSlot: string = ''
  reason: string = ''
  status: AppointmentStatus = AppointmentStatus.BOOKED

  static of(data: Appointment): Appointment {
    const a = new Appointment()
    a.appointmentId = data.appointmentId
    a.studentName = data.studentName
    a.studentId = data.studentId
    a.counselor = data.counselor
    a.date = data.date
    a.timeSlot = data.timeSlot
    a.reason = data.reason
    a.status = data.status
    return a
  }
}

export class ScheduleSlot {
  date: string = ''
  timeRange: string = ''
  counselor: string = ''
  isBooked: boolean = false
  studentName: string = ''

  static of(data: ScheduleSlot): ScheduleSlot {
    const s = new ScheduleSlot()
    s.date = data.date
    s.timeRange = data.timeRange
    s.counselor = data.counselor
    s.isBooked = data.isBooked
    s.studentName = data.studentName
    return s
  }
}

export class VisitRecord {
  recordId: string = ''
  studentName: string = ''
  studentId: string = ''
  counselor: string = ''
  visitDate: string = ''
  type: string = ''
  summary: string = ''
  riskLevel: RiskLevel = RiskLevel.LOW
  nextPlan: string = ''

  static of(data: VisitRecord): VisitRecord {
    const r = new VisitRecord()
    r.recordId = data.recordId
    r.studentName = data.studentName
    r.studentId = data.studentId
    r.counselor = data.counselor
    r.visitDate = data.visitDate
    r.type = data.type
    r.summary = data.summary
    r.riskLevel = data.riskLevel
    r.nextPlan = data.nextPlan
    return r
  }
}

export class FollowUpTask {
  taskId: string = ''
  studentName: string = ''
  studentId: string = ''
  reason: string = ''
  deadline: string = ''
  priority: FollowUpPriority = FollowUpPriority.NORMAL
  completed: boolean = false
  riskLevel: RiskLevel = RiskLevel.HIGH

  static of(data: FollowUpTask): FollowUpTask {
    const t = new FollowUpTask()
    t.taskId = data.taskId
    t.studentName = data.studentName
    t.studentId = data.studentId
    t.reason = data.reason
    t.deadline = data.deadline
    t.priority = data.priority
    t.completed = data.completed
    t.riskLevel = data.riskLevel
    return t
  }
}

export class Activity {
  activityId: string = ''
  title: string = ''
  type: string = ''
  description: string = ''
  status: ActivityStatus = ActivityStatus.DRAFT
  startDate: string = ''
  endDate: string = ''
  organizer: string = ''
  participants: number = 0
  satisfaction: number = 0

  static of(data: Activity): Activity {
    const a = new Activity()
    a.activityId = data.activityId
    a.title = data.title
    a.type = data.type
    a.description = data.description
    a.status = data.status
    a.startDate = data.startDate
    a.endDate = data.endDate
    a.organizer = data.organizer
    a.participants = data.participants
    a.satisfaction = data.satisfaction
    return a
  }
}

export class EfficiencyReport {
  totalParticipants: number = 0
  avgSatisfaction: number = 0
  completionRate: number = 0
  recommendationRate: number = 0
  peakIndex: number = 0
  createdAt: string = ''
  activityId: string = ''

  static of(data: EfficiencyReport): EfficiencyReport {
    const r = new EfficiencyReport()
    r.totalParticipants = data.totalParticipants
    r.avgSatisfaction = data.avgSatisfaction
    r.completionRate = data.completionRate
    r.recommendationRate = data.recommendationRate
    r.peakIndex = data.peakIndex
    r.createdAt = data.createdAt
    r.activityId = data.activityId
    return r
  }
}

export class DashboardSummary {
  activeCalls: number = 0
  pendingOrders: number = 0
  todayAppointments: number = 0
  uncompletedFollowUps: number = 0
  totalStudents: number = 0
  riskDistribution: number[] = [0, 0, 0, 0]

  static of(data: DashboardSummary): DashboardSummary {
    const d = new DashboardSummary()
    d.activeCalls = data.activeCalls
    d.pendingOrders = data.pendingOrders
    d.todayAppointments = data.todayAppointments
    d.uncompletedFollowUps = data.uncompletedFollowUps
    d.totalStudents = data.totalStudents
    d.riskDistribution = data.riskDistribution
    return d
  }
}
