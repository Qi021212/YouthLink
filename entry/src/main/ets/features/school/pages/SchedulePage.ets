import { router, promptAction } from '@kit.ArkUI';
import { ScheduleService } from '../service/ScheduleService';
import {
  ConsultantShift,
  ScheduleAppointment,
  WeekScheduleSummary,
  DayScheduleStats,
  ReminderConfig,
  AvailableSlot
} from '../model/ScheduleModel';

// ================= 工具函数 =================
function getWeekStart(date: Date): Date {
  if (!date) {
    date = new Date();
  }
  const d: Date = new Date(date);
  const day: number = d.getDay();
  d.setDate(d.getDate() - day);
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatDate(d: Date | undefined): string {
  if (!d) {
    return '';
  }
  const year: string = d.getFullYear().toString();
  const month: string = (d.getMonth() + 1).toString().padStart(2, '0');
  const day: string = d.getDate().toString().padStart(2, '0');
  return year + '-' + month + '-' + day;
}

function getStatusText(status: string): string {
  if (status === 'pending') return '待确认';
  if (status === 'confirmed') return '已确认';
  if (status === 'in_progress') return '进行中';
  if (status === 'completed') return '已完成';
  if (status === 'cancelled') return '已取消';
  if (status === 'no_show') return '爽约';
  return status;
}

function getStatusColor(status: string): string {
  if (status === 'pending') return '#FFA726';
  if (status === 'confirmed') return '#4CAF50';
  if (status === 'in_progress') return '#42A5F5';
  if (status === 'completed') return '#78909C';
  if (status === 'cancelled') return '#EF5350';
  if (status === 'no_show') return '#EF5350';
  return '#999999';
}

function getDayName(day: number): string {
  const names: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  return names[day];
}

// ================= 页面组件 =================
@Entry
@Component
struct SchedulePage {
  // ================= 状态 =================
  @State consultantId: string = 'c1';
  @State consultantName: string = '张老师';

  @State weekStart: Date = getWeekStart(new Date());
  @State weekDays: Date[] = [];
  @State appointments: ScheduleAppointment[] = [];

  @State shifts: ConsultantShift[] = [];
  @State showShiftDialog: boolean = false;

  // 添加排班弹窗相关
  @State dialogDayOfWeek: number = 1;
  @State dialogStartTime: string = '09:00';
  @State dialogEndTime: string = '10:00';
  @State dialogRoom: string = '辅导室A';

  @State isLoading: boolean = true;

  @State dayAppointmentsCache: Map<number, ScheduleAppointment[]> = new Map();

  // 强制刷新标志
  @State refreshFlag: number = 0;

  private scheduleService: ScheduleService = ScheduleService.getInstance();

  // ================= 计算属性 =================

  getWeekDisplayText(): string {
    const start: Date = this.weekStart || new Date();
    const end: Date = new Date(start);
    end.setDate(end.getDate() + 6);
    return formatDate(start) + ' ~ ' + formatDate(end);
  }

  // ================= 辅助方法 =================

  isToday(date: Date | undefined): boolean {
    if (!date) {
      return false;
    }
    const today: Date = new Date();
    return date.getFullYear() === today.getFullYear() &&
      date.getMonth() === today.getMonth() &&
      date.getDate() === today.getDate();
  }

  getDayKey(date: Date): number {
    if (!date) {
      return 0;
    }
    return date.getFullYear() * 10000 + date.getMonth() * 100 + date.getDate();
  }

  updateDayCache(): void {
    const newCache: Map<number, ScheduleAppointment[]> = new Map();
    if (!this.weekDays || !this.appointments) {
      this.dayAppointmentsCache = newCache;
      return;
    }
    for (const d of this.weekDays) {
      if (!d) continue;
      const key: number = this.getDayKey(d);
      const dayApps: ScheduleAppointment[] = [];
      for (const a of this.appointments) {
        if (a && a.date.getFullYear() === d.getFullYear() &&
          a.date.getMonth() === d.getMonth() &&
          a.date.getDate() === d.getDate()) {
          dayApps.push(a);
        }
      }
      newCache.set(key, dayApps);
    }
    this.dayAppointmentsCache = newCache;
  }

  getDayAppointments(date: Date | undefined): ScheduleAppointment[] {
    if (!date) {
      return [];
    }
    const key: number = this.getDayKey(date);
    const cached: ScheduleAppointment[] | undefined = this.dayAppointmentsCache.get(key);
    if (cached) {
      return cached;
    }
    const result: ScheduleAppointment[] = [];
    if (!this.appointments) {
      return result;
    }
    for (const a of this.appointments) {
      if (a && a.date.getFullYear() === date.getFullYear() &&
        a.date.getMonth() === date.getMonth() &&
        a.date.getDate() === date.getDate()) {
        result.push(a);
      }
    }
    this.dayAppointmentsCache.set(key, result);
    return result;
  }

  getDayAppointmentCount(date: Date | undefined): number {
    return this.getDayAppointments(date).length;
  }

  hasDayAppointments(date: Date | undefined): boolean {
    return this.getDayAppointments(date).length > 0;
  }

  // ================= 生命周期 =================
  async aboutToAppear(): Promise<void> {
    try {
      this.weekStart = getWeekStart(new Date());
      await this.scheduleService.init(getContext(this));
      await this.loadAllData();
    } catch (e) {
      console.error('初始化失败', JSON.stringify(e));
      this.isLoading = false;
    }
  }

  // ================= 数据加载 =================
  async loadAllData(): Promise<void> {
    this.isLoading = true;
    try {
      const shiftsPromise: Promise<ConsultantShift[]> = this.scheduleService.getShifts(this.consultantId);
      const appointmentsPromise: Promise<ScheduleAppointment[]> = this.scheduleService.getWeekAppointments(
        this.consultantId,
        this.weekStart
      );

      const shiftsResult: ConsultantShift[] = await shiftsPromise;
      const appointmentsResult: ScheduleAppointment[] = await appointmentsPromise;

      this.shifts = shiftsResult || [];
      this.appointments = appointmentsResult || [];

      const weekDaysResult: Date[] = [];
      if (this.weekStart) {
        for (let i: number = 0; i < 7; i++) {
          const d: Date = new Date(this.weekStart);
          d.setDate(d.getDate() + i);
          weekDaysResult.push(d);
        }
      }
      this.weekDays = weekDaysResult;

      this.updateDayCache();

      // 强制刷新：改变 refreshFlag 触发 ForEach 重新渲染
      this.refreshFlag = Date.now();
    } catch (e) {
      console.error('加载数据失败', JSON.stringify(e));
      promptAction.showToast({ message: '加载数据失败' });
    } finally {
      this.isLoading = false;
    }
  }

  // ================= 切换周 =================
  goToPreviousWeek(): void {
    if (!this.weekStart) {
      this.weekStart = new Date();
    }
    const newDate: Date = new Date(this.weekStart);
    newDate.setDate(newDate.getDate() - 7);
    this.weekStart = newDate;
    this.loadAllData();
  }

  goToNextWeek(): void {
    if (!this.weekStart) {
      this.weekStart = new Date();
    }
    const newDate: Date = new Date(this.weekStart);
    newDate.setDate(newDate.getDate() + 7);
    this.weekStart = newDate;
    this.loadAllData();
  }

  goToToday(): void {
    this.weekStart = getWeekStart(new Date());
    this.loadAllData();
  }

  // ================= 预约操作 =================
  async updateStatus(appointmentId: string, status: string, reason?: string): Promise<void> {
    try {
      await this.scheduleService.updateAppointmentStatus(appointmentId, status, reason);
      await this.loadAllData();
      const statusText: string = getStatusText(status);
      promptAction.showToast({ message: statusText + '成功' });
    } catch (e) {
      const err: Error = e as Error;
      promptAction.showToast({ message: err.message || '操作失败' });
    }
  }

  // ================= 添加排班 =================
  async addShift(): Promise<void> {
    if (!this.dialogStartTime || this.dialogStartTime.length < 5) {
      promptAction.showToast({ message: '请输入正确的开始时间，如 09:00' });
      return;
    }
    if (!this.dialogEndTime || this.dialogEndTime.length < 5) {
      promptAction.showToast({ message: '请输入正确的结束时间，如 10:00' });
      return;
    }

    const shift: ConsultantShift = new ConsultantShift();
    shift.dayOfWeek = this.dialogDayOfWeek;
    shift.startTime = this.dialogStartTime;
    shift.endTime = this.dialogEndTime;
    shift.room = this.dialogRoom;
    shift.consultantId = this.consultantId;
    shift.consultantName = this.consultantName;
    shift.isActive = true;

    try {
      await this.scheduleService.addShift(shift);
      await this.loadAllData();
      this.showShiftDialog = false;
      promptAction.showToast({ message: '排班添加成功' });
    } catch (e) {
      console.error('添加排班失败', JSON.stringify(e));
      promptAction.showToast({ message: '添加失败，请重试' });
    }
  }

  // ================= 删除排班 =================
  async deleteShift(shiftId: string): Promise<void> {
    AlertDialog.show({
      title: '删除排班',
      message: '确定要删除这个排班吗？',
      confirm: {
        value: '确定',
        action: async () => {
          try {
            await this.scheduleService.deleteShift(shiftId);
            await this.loadAllData();
            promptAction.showToast({ message: '已删除' });
          } catch (e) {
            console.error('删除排班失败', JSON.stringify(e));
            promptAction.showToast({ message: '删除失败' });
          }
        }
      },
      cancel: () => {}
    });
  }

  // ================= Build =================
  build() {
    Column() {
      this.TitleBar();

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#4CAF50')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Stack() {
          Scroll() {
            Column({ space: 12 }) {
              this.WeekNavigator();
              this.DailySchedule();
              this.ShiftManagement();
            }
            .width('100%')
            .padding(16)
          }
          .scrollBar(BarState.Auto)
          .layoutWeight(1)

          if (this.showShiftDialog) {
            this.AddShiftDialog()
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ================= 标题栏 =================
  @Builder
  TitleBar() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back();
      })

      Text('本周预约与排班')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.refresh'))
          .width(24)
          .height(24)
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.loadAllData();
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
  }

  // ================= 周导航 =================
  @Builder
  WeekNavigator() {
    Column({ space: 8 }) {
      Row() {
        Button('<')
          .fontSize(18)
          .height(36)
          .onClick(() => {
            this.goToPreviousWeek();
          })

        Text(this.getWeekDisplayText())
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('>')
          .fontSize(18)
          .height(36)
          .onClick(() => {
            this.goToNextWeek();
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 4, color: '#1A000000' })

      Button('今天')
        .fontSize(14)
        .height(32)
        .onClick(() => {
          this.goToToday();
        })
    }
    .width('100%')
  }

  // ================= 每日日程 =================
  @Builder
  DailySchedule() {
    Column({ space: 8 }) {
      Text('本周日程')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      if (this.weekDays.length === 0) {
        Text('暂无数据')
          .fontSize(14)
          .fontColor('#999999')
          .padding(16)
      } else {
        ForEach(this.weekDays, (date: Date, index: number) => {
          this.DayItem(date, index)
        }, (date: Date, index: number) => {
          // 使用 refreshFlag 作为 key 的一部分，强制刷新
          return date.getTime().toString() + '_' + this.refreshFlag.toString();
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000' })
  }

  // ================= DayItem =================
  @Builder
  DayItem(date: Date, index: number) {
    Column({ space: 4 }) {
      Row() {
        Text(getDayName(date.getDay()) + ' ' + date.getDate().toString() + '日')
          .fontSize(14)
          .fontWeight(this.isToday(date) ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.isToday(date) ? '#4CAF50' : '#333333')

        Blank()

        Text(this.getDayAppointmentCount(date).toString() + ' 个预约')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')

      if (this.getDayAppointmentCount(date) === 0) {
        Text('暂无预约')
          .fontSize(12)
          .fontColor('#999999')
          .padding({ top: 4, bottom: 4 })
      } else {
        Column({ space: 6 }) {
          ForEach(this.getDayAppointments(date), (app: ScheduleAppointment) => {
            this.AppointmentItem(app)
          }, (app: ScheduleAppointment) => {
            // 使用 app.id 和 refreshFlag 作为 key
            return app.id + '_' + this.refreshFlag.toString();
          })
        }
        .width('100%')
        .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border({
      width: { bottom: index < 6 ? 1 : 0 },
      color: '#EEEEEE'
    })
  }

  // ================= 预约项 =================
  @Builder
  AppointmentItem(app: ScheduleAppointment) {
    Row({ space: 8 }) {
      Column({ space: 2 }) {
        Text(app.startTime)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Text(app.endTime)
          .fontSize(10)
          .fontColor('#999999')
      }
      .width(50)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 2 }) {
        Text(app.studentName + ' · ' + app.studentClass)
          .fontSize(14)
        Text(app.room)
          .fontSize(11)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(getStatusText(app.status))
        .fontSize(11)
        .fontColor(getStatusColor(app.status))
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .borderRadius(12)
        .backgroundColor(getStatusColor(app.status) + '20')

      if (app.status === 'pending') {
        Button('确认')
          .fontSize(11)
          .height(28)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.updateStatus(app.id, 'confirmed');
          })
      } else if (app.status === 'confirmed') {
        Button('开始')
          .fontSize(11)
          .height(28)
          .backgroundColor('#42A5F5')
          .onClick(() => {
            this.updateStatus(app.id, 'in_progress');
          })
      } else if (app.status === 'in_progress') {
        Button('完成')
          .fontSize(11)
          .height(28)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.updateStatus(app.id, 'completed');
          })
      } else if (app.status === 'completed' || app.status === 'cancelled' || app.status === 'no_show') {
        Blank()
          .width(60)
      }
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#F8F9FA')
    .borderRadius(8)
  }

  // ================= 排班管理 =================
  @Builder
  ShiftManagement() {
    Column({ space: 8 }) {
      Row() {
        Text('排班管理')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)

        Blank()

        Button('添加排班')
          .fontSize(12)
          .height(32)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.dialogDayOfWeek = 1;
            this.dialogStartTime = '09:00';
            this.dialogEndTime = '10:00';
            this.dialogRoom = '辅导室A';
            this.showShiftDialog = true;
          })
      }
      .width('100%')

      if (this.shifts.length === 0) {
        Text('暂无排班，请添加')
          .fontSize(14)
          .fontColor('#999999')
          .padding(16)
      } else {
        Column({ space: 4 }) {
          ForEach(this.shifts, (shift: ConsultantShift) => {
            this.ShiftItem(shift)
          }, (shift: ConsultantShift) => {
            return shift.id;
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000' })
  }

  // ================= 添加排班弹窗 =================
  @Builder
  AddShiftDialog() {
    Column() {
      Column({ space: 12 }) {
        Text('添加排班')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .alignSelf(ItemAlign.Start)

        Row() {
          Text('星期')
            .fontSize(14)
            .width(60)

          Select([
            { value: '周一', icon: '' },
            { value: '周二', icon: '' },
            { value: '周三', icon: '' },
            { value: '周四', icon: '' },
            { value: '周五', icon: '' },
            { value: '周六', icon: '' },
            { value: '周日', icon: '' }
          ])
            .selected(this.dialogDayOfWeek - 1)
            .width(120)
            .onSelect((index: number) => {
              this.dialogDayOfWeek = index + 1;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Row() {
          Text('开始时间')
            .fontSize(14)
            .width(60)

          TextInput({ placeholder: '09:00', text: this.dialogStartTime })
            .fontSize(14)
            .width(120)
            .height(36)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 8, right: 8 })
            .onChange((value: string) => {
              this.dialogStartTime = value;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Row() {
          Text('结束时间')
            .fontSize(14)
            .width(60)

          TextInput({ placeholder: '10:00', text: this.dialogEndTime })
            .fontSize(14)
            .width(120)
            .height(36)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .padding({ left: 8, right: 8 })
            .onChange((value: string) => {
              this.dialogEndTime = value;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Row() {
          Text('辅导室')
            .fontSize(14)
            .width(60)

          Select([
            { value: '辅导室A', icon: '' },
            { value: '辅导室B', icon: '' },
            { value: '辅导室C', icon: '' }
          ])
            .selected(0)
            .value(this.dialogRoom)
            .width(120)
            .onSelect((index: number) => {
              const rooms: string[] = ['辅导室A', '辅导室B', '辅导室C'];
              this.dialogRoom = rooms[index];
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14)
            .height(36)
            .layoutWeight(1)
            .backgroundColor('#EEEEEE')
            .fontColor('#333333')
            .onClick(() => {
              this.showShiftDialog = false;
            })

          Button('确认添加')
            .fontSize(14)
            .height(36)
            .layoutWeight(1)
            .backgroundColor('#4CAF50')
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.addShift();
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 12, color: '#1A000000' })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
  }

  // ================= 辅助：获取星期文字 =================
  getDayNameText(day: number): string {
    const names: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[day - 1] || '周一';
  }

  // ================= 排班项 =================
  @Builder
  ShiftItem(shift: ConsultantShift) {
    Row({ space: 8 }) {
      Text('周' + getDayName(shift.dayOfWeek))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .width(40)

      Text(shift.startTime + '-' + shift.endTime)
        .fontSize(12)

      Text(shift.room)
        .fontSize(12)
        .fontColor('#666666')
        .layoutWeight(1)

      Button('删除')
        .fontSize(10)
        .height(24)
        .backgroundColor('#EF5350')
        .onClick(() => {
          this.deleteShift(shift.id);
        })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}

export default SchedulePage;