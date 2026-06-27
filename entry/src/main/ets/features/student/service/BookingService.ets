// BookingService.ts 完整修复版（解决所有类型问题）

import { preferences } from '@kit.ArkData';
import { BookingDTO, BookingHistorySummary, ConsultantShiftDTO, ConsultantInfo, ReminderData } from '../model/BookingModel';

// 持久化存储的 key
const STORAGE_NAME: string = 'booking_data';
const BOOKINGS_KEY: string = 'all_bookings';
const HISTORY_KEY: string = 'booking_history';
const REMINDER_KEY: string = 'next_visit_reminder';

// 用于存储的预约数据结构（date 为字符串）
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
}

// 咨询师信息
const CONSULTANTS: ConsultantInfo[] = [
  { id: 'c1', name: '张老师' },
  { id: 'c2', name: '李老师' },
  { id: 'c3', name: '王老师' }
];

const ROOMS: string[] = ['辅导室A', '辅导室B', '辅导室C'];
const SLOTS: string[] = ['09:00-10:00', '10:00-11:00', '14:00-15:00', '15:00-16:00', '19:00-20:00'];

// 生成固定排班数据
function generateShiftsForDate(date: Date): ConsultantShiftDTO[] {
  const shifts: ConsultantShiftDTO[] = [];
  const seed: number = date.getFullYear() * 366 + date.getMonth() * 31 + date.getDate();

  for (const room of ROOMS) {
    for (const slot of SLOTS) {
      const consultantIndex: number = (seed + room.charCodeAt(0) * 3 + slot.length * 2) % CONSULTANTS.length;
      shifts.push({
        id: `${room}|${slot}`,
        room: room,
        slot: slot,
        consultantId: CONSULTANTS[consultantIndex].id,
        consultantName: CONSULTANTS[consultantIndex].name
      });
    }
  }
  return shifts;
}

// 预约服务
export class BookingService {

  private static instance: BookingService;
  private dataPreferences?: preferences.Preferences;
  private cachedBookings: BookingDTO[] = [];

  private constructor() {}

  static getInstance(): BookingService {
    if (!BookingService.instance) {
      BookingService.instance = new BookingService();
    }
    return BookingService.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, STORAGE_NAME);
      await this.loadBookingsFromStorage();
    } catch (e) {
      console.error('初始化预约服务失败', JSON.stringify(e));
      this.cachedBookings = [];
    }
  }

  // 从存储加载所有预约
  private async loadBookingsFromStorage(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        this.cachedBookings = [];
        return;
      }
      const jsonStr: string = await this.dataPreferences.get(BOOKINGS_KEY, '[]') as string;
      if (!jsonStr || jsonStr === '[]') {
        this.cachedBookings = [];
        return;
      }

      const storedBookings: StoredBooking[] = JSON.parse(jsonStr) as StoredBooking[];
      this.cachedBookings = [];

      for (const stored of storedBookings) {
        if (stored && stored.date) {
          const booking: BookingDTO = {
            id: stored.id,
            name: stored.name,
            clazz: stored.clazz,
            dorm: stored.dorm,
            room: stored.room,
            slot: stored.slot,
            date: new Date(stored.date),
            consultantId: stored.consultantId,
            consultantName: stored.consultantName
          };
          this.cachedBookings.push(booking);
        }
      }
    } catch (e) {
      console.error('加载预约数据失败', JSON.stringify(e));
      this.cachedBookings = [];
    }
  }

  // 保存所有预约到存储（修复第110行的问题）
  private async saveBookingsToStorage(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }

      // 显式声明每个对象的类型为 StoredBooking
      const toStore: StoredBooking[] = [];
      for (let i: number = 0; i < this.cachedBookings.length; i++) {
        const b: BookingDTO = this.cachedBookings[i];
        const storedItem: StoredBooking = {
          id: b.id,
          name: b.name,
          clazz: b.clazz,
          dorm: b.dorm,
          room: b.room,
          slot: b.slot,
          date: b.date.toISOString(),
          consultantId: b.consultantId,
          consultantName: b.consultantName
        };
        toStore.push(storedItem);
      }

      await this.dataPreferences.put(BOOKINGS_KEY, JSON.stringify(toStore));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('保存预约数据失败', JSON.stringify(e));
    }
  }

  // 获取所有预约记录
  async getBookings(): Promise<BookingDTO[]> {
    return [...this.cachedBookings];
  }

  // 获取指定日期的排班
  async getConsultantShifts(date: Date): Promise<ConsultantShiftDTO[]> {
    return generateShiftsForDate(date);
  }

  // 创建预约
  async createBooking(booking: BookingDTO): Promise<void> {
    // 检查是否已被预约
    const existing: BookingDTO | undefined = this.cachedBookings.find((b: BookingDTO) =>
    b.room === booking.room &&
      b.slot === booking.slot &&
      this.isSameDay(b.date, booking.date)
    );
    if (existing) {
      throw new Error('该时段已被预约');
    }

    this.cachedBookings.push(booking);
    await this.saveBookingsToStorage();
    await this.saveBookingHistory(booking);
  }

  // 保存预约历史到本地存储
  private async saveBookingHistory(booking: BookingDTO): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }

      const historyList: BookingHistorySummary[] = await this.getBookingHistoryList();
      const summary: BookingHistorySummary = {
        id: booking.id,
        dateStr: this.formatDate(booking.date),
        timestamp: booking.date.getTime(),
        room: booking.room,
        slot: booking.slot,
        consultantName: booking.consultantName
      };

      const exists: boolean = historyList.some((h: BookingHistorySummary) => h.id === booking.id);
      if (!exists) {
        historyList.unshift(summary);
        await this.dataPreferences.put(HISTORY_KEY, JSON.stringify(historyList));
        await this.dataPreferences.flush();
      }
    } catch (e) {
      console.error('保存预约历史失败', JSON.stringify(e));
    }
  }

  // 获取预约历史列表
  async getBookingHistoryList(): Promise<BookingHistorySummary[]> {
    try {
      if (!this.dataPreferences) {
        return [];
      }

      const jsonStr: string = await this.dataPreferences.get(HISTORY_KEY, '[]') as string;
      if (!jsonStr || jsonStr === '[]') {
        return [];
      }
      return JSON.parse(jsonStr) as BookingHistorySummary[];
    } catch (e) {
      console.error('获取预约历史失败', JSON.stringify(e));
      return [];
    }
  }

  // 保存下次访问提醒
  async saveReminder(booking: BookingDTO): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }

      const reminder: ReminderData = {
        id: booking.id,
        date: booking.date.toISOString(),
        room: booking.room,
        slot: booking.slot,
        consultantName: booking.consultantName,
        name: booking.name
      };
      await this.dataPreferences.put(REMINDER_KEY, JSON.stringify(reminder));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('保存提醒失败', JSON.stringify(e));
    }
  }

  // 获取下次访问提醒
  async getReminder(): Promise<ReminderData | null> {
    try {
      if (!this.dataPreferences) {
        return null;
      }
      const jsonStr: string = await this.dataPreferences.get(REMINDER_KEY, '') as string;
      if (!jsonStr) {
        return null;
      }
      return JSON.parse(jsonStr) as ReminderData;
    } catch (e) {
      console.error('获取提醒失败', JSON.stringify(e));
      return null;
    }
  }

  // 清除所有数据
  async clearAllData(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }
      this.cachedBookings = [];
      await this.dataPreferences.put(BOOKINGS_KEY, '[]');
      await this.dataPreferences.put(HISTORY_KEY, '[]');
      await this.dataPreferences.delete(REMINDER_KEY);
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('清除数据失败', JSON.stringify(e));
    }
  }

  private isSameDay(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate();
  }

  private formatDate(date: Date): string {
    const year: number = date.getFullYear();
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const day: string = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // BookingService.ets - 确认 cancelBooking 方法存在

  // 取消预约
  async cancelBooking(bookingId: string): Promise<void> {
    const index: number = this.cachedBookings.findIndex((b: BookingDTO) => b.id === bookingId);
    if (index !== -1) {
      this.cachedBookings.splice(index, 1);
      await this.saveBookingsToStorage();
      // 同时更新历史记录
      await this.updateBookingHistory();
    }
  }

  // 更新整个历史记录（用于取消预约后同步）
  private async updateBookingHistory(): Promise<void> {
    try {
      if (!this.dataPreferences) {
        return;
      }

      const historyList: BookingHistorySummary[] = [];
      for (const booking of this.cachedBookings) {
        historyList.push({
          id: booking.id,
          dateStr: this.formatDate(booking.date),
          timestamp: booking.date.getTime(),
          room: booking.room,
          slot: booking.slot,
          consultantName: booking.consultantName
        });
      }
      // 按时间倒序
      historyList.sort((a: BookingHistorySummary, b: BookingHistorySummary) => b.timestamp - a.timestamp);

      await this.dataPreferences.put(HISTORY_KEY, JSON.stringify(historyList));
      await this.dataPreferences.flush();
    } catch (e) {
      console.error('更新预约历史失败', JSON.stringify(e));
    }
  }
}

export { BookingDTO };
