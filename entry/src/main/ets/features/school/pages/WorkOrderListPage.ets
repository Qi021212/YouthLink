import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { WorkOrder, WorkOrderStatus, RiskLevel } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { StatusChip } from '../../../common/components/StatusChip'
import { RiskBadge } from '../../../common/components/RiskBadge'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { common } from '@kit.AbilityKit'

function getStatusType(status: WorkOrderStatus): string {
  if (status === WorkOrderStatus.PENDING) return 'warning'
  if (status === WorkOrderStatus.PROCESSING) return 'info'
  if (status === WorkOrderStatus.COMPLETED) return 'success'
  return 'default'
}

function getStatusLabel(status: WorkOrderStatus): string {
  if (status === WorkOrderStatus.PENDING) return '待处理'
  if (status === WorkOrderStatus.PROCESSING) return '处理中'
  if (status === WorkOrderStatus.COMPLETED) return '已完成'
  return '已关闭'
}

class FilterTab {
  label: string = ''
  value: number = -1
  constructor(label: string, value: number) {
    this.label = label
    this.value = value
  }
}

@Entry
@Component
struct WorkOrderListPage {
  @State orders: WorkOrder[] = []
  @State isLoading: boolean = true
  @State currentFilter: number = -1
  private service: SchoolService = new SchoolService()

  private filterTabs: FilterTab[] = [
    new FilterTab('全部', -1),
    new FilterTab('待处理', WorkOrderStatus.PENDING),
    new FilterTab('处理中', WorkOrderStatus.PROCESSING),
    new FilterTab('已完成', WorkOrderStatus.COMPLETED)
  ]

  async onPageShow(): Promise<void> {
    await DatabaseHelper.getInstance().ensureInit(getContext(this) as common.UIAbilityContext)
    await this.loadData()
  }

  private async loadData() {
    this.isLoading = true
    try {
      this.orders = await this.service.fetchWorkOrders()
    } catch (e) {
      this.orders = []
    } finally {
      this.isLoading = false
    }
  }

  private getFilteredOrders(): WorkOrder[] {
    if (this.currentFilter === -1) return this.orders
    return this.orders.filter(o => o.status === this.currentFilter)
  }

  private getFilterBgColor(value: number): string {
    if (this.currentFilter === value) return Colors.PRIMARY
    return '#F3F4F6'
  }

  private getFilterTextColor(value: number): string {
    if (this.currentFilter === value) return Colors.TEXT_ON_PRIMARY
    return Colors.TEXT_SECONDARY
  }

  // 统计数据
  private getRiskStats(): number[] {
    const dist = [0, 0, 0, 0]
    this.orders.forEach(o => {
      dist[o.riskLevel] = dist[o.riskLevel] + 1
    })
    return dist
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('校园心理危机工单')
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

      if (this.isLoading && this.orders.length === 0) {
        Column() {
          LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 数据大屏看板
        Row() {
          Column() {
            Text('今日工单危机分布')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .margin({ bottom: 12 })
            Row() {
              DataPanel({ values: this.getRiskStats().map(v => Math.max(v, 1)), max: Math.max(...this.getRiskStats(), 10) * 1.5, type: DataPanelType.Line })
                .width('100%')
                .height(10)
                .valueColors(['#34D399', '#FBBF24', '#F97316', '#EF4444']) // 对应四个危险等级
            }
            .width('100%')
            Row() {
              Text(`正常:${this.getRiskStats()[0]}  关注:${this.getRiskStats()[1]}  预警:${this.getRiskStats()[2]}  高危:${this.getRiskStats()[3]}`)
                .fontSize(11)
                .fontColor(Colors.TEXT_SECONDARY)
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Colors.CARD_BG)
          .borderRadius(12)
          .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })

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
                .onClick(() => { 
                  this.currentFilter = tab.value;
                })
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .height(48)

        List() {
          ForEach(this.getFilteredOrders(), (order: WorkOrder) => {
            ListItem() {
              WorkOrderItemComponent({ order: order })
            }
            .transition({ type: TransitionType.Insert, translate: { y: 20 }, opacity: 0 })
          }, (order: WorkOrder) => order.orderId + order.status)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}

@Component
struct WorkOrderItemComponent {
  @Prop order: WorkOrder;

  private getBorderColor(): string {
    if (this.order.riskLevel === RiskLevel.CRITICAL) return '#EF4444' // 红色
    if (this.order.riskLevel === RiskLevel.HIGH) return '#F97316' // 橙色
    return 'transparent'
  }

  build() {
    Column() {
      Row() {
        RiskBadge({ riskLevel: this.order.riskLevel })
          .margin({ right: 8 })
          .animation({ duration: 1000, iterations: this.order.riskLevel >= 2 ? -1 : 1, playMode: PlayMode.Alternate })

        Text(this.order.type)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)

        StatusChip({ label: getStatusLabel(this.order.status), type: getStatusType(this.order.status) })
      }
      .width('100%')

      Text(this.order.studentName + ' · ' + this.order.description)
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')

      Row() {
        Text(this.order.createdAt)
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
        Blank()
        Text(this.order.assignedTo.length > 0 ? `负责人: ${this.order.assignedTo}` : '🔴 待智能分配')
          .fontSize(12)
          .fontColor(this.order.assignedTo.length > 0 ? Colors.PRIMARY : Colors.ERROR)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(12)
    .borderWidth(this.order.riskLevel >= 2 ? 1 : 0)
    .borderColor(this.getBorderColor())
    .shadow({ radius: this.order.riskLevel >= 2 ? 8 : 4, color: this.order.riskLevel >= 2 ? this.getBorderColor() + '40' : Colors.SHADOW, offsetY: 2 })
    .margin({ bottom: 10 })
    .onClick(() => {
      router.pushUrl({ url: RouterPath.WORK_ORDER_DETAIL, params: { orderId: this.order.orderId } })
    })
  }
}
