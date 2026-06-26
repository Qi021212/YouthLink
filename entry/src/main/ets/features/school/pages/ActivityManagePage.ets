import { router, promptAction } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { StatusChip } from '../../../common/components/StatusChip'
import { Activity, ActivityStatus, EfficiencyReport } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { ActivityEditFields } from '../../../common/utils/ActivityDBHelper'

class FilterTab {
  label: string = ''
  value: number = 0
  constructor(label: string, value: number) {
    this.label = label
    this.value = value
  }
}

@Entry
@Component
struct ActivityManagePage {
  @State activities: Activity[] = []
  @State isLoading: boolean = true
  @State currentFilter: number = -1
  @State showEfficiencySheet: boolean = false
  @State efficiencyReport: EfficiencyReport | null = null
  @State currentActivityTitle: string = ''
  // 编辑面板状态
  @State showEditSheet: boolean = false
  @State editId: string = ''
  @State editTitle: string = ''
  @State editType: string = ''
  @State editStartTime: string = ''
  @State editEndTime: string = ''
  @State editLocation: string = ''
  @State editStatus: ActivityStatus = ActivityStatus.DRAFT
  private service: SchoolService = new SchoolService()

  private filterTabs: FilterTab[] = [
    new FilterTab('全部', -1),
    new FilterTab('进行中', ActivityStatus.IN_PROGRESS),
    new FilterTab('已批准', ActivityStatus.APPROVED),
    new FilterTab('已完成', ActivityStatus.COMPLETED),
    new FilterTab('草稿', ActivityStatus.DRAFT)
  ]

  async aboutToAppear(): Promise<void> {
    await this.loadActivities()
  }

  // 从其它页面返回时刷新，让学生新报名的人数变化即时反映
  async onPageShow(): Promise<void> {
    await this.loadActivities()
  }

  async loadActivities(): Promise<void> {
    try {
      this.activities = await this.service.fetchActivities(getContext(this) as common.Context)
    } catch (e) {
      this.activities = []
    } finally {
      this.isLoading = false
    }
  }

  // 打开编辑面板，回填当前活动信息
  openEdit(item: Activity): void {
    this.editId = item.activityId
    this.editTitle = item.title
    this.editType = item.type
    this.editStartTime = item.startDate
    this.editEndTime = item.endDate
    this.editLocation = this.extractLocation(item.description)
    this.editStatus = item.status
    this.showEditSheet = true
  }

  // 描述形如 "面向「X」状态学生 · 地点：YYY"，取出地点部分回填
  private extractLocation(desc: string): string {
    const marker: string = '地点：'
    const idx: number = desc.indexOf(marker)
    if (idx >= 0) {
      return desc.substring(idx + marker.length)
    }
    return ''
  }

  // 起止相同（单时间点）只显示一个时间，否则显示时间段
  private formatTimeRange(start: string, end: string): string {
    if (end.length === 0 || start === end) {
      return start
    }
    return start + ' ~ ' + end
  }

  async saveEdit(): Promise<void> {
    if (this.editTitle.trim().length === 0) {
      promptAction.showToast({ message: '活动标题不能为空' })
      return
    }
    // 起止时间合并为 "开始 ~ 结束" 写回；结束留空则按单时间点存
    const timeText: string = this.editEndTime.trim().length > 0
      ? this.editStartTime.trim() + ' ~ ' + this.editEndTime.trim()
      : this.editStartTime.trim()
    const fields: ActivityEditFields = {
      title: this.editTitle,
      type: this.editType,
      time: timeText,
      location: this.editLocation
    }
    const ok: boolean = await this.service.updateActivity(this.editId, fields, getContext(this) as common.Context)
    // 状态变更单独持久化（学校端覆盖值，仅在活动开始前生效）
    await this.service.setActivityStatus(this.editId, this.editStatus)
    this.showEditSheet = false
    promptAction.showToast({ message: ok ? '已保存，学生端同步更新' : '保存失败' })
    await this.loadActivities()
  }

  async approveActivity(): Promise<void> {
    await this.service.setActivityStatus(this.editId, ActivityStatus.APPROVED)
    this.editStatus = ActivityStatus.APPROVED
    this.showEditSheet = false
    promptAction.showToast({ message: '活动已批准' })
    await this.loadActivities()
  }

  private getFilteredActivities(): Activity[] {
    if (this.currentFilter === -1) return this.activities
    return this.activities.filter((item: Activity) => item.status === this.currentFilter)
  }

  private getStatusType(status: ActivityStatus): string {
    if (status === ActivityStatus.DRAFT) return 'default'
    if (status === ActivityStatus.APPROVED) return 'info'
    if (status === ActivityStatus.IN_PROGRESS) return 'warning'
    if (status === ActivityStatus.COMPLETED) return 'success'
    return 'default'
  }

  private getStatusLabel(status: ActivityStatus): string {
    if (status === ActivityStatus.DRAFT) return '草稿'
    if (status === ActivityStatus.APPROVED) return '已批准'
    if (status === ActivityStatus.IN_PROGRESS) return '进行中'
    if (status === ActivityStatus.COMPLETED) return '已完成'
    return '未知'
  }

  private getFilterBgColor(value: number): string {
    if (this.currentFilter === value) return Colors.PRIMARY
    return '#F3F4F6'
  }

  private getFilterTextColor(value: number): string {
    if (this.currentFilter === value) return Colors.TEXT_ON_PRIMARY
    return Colors.TEXT_SECONDARY
  }

  @Builder
  ActivityCard(item: Activity) {
    Column() {
      Row() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)
        StatusChip({ label: this.getStatusLabel(item.status), type: this.getStatusType(item.status) })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(item.type)
          .fontSize(12)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .backgroundColor(Colors.PRIMARY_LIGHT)
        Text(' ')
        Text(this.formatTimeRange(item.startDate, item.endDate))
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
      }
      .margin({ top: 8 })

      Text(item.description)
        .fontSize(14)
        .fontColor(Colors.TEXT_SECONDARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')

      Row() {
        Text(item.participants.toString())
          .fontSize(13)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        Text(' 人参加')
          .fontSize(13)
          .fontColor(Colors.TEXT_SECONDARY)
        Text('  ·  ')
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)
        Text('★ ' + item.satisfaction.toFixed(1))
          .fontSize(13)
          .fontColor('#F59E0B')
          .fontWeight(FontWeight.Medium)
        Text(' 学生评分')
          .fontSize(11)
          .fontColor(Colors.TEXT_HINT)

        Blank()

        if (item.status === ActivityStatus.IN_PROGRESS || item.status === ActivityStatus.COMPLETED) {
          Row() {
            Text('效能报告')
              .fontSize(13)
              .fontColor(Colors.PRIMARY)
              .fontWeight(FontWeight.Medium)
            Text(' →')
              .fontSize(13)
              .fontColor(Colors.PRIMARY)
          }
          .onClick(() => {
            this.currentActivityTitle = item.title
            this.loadEfficiencyReport(item.activityId)
          })
        }
      }
      .width('100%')
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(12)
    .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.openEdit(item)
    })
  }

  async loadEfficiencyReport(activityId: string): Promise<void> {
    try {
      this.efficiencyReport = await this.service.fetchEfficiencyReport(activityId, getContext(this) as common.Context)
    } catch (e) {
      this.efficiencyReport = null
    }
    this.showEfficiencySheet = true
  }

  @Builder
  EfficiencyReportSheet() {
    Column() {
      Column() {
        Column() {
          Row() {
            Text('效能报告')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Blank()
            Text('✕')
              .fontSize(18)
              .fontColor(Colors.TEXT_HINT)
              .onClick(() => { this.showEfficiencySheet = false })
          }
          .width('100%')

          Text(this.currentActivityTitle)
            .fontSize(13)
            .fontColor(Colors.TEXT_HINT)
            .margin({ top: 4 })
        }
        .width('100%')
        .margin({ bottom: 20 })

        if (this.efficiencyReport !== null) {
          Row() {
            this.StatItem('参加人数', this.efficiencyReport.totalParticipants.toString())
            this.StatItem('平均满意度', this.efficiencyReport.avgSatisfaction.toFixed(1) + ' ★')
            this.StatItem('完成率', (this.efficiencyReport.completionRate * 100).toFixed(0) + '%')
            this.StatItem('推荐率', (this.efficiencyReport.recommendationRate * 100).toFixed(0) + '%')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Colors.CARD_BG)
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  EditSheet() {
    Column() {
      Column() {
        Row() {
          Text('编辑活动')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor(Colors.TEXT_HINT)
            .onClick(() => { this.showEditSheet = false })
        }
        .width('100%')
        .margin({ bottom: 20 })

        Text('活动标题')
          .fontSize(13).fontColor(Colors.TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start).margin({ bottom: 6 })
        TextInput({ text: this.editTitle })
          .fontSize(15).backgroundColor('#F3F4F6').borderRadius(10).height(44)
          .margin({ bottom: 14 })
          .onChange((v: string) => { this.editTitle = v })

        Text('活动类型')
          .fontSize(13).fontColor(Colors.TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start).margin({ bottom: 6 })
        TextInput({ text: this.editType })
          .fontSize(15).backgroundColor('#F3F4F6').borderRadius(10).height(44)
          .margin({ bottom: 14 })
          .onChange((v: string) => { this.editType = v })

        Text('开始时间')
          .fontSize(13).fontColor(Colors.TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start).margin({ bottom: 6 })
        TextInput({ text: this.editStartTime, placeholder: '2026-06-12 19:00' })
          .fontSize(15).backgroundColor('#F3F4F6').borderRadius(10).height(44)
          .margin({ bottom: 14 })
          .onChange((v: string) => { this.editStartTime = v })

        Text('结束时间')
          .fontSize(13).fontColor(Colors.TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start).margin({ bottom: 6 })
        TextInput({ text: this.editEndTime, placeholder: '2026-06-12 21:00' })
          .fontSize(15).backgroundColor('#F3F4F6').borderRadius(10).height(44)
          .margin({ bottom: 14 })
          .onChange((v: string) => { this.editEndTime = v })

        Text('活动地点')
          .fontSize(13).fontColor(Colors.TEXT_SECONDARY)
          .alignSelf(ItemAlign.Start).margin({ bottom: 6 })
        TextInput({ text: this.editLocation })
          .fontSize(15).backgroundColor('#F3F4F6').borderRadius(10).height(44)
          .margin({ bottom: 14 })
          .onChange((v: string) => { this.editLocation = v })

        Row() {
          Button('批准活动')
            .fontSize(15)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.SUCCESS)
            .borderRadius(10)
            .height(46)
            .layoutWeight(1)
            .onClick(() => { this.approveActivity() })

          Button('保存修改')
            .fontSize(15)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.PRIMARY)
            .borderRadius(10)
            .height(46)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => { this.saveEdit() })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .width('100%')
      .padding(24)
      .backgroundColor(Colors.CARD_BG)
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  StatItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.PRIMARY)
      Text(label)
        .fontSize(12)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .padding(12)
    .borderRadius(10)
    .backgroundColor('#F0F4FF')
    .layoutWeight(1)
    .margin({ left: 4, right: 4 })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('←')
            .fontSize(22)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .onClick(() => { router.back() })
          Text('心理活动管理')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .margin({ left: 12 })
        }
        .width('100%')
        .height(56)
        .backgroundColor(Colors.PRIMARY)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Row() {
            ForEach(this.filterTabs, (tab: FilterTab) => {
              Text(tab.label)
                .fontSize(13)
                .fontColor(this.getFilterTextColor(tab.value))
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(20)
                .backgroundColor(this.getFilterBgColor(tab.value))
                .margin({ right: 8 })
                .onClick(() => { this.currentFilter = tab.value })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 4 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(52)

        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.getFilteredActivities(), (item: Activity) => {
              ListItem() { this.ActivityCard(item) }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 12 })
          .scrollBar(BarState.Off)
          .divider({ strokeWidth: 0 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.BACKGROUND)

      if (this.showEfficiencySheet) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .onClick(() => { this.showEfficiencySheet = false })
          this.EfficiencyReportSheet()
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor('rgba(0, 0, 0, 0.4)')
      }

      if (this.showEditSheet) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .onClick(() => { this.showEditSheet = false })
          this.EditSheet()
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .backgroundColor('rgba(0, 0, 0, 0.4)')
      }
    }
    .width('100%')
    .height('100%')
  }
}
