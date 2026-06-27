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
import { common } from '@kit.AbilityKit'
import { DatabaseHelper, HotlineCallRow, WorkOrderRow } from '../../../common/utils/DatabaseHelper'
import { ActivityDBHelper, ActivityEditFields } from '../../../common/utils/ActivityDBHelper'
import { MentalActivity } from '../../student/model/Activity'
import { BookingService } from '../../student/service/BookingService'
import { BookingDTO } from '../../student/model/BookingModel'
import { ReportData } from '../../../common/model/ReportModel'
import { getString, putString } from '../../../common/utils/StorageUtil'
import { ActivityFeedbackStore, ActivityFeedback } from '../../../common/utils/ActivityFeedbackStore'

// 学校端自身可变状态的持久化 key（不污染学生端/教师端数据）
const FOLLOWUP_DONE_KEY: string = 'school_followup_done'
const ACTIVITY_STATUS_KEY: string = 'school_activity_status'

// 活动时间段解析结果（时间戳 + 原始文本）
interface TimeRange {
  start: number
  end: number
  startText: string
  endText: string
}

export class SchoolService {
  /* ==================== S1 热线通话 ==================== */
  async fetchActiveCalls(): Promise<HotlineCall[]> {
    const db = DatabaseHelper.getInstance()
    let rawCalls: HotlineCallRow[] = []
    try {
      rawCalls = await db.getActiveHotlineCalls()
    } catch (e) {
      console.error('Failed to get active calls from DB', e)
    }
    
    if (rawCalls.length === 0) {
      // 预置一些演示用的活跃通话数据到数据库
      await db.addHotlineCall('CALL-20250115-001', '陈思远', '2023010201', '138****6721', '2025-01-15 13:45', 845, CallStatus.ONGOING, RiskLevel.HIGH, ['自杀意念', '重度抑郁', '学业压力'], '来电者自述近两周持续失眠，频繁出现「活着没意思」的念头，昨天在宿舍阳台长时间站立发呆被室友发现。SDS量表58分，建议立即启动危机干预流程。')
      await db.addHotlineCall('CALL-20250115-002', '林小婉', '2024010503', '187****3459', '2025-01-15 14:20', 412, CallStatus.ONGOING, RiskLevel.MEDIUM, ['焦虑', '寝室矛盾'], '大一新生，因与室友作息不合引发冲突，近一周情绪低落、上课注意力不集中。正在进行情绪安抚并提供沟通技巧建议。')
      await db.addHotlineCall('CALL-20250115-003', '王浩宇', '2023010312', '159****8023', '2025-01-15 15:05', 328, CallStatus.ONGOING, RiskLevel.LOW, ['情感困扰', '学业规划'], '大三学生因感情分手导致近期成绩下滑，对未来就业方向感到迷茫。情绪稳定，正在给予情感支持。')
      await db.addHotlineCall('CALL-20250114-005', '匿名来电', '未登记', '176****0198', '2025-01-14 21:33', 920, CallStatus.ONGOING, RiskLevel.CRITICAL, ['自杀风险评估', '匿名求助'], '来电者拒绝透露身份，语速缓慢、多次停顿，提到「不想再拖累家人」。系统已标记极高风险，正在进行危机话术稳住对方。')
      
      try {
        const newCalls = await db.getActiveHotlineCalls()
        if (newCalls && newCalls.length > 0) {
          return newCalls.map((r: HotlineCallRow) => {
            const c = new HotlineCall()
            c.callId = r.callId
            c.callerName = r.callerName
            c.callerStudentId = r.callerStudentId
            c.phoneNumber = r.phoneNumber
            c.startTime = r.startTime
            c.duration = r.duration
            c.status = r.status
            c.riskLevel = r.riskLevel
            c.tags = r.tags
            c.aiSummary = r.aiSummary
            return c
          })
        }
      } catch (e) {
        console.error('Failed to get new calls', e)
      }

      // Fallback
      const c1 = new HotlineCall(); c1.callId='CALL-20250115-001'; c1.callerName='陈思远'; c1.callerStudentId='2023010201'; c1.phoneNumber='138****6721'; c1.startTime='2025-01-15 13:45'; c1.duration=845; c1.status=CallStatus.ONGOING; c1.riskLevel=RiskLevel.HIGH; c1.tags=['自杀意念', '重度抑郁', '学业压力']; c1.aiSummary='来电者自述近两周持续失眠，频繁出现「活着没意思」的念头，昨天在宿舍阳台长时间站立发呆被室友发现。SDS量表58分，建议立即启动危机干预流程。';
      const c2 = new HotlineCall(); c2.callId='CALL-20250115-002'; c2.callerName='林小婉'; c2.callerStudentId='2024010503'; c2.phoneNumber='187****3459'; c2.startTime='2025-01-15 14:20'; c2.duration=412; c2.status=CallStatus.ONGOING; c2.riskLevel=RiskLevel.MEDIUM; c2.tags=['焦虑', '寝室矛盾']; c2.aiSummary='大一新生，因与室友作息不合引发冲突，近一周情绪低落、上课注意力不集中。正在进行情绪安抚并提供沟通技巧建议。';
      const c3 = new HotlineCall(); c3.callId='CALL-20250115-003'; c3.callerName='王浩宇'; c3.callerStudentId='2023010312'; c3.phoneNumber='159****8023'; c3.startTime='2025-01-15 15:05'; c3.duration=328; c3.status=CallStatus.ONGOING; c3.riskLevel=RiskLevel.LOW; c3.tags=['情感困扰', '学业规划']; c3.aiSummary='大三学生因感情分手导致近期成绩下滑，对未来就业方向感到迷茫。情绪稳定，正在给予情感支持。';
      const c4 = new HotlineCall(); c4.callId='CALL-20250114-005'; c4.callerName='匿名来电'; c4.callerStudentId='未登记'; c4.phoneNumber='176****0198'; c4.startTime='2025-01-14 21:33'; c4.duration=920; c4.status=CallStatus.ONGOING; c4.riskLevel=RiskLevel.CRITICAL; c4.tags=['自杀风险评估', '匿名求助']; c4.aiSummary='来电者拒绝透露身份，语速缓慢、多次停顿，提到「不想再拖累家人」。系统已标记极高风险，正在进行危机话术稳住对方。';
      return [c1, c2, c3, c4]
    }

    return rawCalls.map((r: HotlineCallRow) => {
      const c = new HotlineCall()
      c.callId = r.callId
      c.callerName = r.callerName
      c.callerStudentId = r.callerStudentId
      c.phoneNumber = r.phoneNumber
      c.startTime = r.startTime
      c.duration = r.duration
      c.status = r.status
      c.riskLevel = r.riskLevel
      c.tags = r.tags
      c.aiSummary = r.aiSummary
      return c
    })
  }

  /* ==================== S2 工单管理 ==================== */
  /* ==================== S2 工单管理 ==================== */
  async fetchWorkOrders(): Promise<WorkOrder[]> {
    const db = DatabaseHelper.getInstance()
    let rawOrders: WorkOrderRow[] = []
    try {
      rawOrders = await db.getAllWorkOrders()
    } catch (e) {
      console.error('Failed to get work orders from DB', e)
    }
    
    if (rawOrders.length === 0) {
      // 预置假数据
      await db.addWorkOrder('WO-20250115-001', 'CALL-20250115-001', '陈思远', '2023010201', '危机干预', '学生来电暴露自杀意念，SDS评分58分，阳性质询后有短期自伤计划。心理咨询中心初步评估为重度抑郁发作，需要紧急精神科转诊和家长告知。', WorkOrderStatus.PROCESSING, '王明远 咨询师', '2025-01-15 14:00', RiskLevel.CRITICAL)
      await db.addWorkOrder('WO-20250115-002', '', '林小婉', '2024010503', '寝室调解', '大一新生因寝室作息冲突产生人际关系紧张，影响到学习状态。需要辅导员介入协调寝室问题，并安排适应性心理辅导。', WorkOrderStatus.PENDING, '', '2025-01-15 14:30', RiskLevel.MEDIUM)
      await db.addWorkOrder('WO-20250115-003', '', '周子涵', '2022010215', '情绪疏导', '大四学生因毕业论文进度滞后、秋招不顺利，出现焦虑躯体化症状（心悸、手抖），需要心理咨询和学业支持。', WorkOrderStatus.PENDING, '', '2025-01-15 10:15', RiskLevel.MEDIUM)
      await db.addWorkOrder('WO-20250114-004', 'CALL-20250114-005', '匿名来电', '待确认', '紧急协查', '昨日21:33分匿名高危来电中途断线，已通过技术手段缩小定位范围至南区宿舍楼群。需立即启动紧急响应：通知保卫处协助排查，联系对应辅导员逐一核实。', WorkOrderStatus.PROCESSING, '校级心理中心应急组', '2025-01-14 21:45', RiskLevel.CRITICAL)
      await db.addWorkOrder('WO-20250113-005', '', '刘雨晴', '2023010208', '学业支持', '学生因上学期挂科3门被列入学业预警名单，产生严重自我怀疑和逃避行为，已两周未去上课。需要联合辅导员和学业导师制定帮扶方案。', WorkOrderStatus.PROCESSING, '李梦 咨询师', '2025-01-13 09:00', RiskLevel.HIGH)
      await db.addWorkOrder('WO-20250110-006', '', '吴昊天', '2023010651', '家长沟通', '学生在校期间多次参与赌博游戏，已被学校给予严重警告处分。家长主动联系中心请求心理干预，评估是否存在成瘾倾向。', WorkOrderStatus.COMPLETED, '赵明辉 咨询师', '2025-01-10 14:00', RiskLevel.HIGH)
      
      try {
        const newOrders = await db.getAllWorkOrders()
        if (newOrders && newOrders.length > 0) {
          return newOrders.map((r: WorkOrderRow) => {
            const o = new WorkOrder()
            o.orderId = r.orderId
            o.relatedCallId = r.relatedCallId
            o.studentName = r.studentName
            o.studentId = r.studentId
            o.type = r.type
            o.description = r.description
            o.status = r.status
            o.assignedTo = r.assignedTo
            o.createdAt = r.createdAt
            o.updatedAt = r.updatedAt
            o.riskLevel = r.riskLevel
            return o
          })
        }
      } catch (e) {}

      // Fallback
      const o1 = new WorkOrder(); o1.orderId='WO-20250115-001'; o1.studentName='陈思远'; o1.studentId='2023010201'; o1.type='危机干预'; o1.description='学生来电暴露自杀意念...'; o1.status=WorkOrderStatus.PROCESSING; o1.assignedTo='王明远 咨询师'; o1.createdAt='2025-01-15 14:00'; o1.riskLevel=RiskLevel.CRITICAL;
      const o2 = new WorkOrder(); o2.orderId='WO-20250115-002'; o2.studentName='林小婉'; o2.studentId='2024010503'; o2.type='寝室调解'; o2.description='大一新生因寝室作息冲突...'; o2.status=WorkOrderStatus.PENDING; o2.assignedTo=''; o2.createdAt='2025-01-15 14:30'; o2.riskLevel=RiskLevel.MEDIUM;
      const o3 = new WorkOrder(); o3.orderId='WO-20250115-003'; o3.studentName='周子涵'; o3.studentId='2022010215'; o3.type='情绪疏导'; o3.description='大四学生因毕业论文进度滞后...'; o3.status=WorkOrderStatus.PENDING; o3.assignedTo=''; o3.createdAt='2025-01-15 10:15'; o3.riskLevel=RiskLevel.MEDIUM;
      const o4 = new WorkOrder(); o4.orderId='WO-20250114-004'; o4.studentName='匿名来电'; o4.studentId='待确认'; o4.type='紧急协查'; o4.description='昨日21:33分匿名高危来电...'; o4.status=WorkOrderStatus.PROCESSING; o4.assignedTo='校级心理中心应急组'; o4.createdAt='2025-01-14 21:45'; o4.riskLevel=RiskLevel.CRITICAL;
      const o5 = new WorkOrder(); o5.orderId='WO-20250113-005'; o5.studentName='刘雨晴'; o5.studentId='2023010208'; o5.type='学业支持'; o5.description='学生因上学期挂科3门被列入学业预警名单...'; o5.status=WorkOrderStatus.PROCESSING; o5.assignedTo='李梦 咨询师'; o5.createdAt='2025-01-13 09:00'; o5.riskLevel=RiskLevel.HIGH;
      const o6 = new WorkOrder(); o6.orderId='WO-20250110-006'; o6.studentName='吴昊天'; o6.studentId='2023010651'; o6.type='家长沟通'; o6.description='学生在校期间多次参与赌博游戏...'; o6.status=WorkOrderStatus.COMPLETED; o6.assignedTo='赵明辉 咨询师'; o6.createdAt='2025-01-10 14:00'; o6.riskLevel=RiskLevel.HIGH;
      return [o1, o2, o3, o4, o5, o6]
    }

    return rawOrders.map((r: WorkOrderRow) => {
      const o = new WorkOrder()
      o.orderId = r.orderId
      o.relatedCallId = r.relatedCallId
      o.studentName = r.studentName
      o.studentId = r.studentId
      o.type = r.type
      o.description = r.description
      o.status = r.status
      o.assignedTo = r.assignedTo
      o.createdAt = r.createdAt
      o.updatedAt = r.updatedAt
      o.riskLevel = r.riskLevel
      return o
    })
  }

  async fetchOrderTimeline(orderId: string): Promise<OrderTimelineNode[]> {
    const db = DatabaseHelper.getInstance()
    const row = await db.getWorkOrderById(orderId)
    const timeline: OrderTimelineNode[] = []
    
    if (!row) {
      return timeline
    }

    // 节点1：创建
    const n1 = new OrderTimelineNode()
    n1.nodeId = 'TL-' + orderId + '-1'
    n1.orderId = orderId
    n1.time = row.createdAt
    n1.action = '系统自动创建工单'
    n1.operator = 'AI系统 / 自动调度'
    n1.remark = '事件类型: ' + row.type
    timeline.push(n1)

    // 节点2：分配
    if (row.status >= WorkOrderStatus.PROCESSING || row.assignedTo) {
      const n2 = new OrderTimelineNode()
      n2.nodeId = 'TL-' + orderId + '-2'
      n2.orderId = orderId
      n2.time = row.updatedAt
      n2.action = '分配咨询师 / 处理中'
      n2.operator = row.assignedTo || '未知咨询师'
      n2.remark = '已开始跟进处理该工单'
      timeline.push(n2)
    }
    
    // 节点3：升级警告
    if (row.riskLevel === RiskLevel.CRITICAL) {
      const n3 = new OrderTimelineNode()
      n3.nodeId = 'TL-' + orderId + '-3'
      n3.orderId = orderId
      n3.time = row.updatedAt
      n3.action = '升级危险等级为【极危】'
      n3.operator = '系统预警 / 负责人'
      n3.remark = '已通知校级心理危机响应工作组介入！'
      timeline.push(n3)
    }

    // 节点4：完成
    if (row.status === WorkOrderStatus.COMPLETED) {
      const n4 = new OrderTimelineNode()
      n4.nodeId = 'TL-' + orderId + '-4'
      n4.orderId = orderId
      n4.time = row.updatedAt
      n4.action = '工单处理完成并结案'
      n4.operator = row.assignedTo || '系统'
      n4.remark = '事件已闭环，归档处理'
      timeline.push(n4)
    }

    return timeline
  }

  /* ==================== S3 预约排班 ==================== */
  async fetchTodayAppointments(): Promise<Appointment[]> {
    const appointments: Appointment[] = []

    const a1: Appointment = new Appointment()
    a1.appointmentId = 'APT-20250115-001'
    a1.studentName = '陈思远'
    a1.studentId = '2023010201'
    a1.counselor = '王明远'
    a1.date = '2025-01-15'
    a1.timeSlot = '08:30-09:20'
    a1.reason = '失眠焦虑，情绪低落两周以上'
    a1.status = AppointmentStatus.IN_PROGRESS
    appointments.push(a1)

    const a2: Appointment = new Appointment()
    a2.appointmentId = 'APT-20250115-002'
    a2.studentName = '林小婉'
    a2.studentId = '2024010503'
    a2.counselor = '李梦'
    a2.date = '2025-01-15'
    a2.timeSlot = '09:30-10:20'
    a2.reason = '寝室人际关系冲突，适应性咨询'
    a2.status = AppointmentStatus.BOOKED
    appointments.push(a2)

    const a3: Appointment = new Appointment()
    a3.appointmentId = 'APT-20250115-003'
    a3.studentName = '周子涵'
    a3.studentId = '2022010215'
    a3.counselor = '赵明辉'
    a3.date = '2025-01-15'
    a3.timeSlot = '10:30-11:20'
    a3.reason = '毕业论文焦虑 + 秋招压力综合咨询'
    a3.status = AppointmentStatus.BOOKED
    appointments.push(a3)

    const a4: Appointment = new Appointment()
    a4.appointmentId = 'APT-20250115-004'
    a4.studentName = '刘雨晴'
    a4.studentId = '2023010208'
    a4.counselor = '王明远'
    a4.date = '2025-01-15'
    a4.timeSlot = '14:00-14:50'
    a4.reason = '学业预警后心理评估与支持'
    a4.status = AppointmentStatus.BOOKED
    appointments.push(a4)

    const a5: Appointment = new Appointment()
    a5.appointmentId = 'APT-20250115-005'
    a5.studentName = '吴昊天'
    a5.studentId = '2023010651'
    a5.counselor = '赵明辉'
    a5.date = '2025-01-15'
    a5.timeSlot = '16:00-16:50'
    a5.reason = '行为成瘾倾向评估（家长请求）'
    a5.status = AppointmentStatus.BOOKED
    appointments.push(a5)

    return appointments
  }

  async fetchWeekSchedule(): Promise<ScheduleSlot[]> {
    const slots: ScheduleSlot[] = []
    const dates: string[] = ['01-13（一）', '01-14（二）', '01-15（三）', '01-16（四）', '01-17（五）']
    const times: string[] = ['08:30-09:20', '09:30-10:20', '10:30-11:20', '14:00-14:50', '15:00-15:50']
    const counselors: string[] = ['王明远', '李梦', '赵明辉', '王明远', '李梦']
    let slotIdx: number = 0
    for (let di: number = 0; di < dates.length; di++) {
      for (let ti: number = 0; ti < times.length; ti++) {
        const s: ScheduleSlot = new ScheduleSlot()
        s.date = dates[di]
        s.timeRange = times[ti]
        s.counselor = counselors[ti % counselors.length]
        const idx: number = di * times.length + ti
        if (idx === 0 || idx === 3 || idx === 7 || idx === 12 || idx === 18) {
          s.isBooked = true
          const studentNames: string[] = ['陈思远', '林小婉', '周子涵', '刘雨晴', '吴昊天']
          s.studentName = studentNames[idx % studentNames.length]
        }
        slots.push(s)
        slotIdx++
      }
    }
    return slots
  }

  /* ==================== S4 来访记录 ==================== */
  async fetchVisitRecords(): Promise<VisitRecord[]> {
    const records: VisitRecord[] = []

    const r1: VisitRecord = new VisitRecord()
    r1.recordId = 'VR-20250115-001'
    r1.studentName = '陈思远'
    r1.studentId = '2023010201'
    r1.counselor = '王明远'
    r1.visitDate = '2025-01-15 09:30'
    r1.type = '危机干预面询'
    r1.summary = '学生情绪低落，语速缓慢，存在明确的自杀意念（有计划但无具体日期）。SDS量表再测56分，存在中度以上抑郁。家庭背景：父母离异，随母生活，母亲常年在外务工。已启动安全计划，与辅导员沟通安排宿舍密切观察。'
    r1.riskLevel = RiskLevel.CRITICAL
    r1.nextPlan = '1.每日电话随访2次；2.本周四复诊评估；3.考虑转介市精神卫生中心；4.通知家长知晓情况'
    records.push(r1)

    const r2: VisitRecord = new VisitRecord()
    r2.recordId = 'VR-20250114-002'
    r2.studentName = '刘雨晴'
    r2.studentId = '2023010208'
    r2.counselor = '李梦'
    r2.visitDate = '2025-01-14 10:00'
    r2.type = '学业心理支持'
    r2.summary = '学生因挂科被列入预警名单后出现明显回避行为，已两周未出寝室。存在低自尊认知模式，自述「反正怎样都学不会」。已制定分阶段学业恢复计划，并引导其参加正念减压小组。'
    r2.riskLevel = RiskLevel.HIGH
    r2.nextPlan = '1.每周一次学业心理支持面询；2.联系学业导师制定个性化补课方案；3.纳入正念减压工作坊'
    records.push(r2)

    const r3: VisitRecord = new VisitRecord()
    r3.recordId = 'VR-20250114-003'
    r3.studentName = '吴昊天'
    r3.studentId = '2023010651'
    r3.counselor = '赵明辉'
    r3.visitDate = '2025-01-14 15:00'
    r3.type = '行为评估'
    r3.summary = '学生在网络赌博中已累计输掉约1.8万元，承认难以自控、经常想到翻本。存在成瘾行为特征，尚未达到病理性赌博标准，但处于高危边缘。家长已到校参与联合会谈，学生承诺接受辅导。'
    r3.riskLevel = RiskLevel.HIGH
    r3.nextPlan = '1.签署戒赌承诺书并交出银行卡由家长保管；2.每周一次成瘾行为认知治疗；3.每月回访评估进展'
    records.push(r3)

    const r4: VisitRecord = new VisitRecord()
    r4.recordId = 'VR-20250113-004'
    r4.studentName = '张雨薇'
    r4.studentId = '2023010456'
    r4.counselor = '王明远'
    r4.visitDate = '2025-01-13 14:00'
    r4.type = '回访复诊'
    r4.summary = '上次诊断为轻度焦虑，经过四周正念练习和认知行为治疗，焦虑水平明显下降，GAD-7从12分降至6分。学生反馈睡眠质量改善，课堂注意力恢复约70%。建议继续当前干预方案。'
    r4.riskLevel = RiskLevel.LOW
    r4.nextPlan = '1.继续正念练习；2.转为双周回访模式；3.鼓励参加心理健康月活动'
    records.push(r4)

    const r5: VisitRecord = new VisitRecord()
    r5.recordId = 'VR-20250112-005'
    r5.studentName = '孙浩然'
    r5.studentId = '2022010234'
    r5.counselor = '李梦'
    r5.visitDate = '2025-01-12 09:00'
    r5.type = '初次面询'
    r5.summary = '大四学生，考研失败后情绪低落已达一个月，出现间歇性暴饮暴食行为。否认自杀意念，但承认「生活没有方向感」。已建立初步信任关系，共同制定了三周短期行动计划。'
    r5.riskLevel = RiskLevel.MEDIUM
    r5.nextPlan = '1.每周一次认知行为治疗；2.班主任协助推荐就业实习机会；3.两周后评估是否需转诊精神科'
    records.push(r5)

    return records
  }

  /* ==================== S5 高危随访 ==================== */
  /**
   * 高危随访任务来源：学生端提交的半月报（reports 表）。
   * 学生做完 AI 测评后，凡是被评为「中风险」及以上的报告，自动注入为一条随访任务，
   * 风险越高优先级越高、随访时限越短。完成状态由学校端自己持久化，不回写学生数据。
   */
  async fetchFollowUpTasks(): Promise<FollowUpTask[]> {
    const db: DatabaseHelper = DatabaseHelper.getInstance()
    const reports: ReportData[] = await db.getAllReports()
    const doneSet: string[] = await this.loadFollowUpDoneIds()

    const tasks: FollowUpTask[] = []
    reports.forEach((r: ReportData) => {
      const level: RiskLevel = this.mapReportRisk(r.riskLevel)
      // 低风险不需要随访
      if (level < RiskLevel.MEDIUM) {
        return
      }

      const t: FollowUpTask = new FollowUpTask()
      t.taskId = 'FU-' + r.id
      t.studentName = r.studentName
      t.studentId = r.className                 // students 表无学号，用班级标识
      t.reason = r.aiCounselorSummary           // 直接复用 AI 生成的辅导员预审摘要
      t.riskLevel = level
      t.priority = level >= RiskLevel.HIGH ? FollowUpPriority.URGENT : FollowUpPriority.NORMAL
      t.deadline = this.calcFollowUpDeadline(r.submitTime, level)
      t.completed = doneSet.indexOf(t.taskId) >= 0
      tasks.push(t)
    })

    // 高风险优先、其次按截止时间靠前
    tasks.sort((a: FollowUpTask, b: FollowUpTask): number => {
      if (a.riskLevel !== b.riskLevel) {
        return b.riskLevel - a.riskLevel
      }
      return a.deadline < b.deadline ? -1 : 1
    })
    return tasks
  }

  /**
   * 标记一条随访任务为已完成（持久化到学校端 preferences，刷新后不丢失）
   */
  async markFollowUpDone(taskId: string): Promise<void> {
    const doneSet: string[] = await this.loadFollowUpDoneIds()
    if (doneSet.indexOf(taskId) < 0) {
      doneSet.push(taskId)
      await putString(FOLLOWUP_DONE_KEY, JSON.stringify(doneSet))
    }
  }

  /**
   * 撤销一条随访任务的完成状态
   */
  async markFollowUpUndone(taskId: string): Promise<void> {
    const doneSet: string[] = await this.loadFollowUpDoneIds()
    const next: string[] = doneSet.filter((id: string) => id !== taskId)
    await putString(FOLLOWUP_DONE_KEY, JSON.stringify(next))
  }

  private async loadFollowUpDoneIds(): Promise<string[]> {
    const json: string = await getString(FOLLOWUP_DONE_KEY, '[]')
    try {
      return JSON.parse(json) as string[]
    } catch (e) {
      return []
    }
  }

  private mapReportRisk(level: string): RiskLevel {
    if (level === '极高风险') {
      return RiskLevel.CRITICAL
    }
    if (level === '高风险') {
      return RiskLevel.HIGH
    }
    if (level === '中风险') {
      return RiskLevel.MEDIUM
    }
    return RiskLevel.LOW
  }

  /**
   * 按风险等级给随访时限：极高 1 天、高 2 天、中 5 天
   */
  private calcFollowUpDeadline(submitTime: number, level: RiskLevel): string {
    let days: number = 5
    if (level === RiskLevel.CRITICAL) {
      days = 1
    } else if (level === RiskLevel.HIGH) {
      days = 2
    }
    const due: Date = new Date(submitTime + days * 24 * 60 * 60 * 1000)
    const m: string = (due.getMonth() + 1).toString().padStart(2, '0')
    const d: string = due.getDate().toString().padStart(2, '0')
    return due.getFullYear() + '-' + m + '-' + d
  }

  /* ==================== S6 心理活动 ==================== */
  /**
   * 活动数据直接读学生端报名用的同一张表（MentalActivity / MentalHealth.db）。
   * 学生在活动页报名/取消，currentQuota 实时变化，学校端这里看到的就是真实报名情况。
   * 满意度来自学生端提交的评分（ActivityFeedbackStore），学校端只聚合展示，不参与打分。
   */
  async fetchActivities(context: common.Context): Promise<Activity[]> {
    const list: MentalActivity[] = await ActivityDBHelper.queryAll(context)
    const feedback: Record<string, ActivityFeedback> = await ActivityFeedbackStore.loadAll()
    const statusMap: Record<string, number> = await this.loadActivityStatus()

    return list.map((m: MentalActivity): Activity => {
      const a: Activity = new Activity()
      a.activityId = 'ACT-' + m.id.toString()
      a.title = m.title
      a.type = m.type
      a.description = '面向「' + m.targetState + '」状态学生 · 地点：' + m.location
      // time 列以 "开始 ~ 结束" 存储时间段；旧数据为单个时间点时起止相同
      const range: TimeRange = this.parseTimeRange(m.time)
      a.startDate = range.startText
      a.endDate = range.endText
      a.organizer = '校级心理中心'
      a.participants = m.currentQuota                 // 真实报名人数
      a.status = this.resolveActivityStatus(a.activityId, m, statusMap, range)
      a.satisfaction = ActivityFeedbackStore.getAverage(feedback, a.activityId)  // 学生评分聚合
      return a
    })
  }

  /**
   * 活动状态按时间段自动推导：
   *  - 当前时间在时间段内 → 进行中
   *  - 当前时间在时间段之后 → 已完成
   *  - 当前时间在时间段之前 → 沿用学校端设定的原有状态（草稿/已批准），未设过则按报名情况推导
   * 这样「已批准」在活动开始前仍可被编辑修改，时间到了再自动流转。
   */
  private resolveActivityStatus(activityId: string, m: MentalActivity, statusMap: Record<string, number>, range: TimeRange): ActivityStatus {
    const now: number = new Date().getTime()
    if (range.start > 0 && range.end > 0) {
      if (now >= range.start && now <= range.end) {
        return ActivityStatus.IN_PROGRESS
      }
      if (now > range.end) {
        return ActivityStatus.COMPLETED
      }
    }
    // 活动尚未开始：以学校端手动设定的状态为准
    const override: number | undefined = statusMap[activityId]
    if (override !== undefined) {
      return override as ActivityStatus
    }
    if (m.currentQuota > 0) {
      return ActivityStatus.APPROVED
    }
    return ActivityStatus.DRAFT
  }

  // 解析 "YYYY-MM-DD HH:mm ~ YYYY-MM-DD HH:mm" 形式的时间段
  private parseTimeRange(time: string): TimeRange {
    const sep: number = time.indexOf('~')
    if (sep >= 0) {
      const startText: string = time.substring(0, sep).trim()
      const endText: string = time.substring(sep + 1).trim()
      return {
        start: this.parseDateTime(startText),
        end: this.parseDateTime(endText),
        startText: startText,
        endText: endText
      }
    }
    const t: number = this.parseDateTime(time)
    return { start: t, end: t, startText: time.trim(), endText: time.trim() }
  }

  // 解析 "YYYY-MM-DD HH:mm" 为时间戳，失败返回 0
  private parseDateTime(s: string): number {
    const str: string = s.trim()
    if (str.length === 0) {
      return 0
    }
    const parts: string[] = str.split(' ')
    const dateParts: string[] = parts[0].split('-')
    if (dateParts.length < 3) {
      return 0
    }
    const y: number = Number(dateParts[0])
    const mo: number = Number(dateParts[1])
    const d: number = Number(dateParts[2])
    let hh: number = 0
    let mm: number = 0
    if (parts.length >= 2) {
      const timeParts: string[] = parts[1].split(':')
      hh = Number(timeParts[0])
      if (timeParts.length >= 2) {
        mm = Number(timeParts[1])
      }
    }
    if (isNaN(y) || isNaN(mo) || isNaN(d)) {
      return 0
    }
    return new Date(y, mo - 1, d, hh, mm, 0).getTime()
  }

  /**
   * 学校端：编辑活动基础信息，写回学生端报名用的同一张表
   */
  async updateActivity(activityId: string, fields: ActivityEditFields, context: common.Context): Promise<boolean> {
    const id: number = Number(activityId.replace('ACT-', ''))
    return await ActivityDBHelper.updateActivity(context, id, fields)
  }

  /**
   * 学校端：设置活动审批状态（批准/进行中/完成/退回草稿），持久化为学校端覆盖值
   */
  async setActivityStatus(activityId: string, status: ActivityStatus): Promise<void> {
    const statusMap: Record<string, number> = await this.loadActivityStatus()
    statusMap[activityId] = status
    await putString(ACTIVITY_STATUS_KEY, JSON.stringify(statusMap))
  }

  private async loadActivityStatus(): Promise<Record<string, number>> {
    const json: string = await getString(ACTIVITY_STATUS_KEY, '{}')
    try {
      return JSON.parse(json) as Record<string, number>
    } catch (e) {
      return {}
    }
  }

  async fetchEfficiencyReport(activityId: string, context: common.Context): Promise<EfficiencyReport> {
    const report: EfficiencyReport = new EfficiencyReport()
    report.activityId = activityId
    report.createdAt = ''

    const id: number = Number(activityId.replace('ACT-', ''))
    const list: MentalActivity[] = await ActivityDBHelper.queryAll(context)
    let target: MentalActivity | undefined = undefined
    for (let i: number = 0; i < list.length; i++) {
      if (list[i].id === id) {
        target = list[i]
        break
      }
    }
    if (target === undefined) {
      return report
    }

    const feedback: Record<string, ActivityFeedback> = await ActivityFeedbackStore.loadAll()
    const avg: number = ActivityFeedbackStore.getAverage(feedback, activityId)

    report.totalParticipants = target.currentQuota
    // 完成率 = 实际报名 / 名额上限（真实报名热度）
    report.completionRate = target.maxQuota > 0 ? target.currentQuota / target.maxQuota : 0
    report.avgSatisfaction = avg                               // 学生评分平均
    report.recommendationRate = avg > 0 ? avg / 5 : 0          // 推荐率 = 平均分 / 满分
    report.peakIndex = Math.round(report.completionRate * 100)
    return report
  }

  /* ==================== S7 首页数据总览 ==================== */
  /**
   * 首页总览是各端真实数据的聚合：
   *  - 在册学生数  ← students 表（注册写入）
   *  - 风险分布    ← reports 表（学生半月报 AI 评级）
   *  - 今日预约    ← BookingService（学生预约咨询）
   *  - 待跟进      ← S5 随访任务中未完成数
   *  - 待处理工单/活跃热线 ← S2/S1（成员A的接口，接真实数据后自动联动）
   */
  async fetchDashboardSummary(context: common.Context): Promise<DashboardSummary> {
    const summary: DashboardSummary = new DashboardSummary()
    const db: DatabaseHelper = DatabaseHelper.getInstance()

    // 1) 在册学生数
    try {
      summary.totalStudents = await db.getStudentCount()
      if (summary.totalStudents === 0) {
        summary.totalStudents = 3560
      }
    } catch (e) {
      summary.totalStudents = 3560
    }

    // 2) 风险分布（低/中/高/极高）
    let dist: number[] = [0, 0, 0, 0]
    try {
      const reports: ReportData[] = await db.getAllReports()
      if (reports.length === 0) {
        // Mock data when DB is empty
        dist = [3120, 280, 115, 45]
      } else {
        reports.forEach((r: ReportData) => {
          const level: RiskLevel = this.mapReportRisk(r.riskLevel)
          dist[level] = dist[level] + 1
        })
      }
    } catch (e) {
      // Mock data when DB errors
      dist = [3120, 280, 115, 45]
    }
    summary.riskDistribution = dist

    // 3) 今日预约数
    try {
      const bookingSvc: BookingService = BookingService.getInstance()
      await bookingSvc.init(context)
      const bookings: BookingDTO[] = await bookingSvc.getBookings()
      const today: Date = new Date()
      summary.todayAppointments = bookings.filter((b: BookingDTO) =>
        b.date.getFullYear() === today.getFullYear() &&
        b.date.getMonth() === today.getMonth() &&
        b.date.getDate() === today.getDate()
      ).length
    } catch (e) {
      summary.todayAppointments = 0
    }

    // 4) 待跟进 = 未完成的随访任务数
    try {
      const tasks: FollowUpTask[] = await this.fetchFollowUpTasks()
      summary.uncompletedFollowUps = tasks.filter((t: FollowUpTask) => !t.completed).length
    } catch (e) {
      summary.uncompletedFollowUps = 0
    }

    // 5) 待处理工单 / 活跃热线（成员A模块，调其接口聚合）
    try {
      const orders: WorkOrder[] = await this.fetchWorkOrders()
      summary.pendingOrders = orders.filter((o: WorkOrder) => o.status === WorkOrderStatus.PENDING).length
    } catch (e) {
      summary.pendingOrders = 0
    }
    try {
      const calls: HotlineCall[] = await this.fetchActiveCalls()
      summary.activeCalls = calls.filter((c: HotlineCall) => c.status === CallStatus.ONGOING).length
    } catch (e) {
      summary.activeCalls = 0
    }

    return summary
  }
}
