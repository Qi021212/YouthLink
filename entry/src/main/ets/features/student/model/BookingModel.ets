// 咨询师排班信息
export interface ConsultantShiftDTO {
  id: string;
  room: string;
  slot: string;
  consultantId: string;
  consultantName: string;
}

// 预约记录
export interface BookingDTO {
  id: string;
  name: string;
  clazz: string;
  dorm: string;
  room: string;
  slot: string;
  date: Date;
  consultantId: string;
  consultantName: string;
}

// 咨询师信息
export interface ConsultantInfo {
  id: string;
  name: string;
}

// 提醒数据（用于持久化存储）
export interface ReminderData {
  id: string;
  date: string;
  room: string;
  slot: string;
  consultantName: string;
  name: string;
}

// 历史记录摘要（用于首页展示）
export interface BookingHistorySummary {
  id: string;
  dateStr: string;
  timestamp: number;
  room: string;
  slot: string;
  consultantName: string;
}