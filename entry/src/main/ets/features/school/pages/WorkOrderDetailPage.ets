import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { OrderTimelineNode, WorkOrderStatus, RiskLevel, WorkOrder } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { DatabaseHelper, WorkOrderRow } from '../../../common/utils/DatabaseHelper'
import promptAction from '@ohos.promptAction'
import { common } from '@kit.AbilityKit'
import { RiskBadge } from '../../../common/components/RiskBadge'

class DetailParams {
  orderId: string = ''
}

@Entry
@Component
struct WorkOrderDetailPage {
  @State timeline: OrderTimelineNode[] = []
  @State order: WorkOrder | null = null
  @State isLoading: boolean = true
  @State orderId: string = ''
  private service: SchoolService = new SchoolService()

  async onPageShow(): Promise<void> {
    const params: DetailParams = router.getParams() as DetailParams
    if (params && params.orderId) {
      this.orderId = params.orderId
    }
    await DatabaseHelper.getInstance().ensureInit(getContext(this) as common.UIAbilityContext)
    await this.loadData()
  }

  private async loadData() {
    this.isLoading = true
    try {
      const db = DatabaseHelper.getInstance()
      const row: WorkOrderRow | null = await db.getWorkOrderById(this.orderId)
      if (row) {
        const o = new WorkOrder()
        o.orderId = row.orderId
        o.relatedCallId = row.relatedCallId
        o.studentName = row.studentName
        o.studentId = row.studentId
        o.type = row.type
        o.description = row.description
        o.status = row.status
        o.assignedTo = row.assignedTo
        o.createdAt = row.createdAt
        o.updatedAt = row.updatedAt
        o.riskLevel = row.riskLevel
        this.order = o
      }
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

  private async dispatchOrder() {
    const db = DatabaseHelper.getInstance()
    // 模拟弹窗选择后更新数据库
    await db.updateWorkOrderStatus(this.orderId, WorkOrderStatus.PROCESSING, '李梦 咨询师')
    promptAction.showToast({ message: '✅ 已一键智能派单给: 李梦 咨询师' })
    await this.loadData()
  }

  private async closeOrder() {
    const db = DatabaseHelper.getInstance()
    await db.updateWorkOrderStatus(this.orderId, WorkOrderStatus.COMPLETED, this.order?.assignedTo || '')
    promptAction.showToast({ message: '✅ 工单已完成并关闭' })
    await this.loadData()
  }

  private async upgradeRiskLevel() {
    const db = DatabaseHelper.getInstance()
    await db.updateWorkOrderRiskLevel(this.orderId, RiskLevel.CRITICAL)
    promptAction.showToast({ message: '⚠️ 已升级为极危工单并通知校应急组介入' })
    await this.loadData()
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('工单详细与处理')
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
      } else if (this.order) {
        Scroll() {
          Column() {
            // AI 智能分析卡片 (演示核心)
            if (this.order.status === WorkOrderStatus.PENDING) {
              Column() {
                Row() {
                  Text('✨ AI 智能分析与调度建议')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#6D28D9') // 紫色高级感
                }
                .width('100%')
                
                Text('基于学生的历史画像及本次求助内容，AI模型测算结果如下：')
                  .fontSize(13)
                  .fontColor(Colors.TEXT_SECONDARY)
                  .margin({ top: 8 })
                
                Row() {
                  Text('推荐指派：')
                    .fontSize(13)
                    .fontColor(Colors.TEXT_PRIMARY)
                  Text('李梦 咨询师')
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Colors.PRIMARY)
                  Text('（匹配度 98%）')
                    .fontSize(12)
                    .fontColor(Colors.SUCCESS)
                }
                .margin({ top: 6 })

                Text('推荐理由：该咨询师擅长处理「' + this.order.type + '」类问题，且目前排班空闲，响应速度最优。')
                  .fontSize(12)
                  .fontColor('#4B5563')
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#F3E8FF') // 浅紫底色
              .borderRadius(12)
              .borderWidth(1)
              .borderColor('#C084FC')
              .margin({ bottom: 16 })
              .animation({ duration: 800, iterations: -1, playMode: PlayMode.Alternate })
            }

            // 基础信息卡片
            Column() {
              Row() {
                Text(this.order.studentName)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Colors.TEXT_PRIMARY)
                RiskBadge({ riskLevel: this.order.riskLevel })
                  .margin({ left: 8 })
                Blank()
                Text(this.order.type)
                  .fontSize(14)
                  .fontColor(Colors.PRIMARY)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor(Colors.PRIMARY + '20')
                  .borderRadius(4)
              }
              .width('100%')

              Text('学号: ' + this.order.studentId + ' | 工单号: ' + this.orderId)
                .fontSize(12)
                .fontColor(Colors.TEXT_HINT)
                .margin({ top: 6 })
              
              Divider().color('#E5E7EB').margin({ top: 12, bottom: 12 })
              
              Text('事件详情描述：')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
                .margin({ bottom: 6 })

              Text(this.order.description)
                .fontSize(13)
                .fontColor(Colors.TEXT_SECONDARY)
                .lineHeight(20)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(12)
            .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
            .margin({ bottom: 16 })

            // 时间线
            Text('处理进度时间线')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .width('100%')
              .margin({ bottom: 12, left: 4 })

            Column() {
              ForEach(this.timeline, (node: OrderTimelineNode, index: number) => {
                Row() {
                  Column() {
                    Column()
                      .width(12)
                      .height(12)
                      .borderRadius(6)
                      .backgroundColor(this.getActionColor(node.action))
                    if (index < this.timeline.length - 1) {
                      Column()
                        .width(2)
                        .height(60)
                        .backgroundColor(this.getActionColor(node.action) + '80')
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
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(12)
            .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
            
            // 底部占位
            Column().height(80).width('100%')
          }
          .padding(16)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 底部悬浮操作栏
        if (this.order.status !== WorkOrderStatus.COMPLETED) {
          Row() {
            if (this.order.status === WorkOrderStatus.PENDING) {
              Button('一键智能派单')
                .layoutWeight(1)
                .height(44)
                .backgroundColor(Colors.PRIMARY)
                .fontColor('#FFFFFF')
                .onClick(() => { this.dispatchOrder() })
            } else if (this.order.status === WorkOrderStatus.PROCESSING) {
              Button('升级危险等级')
                .layoutWeight(1)
                .height(44)
                .backgroundColor(Colors.ERROR)
                .fontColor('#FFFFFF')
                .margin({ right: 12 })
                .onClick(() => { this.upgradeRiskLevel() })

              Button('完成并关闭工单')
                .layoutWeight(1)
                .height(44)
                .backgroundColor(Colors.SUCCESS)
                .fontColor('#FFFFFF')
                .onClick(() => { this.closeOrder() })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Colors.CARD_BG)
          .shadow({ radius: 10, color: Colors.SHADOW, offsetY: -5 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
