import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { HeatmapCell } from '../../../common/components/HeatmapCell'
import { RiskBadge } from '../../../common/components/RiskBadge'
import { ClassHeatData, DormHeatData, RiskStudent } from '../model/RiskStudent'
import { CounselorService } from '../service/CounselorService'
import { ClassDetailResult } from '../service/CounselorService'

@Component
struct DormCell {
  @Prop dormName: string = ''
  @Prop riskLevel: number = 0

  private riskColors: string[] = ['#D1FAE5', '#FEF3C7', '#FED7AA', '#FEE2E2']
  private riskLabels: string[] = ['安', '关', '险', '危']

  build() {
    Column() {
      Text(this.dormName)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A2E')
      Text(this.riskLabels[this.riskLevel] || '?')
        .fontSize(10)
        .fontColor(this.riskLevel >= 2 ? '#EF4444' : '#6B7280')
    }
    .width('30%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.riskColors[this.riskLevel])
    .borderRadius(8)
    .border({ width: 1, color: '#E5E7EB' })
    .margin({ bottom: 8 })
  }
}

@Entry
@Component
struct HeatmapPage {
  @State heatData: ClassHeatData[] = []
  @State selectedClassId: string = ''
  @State selectedClassName: string = ''
  @State dormList: DormHeatData[] = []
  @State riskStudents: RiskStudent[] = []
  @State isLoading: boolean = true
  @State showDetail: boolean = false
  private service: CounselorService = new CounselorService()

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.isLoading = true
    const data = await this.service.fetchHeatmapData()
    this.heatData = data
    this.isLoading = false
  }

  async openClassDetail(item: ClassHeatData): Promise<void> {
    this.selectedClassId = item.classId
    this.selectedClassName = item.className
    const detail = await this.service.fetchClassDetail(item.classId)
    this.dormList = detail.dormList
    this.riskStudents = detail.riskStudents
    this.showDetail = true
  }

  closeDetail(): void {
    this.showDetail = false
    this.selectedClassId = ''
  }

  build() {
    Stack() {
      Column() {
        this.buildHeader()
        if (this.isLoading) {
          this.buildLoading()
        } else {
          this.buildHeatmapGrid()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F5F8')

      if (this.showDetail) {
        this.buildDetailOverlay()
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
          if (this.showDetail) {
            this.closeDetail()
          } else {
            router.back()
          }
        })

      Text('班级心理热力图')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')
        .margin({ left: 12 })

      Blank()

      this.buildLegend()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 48, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildLegend(): void {
    Row() {
      Row() {
        Circle({ width: 8, height: 8 }).fill('#34D399')
        Text('安全').fontSize(10).fontColor('#6B7280').margin({ left: 2 })
      }.margin({ right: 8 })

      Row() {
        Circle({ width: 8, height: 8 }).fill('#FBBF24')
        Text('关注').fontSize(10).fontColor('#6B7280').margin({ left: 2 })
      }.margin({ right: 8 })

      Row() {
        Circle({ width: 8, height: 8 }).fill('#F97316')
        Text('预警').fontSize(10).fontColor('#6B7280').margin({ left: 2 })
      }.margin({ right: 8 })

      Row() {
        Circle({ width: 8, height: 8 }).fill('#EF4444')
        Text('高危').fontSize(10).fontColor('#6B7280').margin({ left: 2 })
      }
    }
  }

  @Builder
  buildLoading(): void {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color(Colors.PRIMARY)
      Text('加载中...')
        .fontSize(14)
        .fontColor('#6B7280')
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildHeatmapGrid(): void {
    Scroll() {
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.heatData, (item: ClassHeatData) => {
          HeatmapCell({
            className: item.className,
            studentCount: item.studentCount,
            riskLevel: item.riskLevel,
            isSelected: this.selectedClassId === item.classId,
            onCellClick: () => {
              this.openClassDetail(item)
            }
          })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  buildDetailOverlay(): void {
    Column() {
      Column() {
        Row() {
          Text(this.selectedClassName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E')
          Blank()
          Text('×')
            .fontSize(24)
            .fontColor('#6B7280')
            .onClick(() => {
              this.closeDetail()
            })
        }
        .width('100%')
        .margin({ bottom: 16 })

        Text('寝室风险分布')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A2E')
          .margin({ bottom: 10 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.dormList, (dorm: DormHeatData) => {
            DormCell({ dormName: dorm.dormName, riskLevel: dorm.riskLevel })
          })
        }
        .width('100%')

        Divider()
          .color('#E5E7EB')
          .margin({ top: 16, bottom: 12 })

        Text('风险学生清单')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A2E')
          .margin({ bottom: 10 })

        Scroll() {
          Column() {
            ForEach(this.riskStudents, (student: RiskStudent) => {
              this.buildStudentCard(student)
            })
          }
        }
        .height(280)
        .scrollBar(BarState.Off)
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
    .onClick(() => {
      this.closeDetail()
    })
  }

  @Builder
  buildStudentCard(student: RiskStudent): void {
    Row() {
      Column() {
        Text(student.name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A2E')
        Text(`心情:${student.moodScore} | 跟进:${student.followUpCount}次`)
          .fontSize(11)
          .fontColor('#6B7280')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      RiskBadge({ riskLevel: student.riskLevel })
    }
    .width('100%')
    .height(52)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#F9FAFB')
    .borderRadius(10)
    .margin({ bottom: 8 })
  }

  onPageShow(): void {
    this.loadData()
  }
}
