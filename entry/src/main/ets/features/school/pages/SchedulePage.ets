import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { Appointment, AppointmentStatus, ScheduleSlot } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { StatusChip } from '../../../common/components/StatusChip'

@Entry
@Component
struct SchedulePage {
  @State todayAppointments: Appointment[] = []
  @State weekSchedule: ScheduleSlot[] = []
  @State selectedDateIndex: number = -1
  private service: SchoolService = new SchoolService()

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    const appointments: Appointment[] = await this.service.fetchTodayAppointments()
    this.todayAppointments = appointments
    const schedule: ScheduleSlot[] = await this.service.fetchWeekSchedule()
    this.weekSchedule = schedule
  }

  private getUniqueDates(): string[] {
    const result: string[] = []
    for (let i = 0; i < this.weekSchedule.length; i++) {
      const date: string = this.weekSchedule[i].date
      let found: boolean = false
      for (let j = 0; j < result.length; j++) {
        if (result[j] === date) { found = true; break }
      }
      if (!found) { result.push(date) }
    }
    return result
  }

  private getUniqueTimes(): string[] {
    const result: string[] = []
    for (let i = 0; i < this.weekSchedule.length; i++) {
      const timeRange: string = this.weekSchedule[i].timeRange
      let found: boolean = false
      for (let j = 0; j < result.length; j++) {
        if (result[j] === timeRange) { found = true; break }
      }
      if (!found) { result.push(timeRange) }
    }
    return result
  }

  private getSlot(date: string, timeRange: string): ScheduleSlot | null {
    for (let i = 0; i < this.weekSchedule.length; i++) {
      const slot: ScheduleSlot = this.weekSchedule[i]
      if (slot.date === date && slot.timeRange === timeRange) { return slot }
    }
    return null
  }

  private hasSlot(date: string, timeRange: string): boolean {
    return this.getSlot(date, timeRange) !== null
  }

  private isSlotBooked(date: string, timeRange: string): boolean {
    const slot: ScheduleSlot | null = this.getSlot(date, timeRange)
    return slot !== null && slot.isBooked
  }

  private getAppointmentStatusLabel(status: AppointmentStatus): string {
    if (status === AppointmentStatus.BOOKED) return '已预约'
    if (status === AppointmentStatus.IN_PROGRESS) return '进行中'
    if (status === AppointmentStatus.COMPLETED) return '已完成'
    return '已取消'
  }

  private getAppointmentStatusType(status: AppointmentStatus): string {
    if (status === AppointmentStatus.BOOKED) return 'info'
    if (status === AppointmentStatus.IN_PROGRESS) return 'warning'
    if (status === AppointmentStatus.COMPLETED) return 'success'
    return 'default'
  }

  build() {
    Column() {
      this.buildTopBar()
      Scroll() {
        Column() {
          this.buildWeekDateRow()
          this.buildTodaySection()
          this.buildWeekScheduleSection()
        }
        .padding({ bottom: 30 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  buildTopBar(): void {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .onClick(() => { router.back() })
      Text('预约排班管理')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16, top: 24 })
    .backgroundColor(Colors.PRIMARY)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildWeekDateRow(): void {
    Column() {
      Text('本周')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .alignSelf(ItemAlign.Start)
        .padding({ left: 16, top: 16, bottom: 8 })
      Scroll() {
        Row() {
          ForEach(this.getUniqueDates(), (date: string, index: number) => {
            Column() {
              Text(date)
                .fontSize(13)
                .fontWeight(this.selectedDateIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.selectedDateIndex === index ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)
            }
            .width(72)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.selectedDateIndex === index ? Colors.PRIMARY : Colors.SURFACE)
            .borderRadius(10)
            .margin({ right: 8 })
            .onClick(() => { this.selectedDateIndex = index })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildTodaySection(): void {
    Column() {
      Row() {
        Text('今日预约')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
        Text(this.todayAppointments.length + ' 条')
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20, bottom: 10 })

      ForEach(this.todayAppointments, (appointment: Appointment, index: number) => {
        this.buildAppointmentCard(appointment)
      }, (appointment: Appointment) => appointment.appointmentId)

      if (this.todayAppointments.length === 0) {
        Text('暂无今日预约')
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)
          .padding({ top: 16, bottom: 16 })
      }
    }
    .width('100%')
  }

  @Builder
  buildAppointmentCard(appointment: Appointment): void {
    Column() {
      Row() {
        Column() {
          Text(appointment.timeSlot)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.PRIMARY)
        }
        .width(80)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Colors.PRIMARY + '12')
        .borderRadius(8)

        Column() {
          Text(appointment.studentName)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
          Text(appointment.reason)
            .fontSize(12)
            .fontColor(Colors.TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)

        Column() {
          StatusChip({ label: this.getAppointmentStatusLabel(appointment.status), type: this.getAppointmentStatusType(appointment.status) })
          Text(appointment.counselor)
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(12)
    .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 1 })
    .margin({ left: 16, right: 16, bottom: 10 })
  }

  @Builder
  buildWeekScheduleSection(): void {
    Column() {
      Text('本周排班')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .alignSelf(ItemAlign.Start)
        .padding({ left: 16, top: 20, bottom: 10 })

      Column() {
        Row() {
          Column().width(52)
          ForEach(this.getUniqueDates(), (date: string) => {
            Text(date)
              .fontSize(11)
              .fontColor(Colors.TEXT_SECONDARY)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 6 })

        ForEach(this.getUniqueTimes(), (timeRange: string) => {
          Row() {
            Text(timeRange)
              .fontSize(11)
              .fontColor(Colors.TEXT_HINT)
              .width(52)
            ForEach(this.getUniqueDates(), (date: string) => {
              this.buildScheduleCell(date, timeRange)
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 2 })
        })
      }
      .width('100%')
      .padding({ top: 8, bottom: 12 })
      .backgroundColor(Colors.CARD_BG)
      .borderRadius(14)
      .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 1 })
      .margin({ left: 16, right: 16 })

      Row() {
        Row() {
          Column().width(12).height(12).borderRadius(3).backgroundColor(Colors.PRIMARY)
          Text('已预约').fontSize(12).fontColor(Colors.TEXT_SECONDARY).margin({ left: 4 })
        }
        .margin({ right: 16 })
        Row() {
          Column().width(12).height(12).borderRadius(3).backgroundColor('#E5E7EB')
          Text('空闲').fontSize(12).fontColor(Colors.TEXT_SECONDARY).margin({ left: 4 })
        }
      }
      .width('100%')
      .padding({ left: 16, top: 10, bottom: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  @Builder
  buildScheduleCell(date: string, timeRange: string): void {
    Column() {
      if (this.hasSlot(date, timeRange)) {
        if (this.isSlotBooked(date, timeRange)) {
          Text('已约')
            .fontSize(10)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(4)
            .backgroundColor(Colors.PRIMARY)
        } else {
          Text('空闲')
            .fontSize(10)
            .fontColor(Colors.TEXT_HINT)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(4)
            .backgroundColor('#E5E7EB')
        }
      }
    }
    .height(30)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .borderRadius(6)
    .backgroundColor(this.isSlotBooked(date, timeRange) ? Colors.PRIMARY + '18' : '#F9FAFB')
    .margin(2)
  }
}
