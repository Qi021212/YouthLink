// common/utils/DateUtil.ets

export class DateUtil {

  /**
   * 格式化日期：yyyy-MM-dd
   */
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化日期时间：yyyy-MM-dd HH:mm:ss
   */
  static formatDateTime(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  /**
   * 格式化时间：HH:mm
   */
  static formatTime(date: Date): string {
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 判断是否为同一天
   */
  static isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate();
  }

  /**
   * 判断是否为同一周
   */
  static isSameWeek(date1: Date, date2: Date): boolean {
    const getWeekNumber = (date: Date): number => {
      const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
      const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000;
      return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
    };
    return date1.getFullYear() === date2.getFullYear() &&
      getWeekNumber(date1) === getWeekNumber(date2);
  }

  /**
   * 判断是否为同一个月
   */
  static isSameMonth(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth();
  }

  /**
   * 获取日期差（天数）
   */
  static daysBetween(date1: Date, date2: Date): number {
    const diffTime = Math.abs(date2.getTime() - date1.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  /**
   * 获取星期几（中文）
   */
  static getWeekdayChinese(date: Date): string {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.getDay()];
  }

  /**
   * 获取星期几（数字，周一=1，周日=7）
   */
  static getWeekdayNumber(date: Date): number {
    const day = date.getDay();
    return day === 0 ? 7 : day;
  }

  /**
   * 添加天数
   */
  static addDays(date: Date, days: number): Date {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }

  /**
   * 添加月份
   */
  static addMonths(date: Date, months: number): Date {
    const result = new Date(date);
    result.setMonth(result.getMonth() + months);
    return result;
  }

  /**
   * 获取当月的第一天
   */
  static getFirstDayOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  /**
   * 获取当月的最后一天
   */
  static getLastDayOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0);
  }

  /**
   * 获取时间戳（毫秒）
   */
  static getTimestamp(date: Date): number {
    return date.getTime();
  }

  /**
   * 解析ISO日期字符串
   */
  static parseISO(dateString: string): Date {
    return new Date(dateString);
  }
}