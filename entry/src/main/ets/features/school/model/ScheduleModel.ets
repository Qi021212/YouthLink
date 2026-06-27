// ================= 咨询师排班时段 =================
export class ConsultantShift {
  id: string = '';
  dayOfWeek: number = 0;          // 0=周日, 1=周一 ... 6=周六
  startTime: string = '';         // "09:00"
  endTime: string = '';           // "10:00"
  room: string = '';              // "辅导室A"
  consultantId: string = '';
  consultantName: string = '';
  isActive: boolean = true;

  constructor() {}
}

// ================= 预约记录 =================
export class ScheduleAppointment {
  id: string = '';
  studentId: string = '';
  studentName: string = '';
  studentClass: string = '';
  room: string = '';
  shiftId: string = '';
  date: Date = new Date();
  startTime: string = '';         // "09:00"
  endTime: string = '';           // "10:00"
  consultantId: string = '';
  consultantName: string = '';
  status: string = 'pending';     // pending | confirmed | in_progress | completed | cancelled | no_show
  studentNote: string = '';
  cancelReason: string = '';
  rescheduleHistory: RescheduleRecord[] = [];
  createdAt: Date = new Date();
  updatedAt: Date = new Date();

  constructor() {}
}

// ================= 改期记录 =================
export class RescheduleRecord {
  fromTime: string = '';
  toTime: string = '';
  operatorId: string = '';
  reason: string = '';
  timestamp: Date = new Date();

  constructor() {}
}

// ================= 提醒配置 =================
export class ReminderConfig {
  enabled: boolean = true;
  times: number[] = [15, 60, 1440];
  methods: string[] = ['push'];

  constructor() {}
}

// ================= 每日统计 =================
export class DayScheduleStats {
  date: Date = new Date();
  dateStr: string = '';
  total: number = 0;
  available: number = 0;
  booked: number = 0;

  constructor() {}
}

// ================= 周视图汇总 =================
export class WeekScheduleSummary {
  weekStart: Date = new Date();
  weekEnd: Date = new Date();
  totalAppointments: number = 0;
  pendingCount: number = 0;
  confirmedCount: number = 0;
  completedCount: number = 0;
  noShowCount: number = 0;
  cancelledCount: number = 0;
  dailyStats: DayScheduleStats[] = [];

  constructor() {}
}

// ================= 可用时段 =================
export class AvailableSlot {
  shift: ConsultantShift = new ConsultantShift();
  isBooked: boolean = false;

  constructor() {}
}

// ================= 冲突检测结果 =================
export class ConflictResult {
  hasConflict: boolean = false;
  conflictingAppointments: ScheduleAppointment[] = [];

  constructor() {}
}