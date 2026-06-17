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
  /* ==================== S1 热线通话 ==================== */
  async fetchActiveCalls(): Promise<HotlineCall[]> {
    const calls: HotlineCall[] = []
    const c1: HotlineCall = new HotlineCall()
    c1.callId = 'CALL-20250115-001'
    c1.callerName = '陈思远'
    c1.callerStudentId = '2023010201'
    c1.phoneNumber = '138****6721'
    c1.startTime = '2025-01-15 13:45'
    c1.duration = 845
    c1.status = CallStatus.ONGOING
    c1.riskLevel = RiskLevel.HIGH
    c1.tags = ['自杀意念', '重度抑郁', '学业压力']
    c1.aiSummary = '来电者自述近两周持续失眠，频繁出现「活着没意思」的念头，昨天在宿舍阳台长时间站立发呆被室友发现。SDS量表58分，建议立即启动危机干预流程。'
    calls.push(c1)

    const c2: HotlineCall = new HotlineCall()
    c2.callId = 'CALL-20250115-002'
    c2.callerName = '林小婉'
    c2.callerStudentId = '2024010503'
    c2.phoneNumber = '187****3459'
    c2.startTime = '2025-01-15 14:20'
    c2.duration = 412
    c2.status = CallStatus.COMPLETED
    c2.riskLevel = RiskLevel.MEDIUM
    c2.tags = ['焦虑', '寝室矛盾']
    c2.aiSummary = '大一新生，因与室友作息不合引发冲突，近一周情绪低落、上课注意力不集中。已进行情绪安抚并提供沟通技巧建议，建议转介辅导员协调寝室调整。'
    calls.push(c2)

    const c3: HotlineCall = new HotlineCall()
    c3.callId = 'CALL-20250115-003'
    c3.callerName = '王浩宇'
    c3.callerStudentId = '2023010312'
    c3.phoneNumber = '159****8023'
    c3.startTime = '2025-01-15 15:05'
    c3.duration = 328
    c3.status = CallStatus.COMPLETED
    c3.riskLevel = RiskLevel.LOW
    c3.tags = ['情感困扰', '学业规划']
    c3.aiSummary = '大三学生因感情分手导致近期成绩下滑，对未来就业方向感到迷茫。已给予情感支持和职业规划初步建议，预约下周面询继续跟进。'
    calls.push(c3)

    const c4: HotlineCall = new HotlineCall()
    c4.callId = 'CALL-20250114-005'
    c4.callerName = '匿名来电'
    c4.callerStudentId = '未登记'
    c4.phoneNumber = '176****0198'
    c4.startTime = '2025-01-14 21:33'
    c4.duration = 920
    c4.status = CallStatus.MISSED
    c4.riskLevel = RiskLevel.CRITICAL
    c4.tags = ['自杀风险评估', '匿名求助']
    c4.aiSummary = '来电者拒绝透露身份，语速缓慢、多次停顿，提到「不想再拖累家人」。通话中途断线，系统已标记极高风险，建议通过运营商协查定位。'
    calls.push(c4)

    return calls
  }

  /* ==================== S2 工单管理 ==================== */
  async fetchWorkOrders(): Promise<WorkOrder[]> {
    const orders: WorkOrder[] = []

    const o1: WorkOrder = new WorkOrder()
    o1.orderId = 'WO-20250115-001'
    o1.relatedCallId = 'CALL-20250115-001'
    o1.studentName = '陈思远'
    o1.studentId = '2023010201'
    o1.type = '危机干预'
    o1.description = '学生来电暴露自杀意念，SDS评分58分，阳性质询后有短期自伤计划。心理咨询中心初步评估为重度抑郁发作，需要紧急精神科转诊和家长告知。'
    o1.status = WorkOrderStatus.PROCESSING
    o1.assignedTo = '王明远 咨询师'
    o1.createdAt = '2025-01-15 14:00'
    o1.updatedAt = '2025-01-15 15:20'
    o1.riskLevel = RiskLevel.CRITICAL
    orders.push(o1)

    const o2: WorkOrder = new WorkOrder()
    o2.orderId = 'WO-20250115-002'
    o2.studentName = '林小婉'
    o2.studentId = '2024010503'
    o2.type = '寝室调解'
    o2.description = '大一新生因寝室作息冲突产生人际关系紧张，影响到学习状态。需要辅导员介入协调寝室问题，并安排适应性心理辅导。'
    o2.status = WorkOrderStatus.PENDING
    o2.assignedTo = ''
    o2.createdAt = '2025-01-15 14:30'
    o2.updatedAt = '2025-01-15 14:30'
    o2.riskLevel = RiskLevel.MEDIUM
    orders.push(o2)

    const o3: WorkOrder = new WorkOrder()
    o3.orderId = 'WO-20250115-003'
    o3.studentName = '周子涵'
    o3.studentId = '2022010215'
    o3.type = '情绪疏导'
    o3.description = '大四学生因毕业论文进度滞后、秋招不顺利，出现焦虑躯体化症状（心悸、手抖），需要心理咨询和学业支持。'
    o3.status = WorkOrderStatus.PENDING
    o3.assignedTo = ''
    o3.createdAt = '2025-01-15 10:15'
    o3.updatedAt = '2025-01-15 10:15'
    o3.riskLevel = RiskLevel.MEDIUM
    orders.push(o3)

    const o4: WorkOrder = new WorkOrder()
    o4.orderId = 'WO-20250114-004'
    o4.studentName = '匿名来电'
    o4.studentId = '待确认'
    o4.type = '紧急协查'
    o4.description = '昨日21:33分匿名高危来电中途断线，已通过技术手段缩小定位范围至南区宿舍楼群。需立即启动紧急响应：通知保卫处协助排查，联系对应辅导员逐一核实。'
    o4.status = WorkOrderStatus.PROCESSING
    o4.assignedTo = '校级心理中心应急组'
    o4.createdAt = '2025-01-14 21:45'
    o4.updatedAt = '2025-01-15 08:30'
    o4.riskLevel = RiskLevel.CRITICAL
    orders.push(o4)

    const o5: WorkOrder = new WorkOrder()
    o5.orderId = 'WO-20250113-005'
    o5.studentName = '刘雨晴'
    o5.studentId = '2023010208'
    o5.type = '学业支持'
    o5.description = '学生因上学期挂科3门被列入学业预警名单，产生严重自我怀疑和逃避行为，已两周未去上课。需要联合辅导员和学业导师制定帮扶方案。'
    o5.status = WorkOrderStatus.PROCESSING
    o5.assignedTo = '李梦 咨询师'
    o5.createdAt = '2025-01-13 09:00'
    o5.updatedAt = '2025-01-14 16:00'
    o5.riskLevel = RiskLevel.HIGH
    orders.push(o5)

    const o6: WorkOrder = new WorkOrder()
    o6.orderId = 'WO-20250110-006'
    o6.studentName = '吴昊天'
    o6.studentId = '2023010651'
    o6.type = '家长沟通'
    o6.description = '学生在校期间多次参与赌博游戏，已被学校给予严重警告处分。家长主动联系中心请求心理干预，评估是否存在成瘾倾向。'
    o6.status = WorkOrderStatus.COMPLETED
    o6.assignedTo = '赵明辉 咨询师'
    o6.createdAt = '2025-01-10 14:00'
    o6.updatedAt = '2025-01-12 17:00'
    o6.riskLevel = RiskLevel.HIGH
    orders.push(o6)

    return orders
  }

  async fetchOrderTimeline(orderId: string): Promise<OrderTimelineNode[]> {
    const timeline: OrderTimelineNode[] = []

    const n1: OrderTimelineNode = new OrderTimelineNode()
    n1.nodeId = 'TL-001'
    n1.orderId = orderId
    n1.time = '2025-01-15 14:00'
    n1.action = '系统自动创建工单'
    n1.operator = 'AI热线系统'
    n1.remark = '根据热线 CALL-20250115-001 高危标记自动生成，风险等级：极高'
    timeline.push(n1)

    const n2: OrderTimelineNode = new OrderTimelineNode()
    n2.nodeId = 'TL-002'
    n2.orderId = orderId
    n2.time = '2025-01-15 14:10'
    n2.action = '危机评估确认'
    n2.operator = '值班管理员 张主任'
    n2.remark = '确认为紧急危机干预事件，已电话联系咨询师王明远'
    timeline.push(n2)

    const n3: OrderTimelineNode = new OrderTimelineNode()
    n3.nodeId = 'TL-003'
    n3.orderId = orderId
    n3.time = '2025-01-15 14:25'
    n3.action = '分配咨询师'
    n3.operator = '系统调度'
    n3.remark = '分配给王明远咨询师（危机干预方向，从业8年）'
    timeline.push(n3)

    const n4: OrderTimelineNode = new OrderTimelineNode()
    n4.nodeId = 'TL-004'
    n4.orderId = orderId
    n4.time = '2025-01-15 15:00'
    n4.action = '咨询师接单'
    n4.operator = '王明远 咨询师'
    n4.remark = '已阅读全部通话记录和AI分析报告，正在前往咨询室面谈'
    timeline.push(n4)

    const n5: OrderTimelineNode = new OrderTimelineNode()
    n5.nodeId = 'TL-005'
    n5.orderId = orderId
    n5.time = '2025-01-15 15:20'
    n5.action = '面询开始'
    n5.operator = '王明远 咨询师'
    n5.remark = '已与学生在咨询室见面，初步进行风险评估访谈'
    timeline.push(n5)

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
  async fetchFollowUpTasks(): Promise<FollowUpTask[]> {
    const tasks: FollowUpTask[] = []

    const t1: FollowUpTask = new FollowUpTask()
    t1.taskId = 'FU-20250115-001'
    t1.studentName = '陈思远'
    t1.studentId = '2023010201'
    t1.reason = '自杀意念高危随访 —— 每日2次电话确认安全'
    t1.deadline = '2025-01-16'
    t1.priority = FollowUpPriority.URGENT
    t1.completed = false
    t1.riskLevel = RiskLevel.CRITICAL
    tasks.push(t1)

    const t2: FollowUpTask = new FollowUpTask()
    t2.taskId = 'FU-20250115-002'
    t2.studentName = '匿名来电'
    t2.studentId = '待确认'
    t2.reason = '昨夜高危匿名来电身份排查 —— 需最终确认来电者身份并建立联系方式'
    t2.deadline = '2025-01-15'
    t2.priority = FollowUpPriority.URGENT
    t2.completed = false
    t2.riskLevel = RiskLevel.CRITICAL
    tasks.push(t2)

    const t3: FollowUpTask = new FollowUpTask()
    t3.taskId = 'FU-20250115-003'
    t3.studentName = '刘雨晴'
    t3.studentId = '2023010208'
    t3.reason = '学业预警后续跟进 —— 确认是否已恢复上课，评估心理状态'
    t3.deadline = '2025-01-17'
    t3.priority = FollowUpPriority.URGENT
    t3.completed = false
    t3.riskLevel = RiskLevel.HIGH
    tasks.push(t3)

    const t4: FollowUpTask = new FollowUpTask()
    t4.taskId = 'FU-20250115-004'
    t4.studentName = '吴昊天'
    t4.studentId = '2023010651'
    t4.reason = '赌博行为成瘾评估跟进 —— 检查戒赌承诺执行情况'
    t4.deadline = '2025-01-20'
    t4.priority = FollowUpPriority.NORMAL
    t4.completed = false
    t4.riskLevel = RiskLevel.HIGH
    tasks.push(t4)

    const t5: FollowUpTask = new FollowUpTask()
    t5.taskId = 'FU-20250115-005'
    t5.studentName = '孙浩然'
    t5.studentId = '2022010234'
    t5.reason = '考研失败情绪低落持续跟进 —— 就业推荐是否落地'
    t5.deadline = '2025-01-22'
    t5.priority = FollowUpPriority.NORMAL
    t5.completed = false
    t5.riskLevel = RiskLevel.MEDIUM
    tasks.push(t5)

    const t6: FollowUpTask = new FollowUpTask()
    t6.taskId = 'FU-20250110-006'
    t6.studentName = '赵雅涵'
    t6.studentId = '2024010882'
    t6.reason = '社交焦虑分级暴露训练完成度检查'
    t6.deadline = '2025-01-18'
    t6.priority = FollowUpPriority.NORMAL
    t6.completed = false
    t6.riskLevel = RiskLevel.MEDIUM
    tasks.push(t6)

    return tasks
  }

  /* ==================== S6 心理活动 ==================== */
  async fetchActivities(): Promise<Activity[]> {
    const activities: Activity[] = []

    const a1: Activity = new Activity()
    a1.activityId = 'ACT-202501-001'
    a1.title = '正念减压八周训练营'
    a1.type = '团体辅导'
    a1.description = '基于MBSR体系的八周结构化正念训练课程，涵盖身体扫描、静坐冥想、正念瑜伽等，目标帮助参与者掌握压力管理核心技能。每周三下午16:00-17:30，活动中心306室。'
    a1.status = ActivityStatus.IN_PROGRESS
    a1.startDate = '2024-12-04'
    a1.endDate = '2025-02-05'
    a1.organizer = '校级心理中心'
    a1.participants = 28
    a1.satisfaction = 4.5
    activities.push(a1)

    const a2: Activity = new Activity()
    a2.activityId = 'ACT-202502-002'
    a2.title = '2025春季心理健康月开幕式'
    a2.type = '大型活动'
    a2.description = '年度心理健康主题活动启动，含心理学专家讲座《压力与韧性》、VR心理体验馆、心理剧表演等。2月20日全天，学活中心广场。'
    a2.status = ActivityStatus.APPROVED
    a2.startDate = '2025-02-20'
    a2.endDate = '2025-02-20'
    a2.organizer = '学工部 × 校级心理中心'
    a2.participants = 0
    a2.satisfaction = 0
    activities.push(a2)

    const a3: Activity = new Activity()
    a3.activityId = 'ACT-202409-003'
    a3.title = '2024级新生心理健康普查'
    a3.type = '测评筛查'
    a3.description = '面向全体2024级新生的心理健康普查（UPI+SCL-90联合施测），覆盖5200名新生，筛查出需关注学生约480人。'
    a3.status = ActivityStatus.COMPLETED
    a3.startDate = '2024-09-15'
    a3.endDate = '2024-09-30'
    a3.organizer = '校级心理中心'
    a3.participants = 5200
    a3.satisfaction = 4.2
    activities.push(a3)

    const a4: Activity = new Activity()
    a4.activityId = 'ACT-202503-004'
    a4.title = '3·25 善爱我户外心理游园会'
    a4.type = '主题活动'
    a4.description = '「善待自己，拥抱情绪」主题游园，设8个互动摊位：情绪雕塑、烦恼甩甩乐、优点轰炸墙、沙盘游戏体验等。'
    a4.status = ActivityStatus.DRAFT
    a4.startDate = '2025-03-25'
    a4.endDate = '2025-03-25'
    a4.organizer = '校级心理中心'
    a4.participants = 0
    a4.satisfaction = 0
    activities.push(a4)

    const a5: Activity = new Activity()
    a5.activityId = 'ACT-202501-005'
    a5.title = '辅导员心理危机识别沙龙'
    a5.type = '培训讲座'
    a5.description = '面向全体辅导员举办的心理危机识别与干预技能培训，由市精神卫生中心专家主讲，内容包括危机信号识别、初次接触技巧、转诊流程。'
    a5.status = ActivityStatus.IN_PROGRESS
    a5.startDate = '2025-01-10'
    a5.endDate = '2025-01-17'
    a5.organizer = '学工部'
    a5.participants = 46
    a5.satisfaction = 4.8
    activities.push(a5)

    const a6: Activity = new Activity()
    a6.activityId = 'ACT-202501-006'
    a6.title = '考试焦虑应对工作坊'
    a6.type = '团体辅导'
    a6.description = '针对期末考试前夕的焦虑管理工作坊，教授呼吸放松法、积极意象训练和时间管理五步法，每次容纳15-20人。'
    a6.status = ActivityStatus.IN_PROGRESS
    a6.startDate = '2025-01-06'
    a6.endDate = '2025-01-18'
    a6.organizer = '校级心理中心'
    a6.participants = 42
    a6.satisfaction = 4.3
    activities.push(a6)

    const a7: Activity = new Activity()
    a7.activityId = 'ACT-202502-007'
    a7.title = '朋辈心理辅导员初级培训'
    a7.type = '培训讲座'
    a7.description = '面向各学院心理委员的朋辈辅导技能培训，含倾听技术、共情训练、危机转介等模块，考核通过颁发初级证书。'
    a7.status = ActivityStatus.DRAFT
    a7.startDate = '2025-02-25'
    a7.endDate = '2025-03-15'
    a7.organizer = '校级心理中心'
    a7.participants = 0
    a7.satisfaction = 0
    activities.push(a7)

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

  /* ==================== S7 首页数据总览 ==================== */
  async fetchDashboardSummary(): Promise<DashboardSummary> {
    const summary: DashboardSummary = new DashboardSummary()
    summary.activeCalls = 4
    summary.pendingOrders = 6
    summary.todayAppointments = 5
    summary.uncompletedFollowUps = 6
    summary.totalStudents = 5200
    summary.riskDistribution = [4100, 720, 280, 100]
    return summary
  }
}
