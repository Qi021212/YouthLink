import { preferences } from '@kit.ArkData';
import {
  ConsultantShift,
  ScheduleAppointment,
  RescheduleRecord,
  ReminderConfig,
  DayScheduleStats,
  WeekScheduleSummary,
  AvailableSlot,
  ConflictResult
} from '../model/ScheduleModel';

// ================= 存储 Key =================
const STORAGE_NAME: string = 'booking_data';
const SHIFTS_KEY: string = 'consultant_shifts';
const APPOINTMENTS_KEY: string = 'all_bookings';
const REMINDER_CONFIG_KEY: string = 'reminder_config';

// ================= 存储预约数据结构（添加 status 字段） =================
interface StoredBooking {
  id: string;
  name: string;
  clazz: string;
  dorm: string;
  room: string;
  slot: string;
  date: string;
  consultantId: string;
  consultantName: string;
  status: string;  // 🆕 添加状态字段
}

// ================= 工具函数 =================
function generateId(): string {
  return Date.now().toString(36) + '_' + Math.random().toString(36).substring(2, 8);
}

function isSameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();
}

function getWeekStart(date: Date): Date {
  const d: Date = new Date(date);
  const day: number = d.getDay();
  d.setDate(d.getDate() - day);
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatDate(d: Date): string {
  const year: string = d.getFullYear().toString();
  const month: string = (d.getMonth() + 1).toString().padStart(2, '0');
  const day: string = d.getDate().toString().padStart(2, '0');
  return year + '-' + month + '-' + day;
}

// ================= 存储排班数据结构 =================
export class StoredShift {
  id: string = '';
  dayOfWeek: number = 0;
  startTime: string = '';
  endTime: string = '';
  room: string = '';
  consultantId: string = '';
  consultantName: string = '';
  isActive: boolean = true;

  constructor() {}
}

// ================= 存储提醒配置数据结构 =================
export class StoredReminderConfig {
  enabled: boolean = true;
  times: number[] = [];
  methods: string[] = [];

  constructor() {
    this.times = [15, 60, 1440];
    this.methods = ['push'];
  }
}

// ================= 预约服务 =================
export class ScheduleService {

  private static instance: ScheduleService;
  private dataPreferences?: preferences.Preferences;

  private shifts: ConsultantShift[] = [];
  private appointments: ScheduleAppointment[] = [];

  private constructor() {}

  static getInstance(): ScheduleService {
    if (!ScheduleService.instance) {
      ScheduleService.instance = new ScheduleService();
    }
    return ScheduleService.instance;
  }

  // ========== 初始化 ==========
  async init(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, STORAGE_NAME);
      await this.loadAllData();
    } catch (e) {
      console.error('初始化排班服务失败', JSON.stringify(e));
    }
  }

  private async loadAllData(): Promise<void> {
    await this.loadShifts();
    await this.loadAppointments();
  }

  // ========== 排班管理 ==========
  private async loadShifts(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        this.shifts = this.getDefaultShifts();
        return;
      }
      const jsonStr: string = await this.dataPreferences.get(SHIFTS_KEY, '[]') as string;
      if (!jsonStr || jsonStr === '[]') {
        this.shifts = this.getDefaultShifts();
        return;
      }
      const rawData: StoredShift[] = JSON.parse(jsonStr) as StoredShift[];
      const result: ConsultantShift[] = [];
      for (const item of rawData) {
        const shift: ConsultantShift = new ConsultantShift();
        shift.id = item.id;
        shift.dayOfWeek = item.dayOfWeek;
        shift.startTime = item.startTime;
        shift.endTime = item.endTime;
        shift.room = item.room;
        shift.consultantId = item.consultantId;
        shift.consultantName = item.consultantName;
        shift.isActive = item.isActive;
        result.push(shift);
      }
      this.shifts = result;
    } catch (e) {
      console.error('加载排班失败', JSON.stringify(e));
      this.shifts = this.getDefaultShifts();
    }
  }

  private async saveShifts(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }
      const toStore: StoredShift[] = [];
      for (const s of this.shifts) {
        const stored: StoredShift = new StoredShift();
        stored.id = s.id;
        stored.dayOfWeek = s.dayOfWeek;
        stored.startTime = s.startTime;
        stored.endTime = s.endTime;
        stored.room = s.room;
        stored.consultantId = s.consultantId;
        stored.consultantName = s.consultantName;
        stored.isActive = s.isActive;
        toStore.push(stored);
      }
      await this.dataPreferences.put(SHIFTS_KEY, JSON.stringify(toStore));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('保存排班失败', JSON.stringify(e));
    }
  }

  private getDefaultShifts(): ConsultantShift[] {
    const result: ConsultantShift[] = [];
    const consultantId: string = 'c1';
    const consultantName: string = '张老师';
    const rooms: string[] = ['辅导室A', '辅导室B'];
    const timeSlots: string[][] = [
      ['09:00', '10:00'],
      ['10:00', '11:00'],
      ['14:00', '15:00'],
      ['15:00', '16:00'],
      ['16:00', '17:00']
    ];

    for (let day: number = 1; day <= 5; day++) {
      for (const room of rooms) {
        for (const slot of timeSlots) {
          if (slot[0] >= '14:00' && room === '辅导室B') {
            continue;
          }
          const shift: ConsultantShift = new ConsultantShift();
          shift.id = generateId();
          shift.dayOfWeek = day;
          shift.startTime = slot[0];
          shift.endTime = slot[1];
          shift.room = room;
          shift.consultantId = consultantId;
          shift.consultantName = consultantName;
          shift.isActive = true;
          result.push(shift);
        }
      }
    }
    return result;
  }

  async getShifts(consultantId: string): Promise<ConsultantShift[]> {
    const result: ConsultantShift[] = [];
    for (const s of this.shifts) {
      if (s.consultantId === consultantId && s.isActive) {
        result.push(s);
      }
    }
    return result;
  }

  async addShift(shift: ConsultantShift): Promise<void> {
    shift.id = generateId();
    this.shifts.push(shift);
    await this.saveShifts();
  }

  async updateShift(shiftId: string, updates: ConsultantShift): Promise<void> {
    for (let i: number = 0; i < this.shifts.length; i++) {
      if (this.shifts[i].id === shiftId) {
        const updated: ConsultantShift = new ConsultantShift();
        updated.id = this.shifts[i].id;
        updated.dayOfWeek = updates.dayOfWeek !== undefined ? updates.dayOfWeek : this.shifts[i].dayOfWeek;
        updated.startTime = updates.startTime || this.shifts[i].startTime;
        updated.endTime = updates.endTime || this.shifts[i].endTime;
        updated.room = updates.room || this.shifts[i].room;
        updated.consultantId = updates.consultantId || this.shifts[i].consultantId;
        updated.consultantName = updates.consultantName || this.shifts[i].consultantName;
        updated.isActive = updates.isActive !== undefined ? updates.isActive : this.shifts[i].isActive;
        this.shifts[i] = updated;
        break;
      }
    }
    await this.saveShifts();
  }

  async deleteShift(shiftId: string): Promise<void> {
    const newList: ConsultantShift[] = [];
    for (const s of this.shifts) {
      if (s.id !== shiftId) {
        newList.push(s);
      }
    }
    this.shifts = newList;
    await this.saveShifts();
  }

  // ========== 预约管理 ==========

  private convertStoredBookingToAppointment(stored: StoredBooking): ScheduleAppointment {
    const app: ScheduleAppointment = new ScheduleAppointment();
    app.id = stored.id;
    app.studentId = stored.id;
    app.studentName = stored.name;
    app.studentClass = stored.clazz;
    app.room = stored.room;
    app.shiftId = stored.room + '|' + stored.slot;
    app.date = new Date(stored.date);
    app.startTime = stored.slot.split('-')[0] || '';
    app.endTime = stored.slot.split('-')[1] || '';
    app.consultantId = stored.consultantId;
    app.consultantName = stored.consultantName;
    // 🆕 从存储中读取状态，如果没有则默认为 pending
    app.status = stored.status || 'pending';
    app.studentNote = '';
    app.cancelReason = '';
    app.rescheduleHistory = [];
    app.createdAt = new Date();
    app.updatedAt = new Date();
    return app;
  }

  private convertAppointmentToStoredBooking(app: ScheduleAppointment): StoredBooking {
    return {
      id: app.id,
      name: app.studentName,
      clazz: app.studentClass,
      dorm: '',
      room: app.room,
      slot: app.startTime + '-' + app.endTime,
      date: app.date.toISOString(),
      consultantId: app.consultantId,
      consultantName: app.consultantName,
      status: app.status  // 🆕 保存状态
    };
  }

  private async loadAppointments(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        this.appointments = [];
        return;
      }
      const jsonStr: string = await this.dataPreferences.get(APPOINTMENTS_KEY, '[]') as string;
      if (!jsonStr || jsonStr === '[]') {
        this.appointments = [];
        return;
      }
      const rawData: StoredBooking[] = JSON.parse(jsonStr) as StoredBooking[];
      const result: ScheduleAppointment[] = [];
      for (const item of rawData) {
        const app: ScheduleAppointment = this.convertStoredBookingToAppointment(item);
        result.push(app);
      }
      this.appointments = result;
    } catch (e) {
      console.error('加载预约失败', JSON.stringify(e));
      this.appointments = [];
    }
  }

  private async saveAppointmentsToStorage(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }
      const jsonStr: string = await this.dataPreferences.get(APPOINTMENTS_KEY, '[]') as string;
      let allBookings: StoredBooking[] = [];
      if (jsonStr && jsonStr !== '[]') {
        allBookings = JSON.parse(jsonStr) as StoredBooking[];
      }

      const idSet: Set<string> = new Set();
      const updatedBookings: StoredBooking[] = [];

      for (const app of this.appointments) {
        idSet.add(app.id);
        updatedBookings.push(this.convertAppointmentToStoredBooking(app));
      }

      for (const booking of allBookings) {
        if (!idSet.has(booking.id)) {
          updatedBookings.push(booking);
        }
      }

      await this.dataPreferences.put(APPOINTMENTS_KEY, JSON.stringify(updatedBookings));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('保存预约失败', JSON.stringify(e));
    }
  }

  // 获取咨询师本周所有预约（先加载最新数据）
  async getWeekAppointments(consultantId: string, weekStart: Date): Promise<ScheduleAppointment[]> {
    await this.loadAppointments();

    const start: Date = getWeekStart(weekStart);
    const end: Date = new Date(start);
    end.setDate(end.getDate() + 7);

    const result: ScheduleAppointment[] = [];
    for (const a of this.appointments) {
      if (a.consultantId === consultantId && a.date >= start && a.date < end) {
        result.push(a);
      }
    }
    result.sort((a: ScheduleAppointment, b: ScheduleAppointment) => {
      if (a.date.getTime() !== b.date.getTime()) {
        return a.date.getTime() - b.date.getTime();
      }
      return a.startTime.localeCompare(b.startTime);
    });
    return result;
  }

  // 更新预约状态
  async updateAppointmentStatus(appointmentId: string, status: string, reason?: string): Promise<void> {
    await this.loadAppointments();

    let targetIndex: number = -1;
    for (let i: number = 0; i < this.appointments.length; i++) {
      if (this.appointments[i].id === appointmentId) {
        targetIndex = i;
        break;
      }
    }
    if (targetIndex === -1) {
      throw new Error('预约不存在');
    }

    const targetApp: ScheduleAppointment = this.appointments[targetIndex];

    // 状态流转校验
    const pendingTransitions: string[] = ['confirmed', 'cancelled'];
    const confirmedTransitions: string[] = ['in_progress', 'cancelled', 'no_show'];
    const inProgressTransitions: string[] = ['completed', 'cancelled'];

    let allowed: string[] = [];
    if (targetApp.status === 'pending') {
      allowed = pendingTransitions;
    } else if (targetApp.status === 'confirmed') {
      allowed = confirmedTransitions;
    } else if (targetApp.status === 'in_progress') {
      allowed = inProgressTransitions;
    } else {
      allowed = [];
    }

    let isAllowed: boolean = false;
    for (const s of allowed) {
      if (s === status) {
        isAllowed = true;
        break;
      }
    }
    if (!isAllowed) {
      throw new Error('无法从 ' + targetApp.status + ' 变更为 ' + status);
    }

    targetApp.status = status;
    targetApp.updatedAt = new Date();
    if (status === 'cancelled' && reason) {
      targetApp.cancelReason = reason;
    }

    this.appointments[targetIndex] = targetApp;
    await this.saveAppointmentsToStorage();
  }

  // 创建预约
  async createAppointment(data: ScheduleAppointment): Promise<ScheduleAppointment> {
    await this.loadAppointments();

    for (const a of this.appointments) {
      if (a.consultantId === data.consultantId &&
        isSameDay(a.date, data.date) &&
        a.startTime === data.startTime &&
        a.status !== 'cancelled' &&
        a.status !== 'completed') {
        throw new Error('该时段已被预约');
      }
    }

    const app: ScheduleAppointment = new ScheduleAppointment();
    app.id = generateId();
    app.studentId = data.studentId;
    app.studentName = data.studentName;
    app.studentClass = data.studentClass;
    app.room = data.room;
    app.shiftId = data.shiftId;
    app.date = data.date;
    app.startTime = data.startTime;
    app.endTime = data.endTime;
    app.consultantId = data.consultantId;
    app.consultantName = data.consultantName;
    app.status = 'pending';
    app.studentNote = data.studentNote || '';
    app.cancelReason = '';
    app.rescheduleHistory = [];
    app.createdAt = new Date();
    app.updatedAt = new Date();

    this.appointments.push(app);
    await this.saveAppointmentsToStorage();
    return app;
  }

  // 取消预约
  async cancelBooking(bookingId: string): Promise<void> {
    await this.loadAppointments();

    let targetIndex: number = -1;
    for (let i: number = 0; i < this.appointments.length; i++) {
      if (this.appointments[i].id === bookingId) {
        targetIndex = i;
        break;
      }
    }
    if (targetIndex === -1) {
      throw new Error('预约不存在');
    }

    this.appointments.splice(targetIndex, 1);
    await this.saveAppointmentsToStorage();
  }

  // ========== 周视图统计 ==========
  async getWeekSummary(consultantId: string, weekStart: Date): Promise<WeekScheduleSummary> {
    await this.loadAppointments();

    const start: Date = getWeekStart(weekStart);
    const end: Date = new Date(start);
    end.setDate(end.getDate() + 7);

    const weekApps: ScheduleAppointment[] = [];
    for (const a of this.appointments) {
      if (a.consultantId === consultantId && a.date >= start && a.date < end) {
        weekApps.push(a);
      }
    }

    const dailyStats: DayScheduleStats[] = [];
    for (let i: number = 0; i < 7; i++) {
      const d: Date = new Date(start);
      d.setDate(d.getDate() + i);

      const dayApps: ScheduleAppointment[] = [];
      for (const a of weekApps) {
        if (isSameDay(a.date, d)) {
          dayApps.push(a);
        }
      }

      let shiftCount: number = 0;
      for (const s of this.shifts) {
        if (s.consultantId === consultantId && s.dayOfWeek === d.getDay() && s.isActive) {
          shiftCount++;
        }
      }

      let bookedCount: number = 0;
      for (const a of dayApps) {
        if (a.status !== 'cancelled' && a.status !== 'completed') {
          bookedCount++;
        }
      }

      const stats: DayScheduleStats = new DayScheduleStats();
      stats.date = d;
      stats.dateStr = formatDate(d);
      stats.total = dayApps.length;
      stats.available = shiftCount - bookedCount;
      stats.booked = bookedCount;
      dailyStats.push(stats);
    }

    let pendingCount: number = 0;
    let confirmedCount: number = 0;
    let completedCount: number = 0;
    let noShowCount: number = 0;
    let cancelledCount: number = 0;

    for (const a of weekApps) {
      if (a.status === 'pending') {
        pendingCount++;
      } else if (a.status === 'confirmed') {
        confirmedCount++;
      } else if (a.status === 'completed') {
        completedCount++;
      } else if (a.status === 'no_show') {
        noShowCount++;
      } else if (a.status === 'cancelled') {
        cancelledCount++;
      }
    }

    const summary: WeekScheduleSummary = new WeekScheduleSummary();
    summary.weekStart = start;
    summary.weekEnd = end;
    summary.totalAppointments = weekApps.length;
    summary.pendingCount = pendingCount;
    summary.confirmedCount = confirmedCount;
    summary.completedCount = completedCount;
    summary.noShowCount = noShowCount;
    summary.cancelledCount = cancelledCount;
    summary.dailyStats = dailyStats;

    return summary;
  }

  // ========== 提醒配置 ==========
  async getReminderConfig(consultantId: string): Promise<ReminderConfig> {
    try {
      if (!this.dataPreferences) {
        const config: ReminderConfig = new ReminderConfig();
        return config;
      }
      const key: string = REMINDER_CONFIG_KEY + '_' + consultantId;
      const jsonStr: string = await this.dataPreferences.get(key, '') as string;
      if (!jsonStr) {
        const config: ReminderConfig = new ReminderConfig();
        return config;
      }
      const obj: StoredReminderConfig = JSON.parse(jsonStr) as StoredReminderConfig;
      const config: ReminderConfig = new ReminderConfig();
      config.enabled = obj.enabled;
      config.times = obj.times;
      config.methods = obj.methods;
      return config;
    } catch (e) {
      const config: ReminderConfig = new ReminderConfig();
      return config;
    }
  }

  async saveReminderConfig(consultantId: string, config: ReminderConfig): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }
      const key: string = REMINDER_CONFIG_KEY + '_' + consultantId;
      const toStore: StoredReminderConfig = new StoredReminderConfig();
      toStore.enabled = config.enabled;
      toStore.times = config.times;
      toStore.methods = config.methods;
      await this.dataPreferences.put(key, JSON.stringify(toStore));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('保存提醒配置失败', JSON.stringify(e));
    }
  }

  // ========== 获取可用时段 ==========
  getAvailableSlots(consultantId: string, date: Date): AvailableSlot[] {
    const dayOfWeek: number = date.getDay();
    const result: AvailableSlot[] = [];

    const dayShifts: ConsultantShift[] = [];
    for (const s of this.shifts) {
      if (s.consultantId === consultantId && s.dayOfWeek === dayOfWeek && s.isActive) {
        dayShifts.push(s);
      }
    }

    for (const shift of dayShifts) {
      let isBooked: boolean = false;
      for (const a of this.appointments) {
        if (a.consultantId === consultantId &&
          isSameDay(a.date, date) &&
          a.startTime === shift.startTime &&
          a.status !== 'cancelled' &&
          a.status !== 'completed') {
          isBooked = true;
          break;
        }
      }
      const slot: AvailableSlot = new AvailableSlot();
      slot.shift = shift;
      slot.isBooked = isBooked;
      result.push(slot);
    }

    return result;
  }

  // ========== 清理 ==========
  async clearAllData(): Promise<void> {
    try {
      this.shifts = [];
      this.appointments = [];
      if (this.dataPreferences) {
        await this.dataPreferences.clear();
        await this.dataPreferences.flush();
      }
    } catch (e) {
      console.error('清除数据失败', JSON.stringify(e));
    }
  }
}