import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { VisitRecord, RiskLevel } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { RiskBadge } from '../../../common/components/RiskBadge'

@Entry
@Component
struct VisitRecordPage {
  @State records: VisitRecord[] = []
  @State isLoading: boolean = true
  @State searchText: string = ''
  private service: SchoolService = new SchoolService()

  async aboutToAppear(): Promise<void> {
    try {
      this.records = await this.service.fetchVisitRecords()
    } catch (e) {
      this.records = []
    } finally {
      this.isLoading = false
    }
  }

  private getFilteredRecords(): VisitRecord[] {
    if (this.searchText.length === 0) return this.records
    return this.records.filter((r: VisitRecord) => {
      return r.studentName.indexOf(this.searchText) >= 0 || r.studentId.indexOf(this.searchText) >= 0
    })
  }

  private getRiskText(level: RiskLevel): string {
    if (level === RiskLevel.LOW) return '低'
    if (level === RiskLevel.MEDIUM) return '中'
    if (level === RiskLevel.HIGH) return '高'
    return '危'
  }

  private getRiskClass(level: RiskLevel): string {
    if (level === RiskLevel.LOW) return 'low'
    if (level === RiskLevel.MEDIUM) return 'medium'
    if (level === RiskLevel.HIGH) return 'high'
    return 'critical'
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('面询记录')
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

      Row() {
        TextInput({ placeholder: '搜索学生姓名或学号...', text: this.searchText })
          .fontSize(14)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#F3F4F6')
          .borderRadius(10)
          .padding({ left: 14 })
          .onChange((value: string) => { this.searchText = value })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.getFilteredRecords(), (record: VisitRecord) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(record.studentName)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Colors.TEXT_PRIMARY)
                    Text(record.studentId)
                      .fontSize(12)
                      .fontColor(Colors.TEXT_HINT)
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  RiskBadge({ level: this.getRiskClass(record.riskLevel), text: this.getRiskText(record.riskLevel) })
                }
                .width('100%')

                Row() {
                  Text(record.type)
                    .fontSize(12)
                    .fontColor(Colors.PRIMARY)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(4)
                    .backgroundColor(Colors.PRIMARY + '15')
                  Text('  ·  ')
                    .fontSize(12)
                    .fontColor(Colors.TEXT_HINT)
                  Text(record.counselor)
                    .fontSize(12)
                    .fontColor(Colors.TEXT_SECONDARY)
                  Text('  ·  ')
                    .fontSize(12)
                    .fontColor(Colors.TEXT_HINT)
                  Text(record.visitDate)
                    .fontSize(12)
                    .fontColor(Colors.TEXT_SECONDARY)
                }
                .margin({ top: 10 })

                Text(record.summary)
                  .fontSize(13)
                  .fontColor(Colors.TEXT_SECONDARY)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 8 })
                  .width('100%')

                Row() {
                  Text('下一步: ')
                    .fontSize(12)
                    .fontColor(Colors.TEXT_HINT)
                  Text(record.nextPlan)
                    .fontSize(12)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                }
                .margin({ top: 8 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Colors.CARD_BG)
              .borderRadius(12)
              .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
              .margin({ bottom: 10 })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 4 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
