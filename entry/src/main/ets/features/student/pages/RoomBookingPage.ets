import { router, promptAction } from '@kit.ArkUI';
import { DateUtil } from '../../../common/utils/DateUtil';
import { getString, putObject } from '../../../common/utils/StorageUtil';
import { BookingService } from '../service/BookingService';
import { BookingDTO, ConsultantShiftDTO, ConsultantInfo, ReminderData } from '../model/BookingModel';

// ================= 工具函数 =================

function isSameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();
}

function generateUUID(): string {
  let result: string = '';
  const characters: string = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
  for (let i = 0; i < characters.length; i++) {
    const c: string = characters.charAt(i);
    if (c === 'x' || c === 'y') {
      const r: number = Math.random() * 16 | 0;
      const v: number = c === 'x' ? r : (r & 0x3 | 0x8);
      result += v.toString(16);
    } else {
      result += c;
    }
  }
  return result;
}

function getButtonColor(shift: ConsultantShiftDTO | undefined, isSelected: boolean, busy: boolean): ResourceColor {
  if (isSelected) {
    return '#4CAF50';
  }
  if (busy) {
    return '#FFE4E4';
  }
  if (shift !== undefined) {
    return '#E8F5E9';
  }
  return '#F5F5F5';
}

function getButtonFontColor(isSelected: boolean, busy: boolean): ResourceColor {
  if (isSelected) {
    return '#FFFFFF';
  }
  if (busy) {
    return '#FF6B6B';
  }
  return '#333333';
}

function getOccupiedMap(bookings: BookingDTO[], shifts: ConsultantShiftDTO[], selectedDate: Date): Map<string, BookingDTO> {
  const occupied: Map<string, BookingDTO> = new Map();
  for (const booking of bookings) {
    if (isSameDay(booking.date, selectedDate)) {
      for (const shift of shifts) {
        if (shift.room === booking.room && shift.slot === booking.slot) {
          occupied.set(shift.id, booking);
          break;
        }
      }
    }
  }
  return occupied;
}

function getTodayBookings(bookings: BookingDTO[], selectedDate: Date): BookingDTO[] {
  const result: BookingDTO[] = [];
  for (const booking of bookings) {
    if (isSameDay(booking.date, selectedDate)) {
      result.push(booking);
    }
  }
  return result;
}

function findShift(shifts: ConsultantShiftDTO[], room: string, slot: string): ConsultantShiftDTO | undefined {
  for (const s of shifts) {
    if (s.room === room && s.slot === slot) {
      return s;
    }
  }
  return undefined;
}

function isAvailable(shift: ConsultantShiftDTO | undefined, occupied: Map<string, BookingDTO>): boolean {
  return shift !== undefined && !occupied.has(shift.id);
}

function getAvailableCount(shifts: ConsultantShiftDTO[], occupied: Map<string, BookingDTO>): number {
  let count: number = 0;
  for (const shift of shifts) {
    if (!occupied.has(shift.id)) {
      count++;
    }
  }
  return count;
}

// ================= 页面组件 =================

@Entry
@Component
struct RoomBookingPage {
  @State studentName: string = '';
  @State studentClass: string = '';
  @State studentDorm: string = '';

  @State selectedDate: Date = new Date();
  @State selectedShift: ConsultantShiftDTO | null = null;
  @State isLoading: boolean = true;
  @State isSubmitting: boolean = false;
  @State onlyAvailable: boolean = false;
  @State bookings: BookingDTO[] = [];
  @State shifts: ConsultantShiftDTO[] = [];

  private readonly roomsOrder: string[] = ['辅导室A', '辅导室B', '辅导室C'];
  private readonly slotsOrder: string[] = [
    '09:00-10:00', '10:00-11:00', '14:00-15:00', '15:00-16:00', '19:00-20:00'
  ];
  private readonly nextVisitKey: string = 'next_visit_reminder';
  private bookingService: BookingService = BookingService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.bookingService.init(getContext(this));
    this.loadStudentInfo();
    this.loadAllData();
  }

  async loadStudentInfo(): Promise<void> {
    try {
      const name = await getString('user_name', '');
      const clazz = await getString('user_class', '');
      const dorm = await getString('user_dorm', '');

      if (name) {
        this.studentName = name;
      }
      if (clazz) {
        this.studentClass = clazz;
      }
      if (dorm) {
        this.studentDorm = dorm;
      }
    } catch (e) {
      console.error('加载学生信息失败', JSON.stringify(e));
    }
  }

  async loadAllData(): Promise<void> {
    this.isLoading = true;
    try {
      const bookings: BookingDTO[] = await this.bookingService.getBookings();
      const shifts: ConsultantShiftDTO[] = await this.bookingService.getConsultantShifts(this.selectedDate);
      this.bookings = bookings;
      this.shifts = shifts;
      this.selectedShift = null;
    } catch (e) {
      console.error('加载数据失败', JSON.stringify(e));
      this.bookings = [];
      this.shifts = [];
    } finally {
      this.isLoading = false;  // 只有数据加载完才设为 false
    }
  }
  async submitBooking(): Promise<void> {
    if (this.selectedShift === null) {
      promptAction.showToast({ message: '请先选择预约时段' });
      return;
    }

    const occupied: Map<string, BookingDTO> = getOccupiedMap(this.bookings, this.shifts, this.selectedDate);
    if (occupied.has(this.selectedShift.id)) {
      promptAction.showToast({ message: '该时段已被预约' });
      return;
    }

    if (!this.studentName || this.studentName.trim().length === 0) {
      promptAction.showToast({ message: '请输入姓名' });
      return;
    }

    const newBooking: BookingDTO = {
      id: generateUUID(),
      name: this.studentName.trim(),
      clazz: this.studentClass,
      dorm: this.studentDorm,
      room: this.selectedShift.room,
      slot: this.selectedShift.slot,
      date: new Date(this.selectedDate),
      consultantId: this.selectedShift.consultantId,
      consultantName: this.selectedShift.consultantName
    };

    this.isSubmitting = true;
    try {
      await this.bookingService.createBooking(newBooking);
      await this.bookingService.saveReminder(newBooking);
      await this.loadAllData();
      promptAction.showToast({ message: '预约成功' });
    } catch (e) {
      console.error('预约失败', JSON.stringify(e));
      promptAction.showToast({ message: '预约失败，请重试' });
    } finally {
      this.isSubmitting = false;
    }
  }

  // 取消预约
  async cancelBooking(bookingId: string): Promise<void> {
    AlertDialog.show({
      title: '取消预约',
      message: '确定要取消这个预约吗？',
      confirm: {
        value: '确定',
        action: async () => {
          try {
            await this.bookingService.cancelBooking(bookingId);
            await this.loadAllData();
            promptAction.showToast({ message: '取消预约成功' });
          } catch (e) {
            console.error('取消预约失败', JSON.stringify(e));
            promptAction.showToast({ message: '取消预约失败' });
          }
        }
      },
      cancel: () => {}
    });
  }

  build() {
    Column() {
      // 标题栏
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

        Text('情感辅导预约')
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
        Scroll() {
          Column({ space: 12 }) {
            // 日期卡片
            this.DateCard()
            // 排班卡片
            this.ShiftCard()
            // 表单卡片
            this.FormCard()
            // 列表卡片
            this.ListCard()
          }
          .width('100%')
          .padding(16)
        }
        .scrollBar(BarState.Auto)
        .scrollable(ScrollDirection.Vertical)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  DateCard() {
    Row() {
      Image($r('app.media.calendar'))
        .width(24)
        .height(24)
        .margin({ right: 12 })

      Column({ space: 4 }) {
        Text(DateUtil.formatDate(this.selectedDate))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Text('当前预约日期')
          .fontSize(12)
          .fontColor('#666666')
      }

      Blank()

      Button('更改')
        .fontSize(14)
        .height(36)
        .onClick(() => {
          const currentDate: Date = new Date();
          const minDate: Date = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
          const maxDate: Date = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate() + 30);

          DatePickerDialog.show({
            selected: this.selectedDate,
            start: minDate,
            end: maxDate,
            onAccept: (value: DatePickerResult) => {
              const year: number = value.year ?? this.selectedDate.getFullYear();
              const month: number = (value.month !== undefined) ? value.month: this.selectedDate.getMonth();
              const day: number = value.day ?? this.selectedDate.getDate();
              this.selectedDate = new Date(year, month, day);
              this.loadAllData();
            }
          });
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000' })
  }

  @Builder
  ShiftCard() {
    Column({ space: 12 }) {
      Row() {
        Text('当日咨询师排班')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%')

      ForEach(this.roomsOrder, (room: string) => {
        Column({ space: 8 }) {
          Text(room)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)

          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
            ForEach(this.slotsOrder, (slot: string) => {
              this.SlotButton(room, slot)
            })
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .margin({ bottom: 12 })
      })

      if (this.selectedShift !== null) {
        Row({ space: 4 }) {
          Text('✅')
            .fontSize(12)
          Text(`已选择：${this.selectedShift.room} · ${this.selectedShift.slot} · ${this.selectedShift.consultantName}`)
            .fontSize(12)
            .fontColor('#4CAF50')
        }
        .margin({ top: 8 })
        .padding(8)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000' })
  }

  @Builder
  SlotButton(room: string, slot: string) {
    // 所有计算都在函数调用中完成，不声明局部变量
    Button() {
      Column({ space: 2 }) {
        Text(slot)
          .fontSize(12)
        Text(findShift(this.shifts, room, slot)?.consultantName ?? '无排班')
          .fontSize(10)
          .fontColor(
            this.selectedShift !== null &&
              findShift(this.shifts, room, slot) !== undefined &&
              this.selectedShift!.id === findShift(this.shifts, room, slot)!.id
              ? '#FFFFFF'
              : findShift(this.shifts, room, slot) !== undefined &&
              getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(findShift(this.shifts, room, slot)!.id)
              ? '#FF6B6B'
              : findShift(this.shifts, room, slot) !== undefined
                ? '#4CAF50'
                : '#999999'
          )
      }
      .padding({ top: 8, bottom: 8 })
    }
    .backgroundColor(
      getButtonColor(
        findShift(this.shifts, room, slot),
        this.selectedShift !== null &&
          findShift(this.shifts, room, slot) !== undefined &&
          this.selectedShift!.id === findShift(this.shifts, room, slot)!.id,
        findShift(this.shifts, room, slot) !== undefined &&
          getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(findShift(this.shifts, room, slot)!.id)
      )
    )
    .fontColor(
      getButtonFontColor(
        this.selectedShift !== null &&
          findShift(this.shifts, room, slot) !== undefined &&
          this.selectedShift!.id === findShift(this.shifts, room, slot)!.id,
        findShift(this.shifts, room, slot) !== undefined &&
          getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(findShift(this.shifts, room, slot)!.id)
      )
    )
    .borderRadius(20)
    .padding({ left: 16, right: 16 })
    .constraintSize({ minHeight: 44 })
    .enabled(
      findShift(this.shifts, room, slot) !== undefined &&
        !getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(findShift(this.shifts, room, slot)!.id)
    )
    .visibility(
      this.onlyAvailable &&
        !(findShift(this.shifts, room, slot) !== undefined &&
          !getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(findShift(this.shifts, room, slot)!.id))
        ? Visibility.Hidden : Visibility.Visible
    )
    .onClick(() => {
      if (findShift(this.shifts, room, slot) !== undefined &&
        !getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(findShift(this.shifts, room, slot)!.id)) {
        this.selectedShift = findShift(this.shifts, room, slot)!;
      }
    })
  }

  @Builder
  FormCard() {
    Column({ space: 12 }) {
      Text('预约信息')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '姓名*', text: this.studentName })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.studentName = value;
        })

      TextInput({ placeholder: '班级', text: this.studentClass })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.studentClass = value;
        })

      TextInput({ placeholder: '寝室', text: this.studentDorm })
        .width('100%')
        .height(44)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.studentDorm = value;
        })

      Button(this.isSubmitting ? '提交中...' : '提交预约')
        .width('100%')
        .height(44)
        .backgroundColor(
          this.selectedShift === null ||
            (this.selectedShift !== null &&
              getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(this.selectedShift.id)) ||
            this.isSubmitting
            ? '#CCCCCC' : '#4CAF50'
        )
        .fontColor('#FFFFFF')
        .borderRadius(8)
        .enabled(
          this.selectedShift !== null &&
            !getOccupiedMap(this.bookings, this.shifts, this.selectedDate).has(this.selectedShift.id) &&
            !this.isSubmitting
        )
        .onClick(() => {
          this.submitBooking();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000' })
  }

  // RoomBookingPage.ets - 修改 ListCard 方法

  @Builder
  ListCard() {
    Column({ space: 12 }) {
      Row() {
        Text('预约列表')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(`可预约：${getAvailableCount(this.shifts, getOccupiedMap(this.bookings, this.shifts, this.selectedDate))}/${this.shifts.length}`)
          .fontSize(12)
          .fontColor('#4CAF50')
      }
      .width('100%')

      if (getTodayBookings(this.bookings, this.selectedDate).length === 0) {
        Text('当前日期暂无预约')
          .fontSize(14)
          .fontColor('#999999')
          .padding(16)
      } else {
        List({ space: 10 }) {
          ForEach(getTodayBookings(this.bookings, this.selectedDate), (booking: BookingDTO) => {
            ListItem() {
              Row() {
                Image($r('app.media.event_available'))
                  .width(20)
                  .height(20)
                  .margin({ right: 12 })

                Column({ space: 2 }) {
                  Text(`${booking.room} · ${booking.slot}`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                  Text(`咨询师：${booking.consultantName} · 预约人：${booking.name}`)
                    .fontSize(12)
                    .fontColor('#666666')
                }

                Blank()

                // 添加取消按钮
                Button('取消')
                  .fontSize(12)
                  .height(32)
                  .backgroundColor('#FF6B6B')
                  .borderRadius(16)
                  .padding({ left: 12, right: 12 })
                  .onClick(() => {
                    this.cancelBooking(booking.id);
                  })
              }
              .width('100%')
              .padding(12)
            }
            .swipeAction({ end: this.getDeleteSwipeAction(booking) }) // 添加左滑删除
          }, (booking: BookingDTO) => booking.id)
        }
        .width('100%')
        .height(300)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000' })
  }

  @Builder
  getDeleteSwipeAction(booking: BookingDTO) {
    Row() {
      Button('删除')
        .width(80)
        .height('100%')
        .backgroundColor('#FF6B6B')
        .fontColor('#FFFFFF')
        .fontSize(14)
        .borderRadius(0)
        .onClick(() => {
          this.cancelBooking(booking.id);
        })
    }
    .width(80)
    .height('100%')
  }
}

export default RoomBookingPage;