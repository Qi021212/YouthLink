import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { OrderTimelineNode, WorkOrderStatus } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'

class DetailParams {
  orderId: string = ''
}

@Entry
@Component
struct WorkOrderDetailPage {
  @State timeline: OrderTimelineNode[] = []
  @State isLoading: boolean = true
  @State orderId: string = ''
  private service: SchoolService = new SchoolService()

  async aboutToAppear(): Promise<void> {
    const params: DetailParams = router.getParams() as DetailParams
    if (params && params.orderId) {
      this.orderId = params.orderId
    }
    try {
      this.timeline = await this.service.fetchOrderTimeline(this.orderId)
    } catch (e) {
      this.timeline = []
    } finally {
      this.isLoading = false
    }
  }

  private getActionColor(action: string): string {
    if (action.indexOf('创建') >= 0) return Colors.INFO
    if (action.indexOf('分配') >= 0) return Colors.WARNING
    if (action.indexOf('接收') >= 0) return Colors.SUCCESS
    if (action.indexOf('完成') >= 0) return Colors.SUCCESS
    return Colors.TEXT_SECONDARY
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('工单详情')
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

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          Text('工单编号')
            .fontSize(12)
            .fontColor(Colors.TEXT_HINT)
          Text(this.orderId)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Colors.CARD_BG)
        .borderRadius(12)
        .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
        .margin({ left: 16, right: 16, top: 16 })

        List() {
          ForEach(this.timeline, (node: OrderTimelineNode, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Column()
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(index === 0 ? Colors.PRIMARY : '#D1D5DB')
                  if (index < this.timeline.length - 1) {
                    Column()
                      .width(2)
                      .height(60)
                      .backgroundColor('#E5E7EB')
                  }
                }
                .alignItems(HorizontalAlign.Center)
                .margin({ right: 14 })

                Column() {
                  Text(node.action)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.getActionColor(node.action))

                  Text(node.remark)
                    .fontSize(13)
                    .fontColor(Colors.TEXT_SECONDARY)
                    .margin({ top: 4 })

                  Row() {
                    Text(node.operator)
                      .fontSize(12)
                      .fontColor(Colors.TEXT_HINT)
                    Text('  ·  ')
                      .fontSize(12)
                      .fontColor(Colors.TEXT_HINT)
                    Text(node.time)
                      .fontSize(12)
                      .fontColor(Colors.TEXT_HINT)
                  }
                  .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .alignItems(VerticalAlign.Top)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
