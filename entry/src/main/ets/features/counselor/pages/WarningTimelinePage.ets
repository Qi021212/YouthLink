import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RiskBadge } from '../../../common/components/RiskBadge'
import { ConfirmDialog } from '../../../common/components/ConfirmDialog'
import { WarningEvent, TimelineNode } from '../model/WarningEvent'
import { CounselorService } from '../service/CounselorService'

const STATUS_NAMES: string[] = ['待处理', '处理中', '已结案']
const STATUS_COLORS: string[] = ['#EF4444', '#F97316', '#34D399']

@Entry
@Component
struct WarningTimelinePage {
  @State eventList: WarningEvent[] = []
  @State selectedEvent: WarningEvent | null = null
  @State timelineNodes: TimelineNode[] = []
  @State isLoading: boolean = true
  @State showTimeline: boolean = false
  private service: CounselorService = new CounselorService()
  private timelineDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '提示',
      message: '确认要将此事件置为已结案吗？',
      confirmText: '确认结案',
      cancelText: '取消',
      onConfirm: () => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center
  })

  aboutToAppear(): void {
    this.loadEvents()
  }

  async loadEvents(): Promise<void> {
    this.isLoading = true
    const data = await this.service.fetchWarningEvents()
    this.eventList = data
    this.isLoading = false
  }

  async openTimeline(event: WarningEvent): Promise<void> {
    this.selectedEvent = event
    const nodes = await this.service.fetchWarningTimeline(event.eventId)
    this.timelineNodes = nodes
    this.showTimeline = true
  }

  closeTimeline(): void {
    this.showTimeline = false
    this.selectedEvent = null
    this.timelineNodes = []
  }

  build() {
    Stack() {
      Column() {
        this.buildHeader()
        if (this.isLoading) {
          this.buildLoading()
        } else {
          this.buildEventList()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F5F8')

      if (this.showTimeline) {
        this.buildTimelineOverlay()
      }
    }
  }

  @Builder
  buildHeader(): void {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor('#1A1A2E')
        .onClick(() => {
          if (this.showTimeline) {
            this.closeTimeline()
          } else {
            router.back()
          }
        })

      Text('AI前哨预警追踪')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')
        .margin({ left: 12 })

      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 48, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildLoading(): void {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(Colors.PRIMARY)
      Text('加载预警事件...')
        .fontSize(14)
        .fontColor('#6B7280')
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildEventList(): void {
    Scroll() {
      Column() {
        ForEach(this.eventList, (event: WarningEvent) => {
          this.buildEventCard(event)
        })
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  buildEventCard(event: WarningEvent): void {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(event.studentName)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A2E')

            RiskBadge({ riskLevel: event.riskLevel })
              .margin({ left: 8 })
          }

          Text(event.eventType)
            .fontSize(12)
            .fontColor('#6B7280')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        this.buildStatusTag(event.status)
      }
      .width('100%')

      Text(event.description)
        .fontSize(13)
        .fontColor('#4B5563')
        .lineHeight(20)
        .margin({ top: 10 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Text(event.timestamp)
          .fontSize(11)
          .fontColor('#9CA3AF')

        Blank()

        Button('查看详情')
          .fontSize(12)
          .fontColor('#4A90D9')
          .backgroundColor('rgba(74,144,217,0.08)')
          .borderRadius(6)
          .height(30)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.openTimeline(event)
          })
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildStatusTag(status: number): void {
    Text(STATUS_NAMES[status] || '未知')
      .fontSize(11)
      .fontColor(STATUS_COLORS[status] || '#9CA3AF')
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(8)
      .backgroundColor(STATUS_COLORS[status] + '18')
  }

  @Builder
  buildTimelineOverlay(): void {
    Column() {
      Column() {
        Row() {
          Text('闭环追踪时间线')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E')
          Blank()
          Text('×')
            .fontSize(24)
            .fontColor('#6B7280')
            .onClick(() => {
              this.closeTimeline()
            })
        }
        .width('100%')
        .margin({ bottom: 8 })

        if (this.selectedEvent !== null) {
          Row() {
            Text(this.selectedEvent!.studentName)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A2E')
            Text('·')
              .fontSize(14)
              .fontColor('#9CA3AF')
              .margin({ left: 6, right: 6 })
            Text(this.selectedEvent!.eventType)
              .fontSize(14)
              .fontColor('#F97316')
            Blank()
            RiskBadge({ riskLevel: this.selectedEvent!.riskLevel })
          }
          .width('100%')
          .margin({ bottom: 20 })
        }

        Scroll() {
          Column() {
            ForEach(this.timelineNodes, (node: TimelineNode, index: number) => {
              this.buildTimelineNode(node, index)
            })
          }
        }
        .height(320)
        .scrollBar(BarState.Off)

        Divider()
          .color('#E5E7EB')
          .margin({ top: 12, bottom: 12 })

        Row() {
          if (this.selectedEvent !== null && this.selectedEvent!.status < 2) {
            Button(this.selectedEvent!.status === 0 ? '开始处理' : '结案')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor(Colors.PRIMARY)
              .borderRadius(10)
              .layoutWeight(1)
              .height(44)
              .onClick(() => {
                this.handleStatusChange()
              })

            if (this.selectedEvent !== null && this.selectedEvent!.status === 1) {
              Button('联系家长')
                .fontSize(14)
                .fontColor('#4A90D9')
                .backgroundColor('#EFF6FF')
                .borderRadius(10)
                .layoutWeight(1)
                .height(44)
                .margin({ left: 12 })
                .onClick(() => {
                  promptAction.showToast({ message: '家校联系记录已创建', duration: 2000 })
                })
            }
          } else {
            Text('该事件已结案')
              .fontSize(14)
              .fontColor('#34D399')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 8 })
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
    .backgroundColor('rgba(0,0,0,0.4)')
  }

  @Builder
  buildTimelineNode(node: TimelineNode, index: number): void {
    Row() {
      Column() {
        if (node.isCompleted) {
          Circle({ width: 14, height: 14 })
            .fill('#34D399')
        } else if (node.isCurrent) {
          Circle({ width: 14, height: 14 })
            .fill('#4A90D9')
            .border({ width: 3, color: 'rgba(74,144,217,0.2)' })
        } else {
          Circle({ width: 14, height: 14 })
            .fill('#E5E7EB')
        }

        if (index < this.timelineNodes.length - 1) {
          Line()
            .width(2)
            .height(28)
            .backgroundColor(node.isCompleted ? '#34D399' : '#E5E7EB')
        }
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 14 })

      Column() {
        Text(node.stepName)
          .fontSize(14)
          .fontWeight(node.isCurrent ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(node.isCompleted || node.isCurrent ? '#1A1A2E' : '#9CA3AF')

        if (node.timestamp.length > 0) {
          Text(`${node.timestamp} · ${node.handler}`)
            .fontSize(11)
            .fontColor('#9CA3AF')
            .margin({ top: 2 })
        }

        Text(node.result)
          .fontSize(12)
          .fontColor('#6B7280')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ bottom: 4 })
  }

  async handleStatusChange(): Promise<void> {
    if (this.selectedEvent === null) {
      return
    }

    const event = this.selectedEvent!
    const newStatus = event.status + 1

    const ok = await this.service.updateWarningStatus(event.eventId, newStatus)
    if (ok) {
      promptAction.showToast({ message: newStatus === 2 ? '事件已结案' : '已开始处理', duration: 2000 })
      this.closeTimeline()
      this.loadEvents()
    }
  }

  onPageShow(): void {
    this.loadEvents()
  }
}
