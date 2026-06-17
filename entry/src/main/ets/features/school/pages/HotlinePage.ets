import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { HotlineCall, CallStatus, RiskLevel } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { RiskBadge } from '../../../common/components/RiskBadge'

@Entry
@Component
struct HotlinePage {
  @State activeCalls: HotlineCall[] = []
  @State isLoading: boolean = true
  private service: SchoolService = new SchoolService()

  async aboutToAppear(): Promise<void> {
    try {
      this.activeCalls = await this.service.fetchActiveCalls()
    } catch (e) {
      this.activeCalls = []
    } finally {
      this.isLoading = false
    }
  }

  private getCallStatusType(status: CallStatus): string {
    if (status === CallStatus.ONGOING) return 'warning'
    if (status === CallStatus.COMPLETED) return 'success'
    return 'default'
  }

  private getCallStatusLabel(status: CallStatus): string {
    if (status === CallStatus.ONGOING) return '通话中'
    if (status === CallStatus.COMPLETED) return '已结束'
    return '未接听'
  }

  private formatDuration(seconds: number): string {
    const m: number = Math.floor(seconds / 60)
    const s: number = seconds % 60
    return m + '\'' + s.toString().padStart(2, '0') + '"'
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('AI热线监控')
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
        List() {
          ForEach(this.activeCalls, (call: HotlineCall) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(call.callerName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Colors.TEXT_PRIMARY)
                    Text(call.phoneNumber)
                      .fontSize(12)
                      .fontColor(Colors.TEXT_HINT)
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Column() {
                    Text(this.getCallStatusLabel(call.status))
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(call.status === CallStatus.ONGOING ? Colors.WARNING : Colors.SUCCESS)
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .backgroundColor(call.status === CallStatus.ONGOING ? Colors.WARNING + '20' : Colors.SUCCESS + '20')
                }
                .width('100%')

                Row() {
                  Text('时长: ' + this.formatDuration(call.duration))
                    .fontSize(13)
                    .fontColor(Colors.TEXT_SECONDARY)
                  Blank()
                  Row() {
                    ForEach(call.tags, (tag: string) => {
                      Text(tag)
                        .fontSize(11)
                        .fontColor(Colors.PRIMARY)
                        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                        .borderRadius(4)
                        .backgroundColor(Colors.PRIMARY + '15')
                        .margin({ left: 4 })
                    })
                  }
                }
                .width('100%')
                .margin({ top: 10 })

                Text(call.aiSummary)
                  .fontSize(13)
                  .fontColor(Colors.TEXT_SECONDARY)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 10 })
                  .padding(12)
                  .borderRadius(8)
                  .backgroundColor('#F0F4FF')
                  .width('100%')
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Colors.CARD_BG)
              .borderRadius(12)
              .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
              .margin({ bottom: 12 })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 12 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
