import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { WorkOrder, WorkOrderStatus, RiskLevel } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { StatusChip } from '../../../common/components/StatusChip'

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

  async aboutToAppear(): Promise<void> {
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
    return this.orders.filter((o: WorkOrder) => o.status === this.currentFilter)
  }

  private getStatusType(status: WorkOrderStatus): string {
    if (status === WorkOrderStatus.PENDING) return 'warning'
    if (status === WorkOrderStatus.PROCESSING) return 'info'
    if (status === WorkOrderStatus.COMPLETED) return 'success'
    return 'default'
  }

  private getStatusLabel(status: WorkOrderStatus): string {
    if (status === WorkOrderStatus.PENDING) return '待处理'
    if (status === WorkOrderStatus.PROCESSING) return '处理中'
    if (status === WorkOrderStatus.COMPLETED) return '已完成'
    return '已关闭'
  }

  private getFilterBgColor(value: number): string {
    if (this.currentFilter === value) return Colors.PRIMARY
    return '#F3F4F6'
  }

  private getFilterTextColor(value: number): string {
    if (this.currentFilter === value) return Colors.TEXT_ON_PRIMARY
    return Colors.TEXT_SECONDARY
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('工单管理')
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
          ForEach(this.getFilteredOrders(), (order: WorkOrder) => {
            ListItem() {
              Column() {
                Row() {
                  Text(order.type)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .layoutWeight(1)
                  StatusChip({ label: this.getStatusLabel(order.status), type: this.getStatusType(order.status) })
                }
                .width('100%')

                Text(order.studentName + ' · ' + order.description)
                  .fontSize(13)
                  .fontColor(Colors.TEXT_SECONDARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 6 })
                  .width('100%')

                Row() {
                  Text(order.createdAt)
                    .fontSize(12)
                    .fontColor(Colors.TEXT_HINT)
                  Blank()
                  Text(order.assignedTo.length > 0 ? order.assignedTo : '待分配')
                    .fontSize(12)
                    .fontColor(order.assignedTo.length > 0 ? Colors.PRIMARY : Colors.TEXT_HINT)
                }
                .width('100%')
                .margin({ top: 8 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Colors.CARD_BG)
              .borderRadius(12)
              .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
              .margin({ bottom: 10 })
              .onClick(() => {
                router.pushUrl({ url: RouterPath.WORK_ORDER_DETAIL, params: { orderId: order.orderId } })
              })
            }
          })
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
