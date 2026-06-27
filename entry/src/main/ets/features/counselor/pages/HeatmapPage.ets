import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RiskBadge } from '../../../common/components/RiskBadge'
import { DormHeatData, RiskStudent } from '../model/RiskStudent'
import { CounselorService, ClassDetailResult } from '../service/CounselorService'

@Component
struct DormCell {
  @Prop dormName: string = ''
  @Prop riskLevel: number = 0
  @Prop gender: 'Male' | 'Female' = 'Male'
  @Prop beds: number[] = [0, 0, 0, 0]

  private bedColors: string[] = ['#34D399', '#FBBF24', '#F97316', '#EF4444']

  build() {
    Column() {
      Row() {
        SymbolGlyph(this.gender === 'Male' ? $r('sys.symbol.person_fill') : $r('sys.symbol.person_crop_circle_fill'))
          .fontSize(14)
          .fontColor([this.gender === 'Male' ? '#3B82F6' : '#EC4899'])
          .margin({ right: 4 })
        Text(this.dormName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
      }
      .margin({ bottom: 12 })

      // 2x2 Grid for 4 beds
      Grid() {
        ForEach(this.beds, (bedRisk: number, index: number) => {
          GridItem() {
            Column()
              .width(24)
              .height(24)
              .backgroundColor(this.bedColors[bedRisk] || '#E5E7EB')
              .borderRadius(6)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width(56)
      .height(56)
    }
    .width('46%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 4 })
    .margin({ bottom: 12 })
  }
}

@Entry
@Component
struct HeatmapPage {
  @State selectedClassName: string = ''
  @State dormList: DormHeatData[] = []
  @State riskStudents: RiskStudent[] = []
  @State isLoading: boolean = true
  private service: CounselorService = new CounselorService()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['activeClassName']) {
      this.selectedClassName = params['activeClassName']
    } else {
      this.selectedClassName = '计算机2401' // Default fallback
    }
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.isLoading = true
    const detail = await this.service.fetchClassDetail(this.selectedClassName)
    this.dormList = detail.dormList
    this.riskStudents = detail.riskStudents
    this.isLoading = false
  }

  build() {
    Column() {
      this.buildHeader()
      
      if (this.isLoading) {
        this.buildLoading()
      } else {
        Scroll() {
          Column() {
            this.buildOverviewCard()
            this.buildDormitorySection()
            this.buildRiskStudentsSection()
          }
          .padding({ bottom: 40 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F9FAFB')
  }

  @Builder
  buildHeader(): void {
    Row() {
      Text('←')
        .fontSize(22)
        .fontColor('#1A1A2E')
        .onClick(() => {
          router.back()
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
      }.margin({ right: 6 })
      Row() {
        Circle({ width: 8, height: 8 }).fill('#FBBF24')
        Text('关注').fontSize(10).fontColor('#6B7280').margin({ left: 2 })
      }.margin({ right: 6 })
      Row() {
        Circle({ width: 8, height: 8 }).fill('#F97316')
        Text('预警').fontSize(10).fontColor('#6B7280').margin({ left: 2 })
      }.margin({ right: 6 })
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
  buildOverviewCard(): void {
    Column() {
      Text(this.selectedClassName)
        .fontSize(24)
        .fontWeight(FontWeight.Bolder)
        .fontColor('#FFFFFF')
      
      Row() {
        Column() {
          Text('异常预警')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
          Text(`${this.riskStudents.filter(s => s.riskLevel >= 2).length}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start)
        
        Blank()
        
        Column() {
          Text('重点关注')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.8)')
          Text(`${this.riskStudents.filter(s => s.riskLevel === 1).length}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 4 })
        }.alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('92%')
    .padding(24)
    .margin({ top: 16, bottom: 24 })
    .linearGradient({ colors: [['#3B82F6', 0.0], ['#2563EB', 1.0]], direction: GradientDirection.RightBottom })
    .borderRadius(20)
    .shadow({ radius: 12, color: 'rgba(59, 130, 246, 0.3)', offsetY: 6 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildDormitorySection(): void {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.house_fill'))
          .fontSize(18)
          .fontColor(['#1A1A2E'])
          .margin({ right: 8 })
        Text('寝室风险分布 (4人寝)')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')
      }
      .width('92%')
      .margin({ bottom: 16 })

      // 男生寝室
      if (this.dormList.filter(d => d.gender === 'Male').length > 0) {
        Text('男生寝室')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6B7280')
          .width('92%')
          .margin({ bottom: 12 })
        
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.dormList.filter(d => d.gender === 'Male'), (dorm: DormHeatData) => {
            DormCell({ dormName: dorm.dormName, riskLevel: dorm.riskLevel, gender: dorm.gender, beds: dorm.beds })
          })
        }
        .width('92%')
        .margin({ bottom: 16 })
      }

      // 女生寝室
      if (this.dormList.filter(d => d.gender === 'Female').length > 0) {
        Text('女生寝室')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6B7280')
          .width('92%')
          .margin({ bottom: 12 })
        
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          ForEach(this.dormList.filter(d => d.gender === 'Female'), (dorm: DormHeatData) => {
            DormCell({ dormName: dorm.dormName, riskLevel: dorm.riskLevel, gender: dorm.gender, beds: dorm.beds })
          })
        }
        .width('92%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 24 })
  }

  @Builder
  buildRiskStudentsSection(): void {
    if (this.riskStudents.filter(s => s.riskLevel >= 1).length > 0) {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.person_3_fill'))
            .fontSize(18)
            .fontColor(['#1A1A2E'])
            .margin({ right: 8 })
          Text('重点关注学生')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E')
        }
        .width('92%')
        .margin({ bottom: 16 })

        Column() {
          ForEach(this.riskStudents.filter(s => s.riskLevel >= 1), (student: RiskStudent) => {
            this.buildStudentCard(student)
          })
        }
        .width('92%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  @Builder
  buildStudentCard(student: RiskStudent): void {
    Row() {
      Column() {
        Row() {
          Text(student.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E')
            .margin({ right: 8 })
          Text(student.dormName)
            .fontSize(11)
            .fontColor('#6B7280')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#E5E7EB')
            .borderRadius(4)
        }
        .margin({ bottom: 4 })
        
        Text(`心情评分: ${student.moodScore} | 近期跟进: ${student.followUpCount}次`)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      RiskBadge({ riskLevel: student.riskLevel })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.03)', offsetY: 2 })
    .margin({ bottom: 12 })
  }

  onPageShow(): void {
    // 可以在这里刷新
  }
}
