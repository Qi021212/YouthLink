import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { DashboardSummary } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { AuthManager } from '../../../core/auth/AuthManager'

class ModuleEntry {
  icon: string = ''
  title: string = ''
  subtitle: string = ''
  route: string = ''
  color: string = ''
  constructor(icon: string, title: string, subtitle: string, route: string, color: string) {
    this.icon = icon
    this.title = title
    this.subtitle = subtitle
    this.route = route
    this.color = color
  }
}

@Entry
@Component
struct SchoolHomePage {
  @State summary: DashboardSummary = new DashboardSummary()
  @State currentTab: number = 0
  @State isLoading: boolean = true
  private service: SchoolService = new SchoolService()

  private mainModules: ModuleEntry[] = [
    new ModuleEntry('📞', 'AI热线监控', '实时通话/AI分析', RouterPath.HOTLINE, Colors.PRIMARY),
    new ModuleEntry('📋', '工单管理', '工单处理/跟踪', RouterPath.WORK_ORDER_LIST, '#6366F1'),
    new ModuleEntry('📅', '预约排班', '排班/预约管理', RouterPath.SCHEDULE, '#10B981'),
    new ModuleEntry('📝', '面询记录', '咨询记录查询', RouterPath.VISIT_RECORD, '#F59E0B'),
    new ModuleEntry('⚠️', '高危跟进', '重点学生追踪', RouterPath.FOLLOW_UP, Colors.ERROR),
    new ModuleEntry('🎯', '心理活动', '活动发布/效能', RouterPath.ACTIVITY_MANAGE, '#EC4899')
  ]

  aboutToAppear(): void {
    this.loadSummary()
  }

  async loadSummary(): Promise<void> {
    try {
      this.summary = await this.service.fetchDashboardSummary()
    } catch (e) {
      this.summary = new DashboardSummary()
    } finally {
      this.isLoading = false
    }
  }

  @Builder
  TopBar() {
    Row() {
      Text('青心链')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_ON_PRIMARY)
      Blank()
      Text('校级心理中心')
        .fontSize(13)
        .fontColor(Colors.TEXT_ON_PRIMARY + 'CC')
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .borderRadius(12)
        .backgroundColor('rgba(255,255,255,0.2)')
      Text('  退出')
        .fontSize(13)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(12)
        .backgroundColor('rgba(255,255,255,0.15)')
        .margin({ left: 8 })
        .onClick(() => {
          const authManager = AuthManager.getInstance()
          authManager.logout()
          router.replaceUrl({ url: RouterPath.LOGIN })
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 24, bottom: 16 })
    .backgroundColor(Colors.PRIMARY)
  }

  @Builder
  StatsBar() {
    Row() {
      this.StatCell('进行中通话', this.summary.activeCalls.toString(), Colors.WARNING + '20', Colors.WARNING)
      this.StatCell('待处理工单', this.summary.pendingOrders.toString(), Colors.INFO + '20', Colors.INFO)
      this.StatCell('今日预约', this.summary.todayAppointments.toString(), Colors.SUCCESS + '20', Colors.SUCCESS)
      this.StatCell('待跟进', this.summary.uncompletedFollowUps.toString(), Colors.ERROR + '20', Colors.ERROR)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 4 })
  }

  @Builder
  StatCell(label: string, value: string, bgColor: string, valueColor: string) {
    Column() {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)
      Text(label)
        .fontSize(10)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: 4 })
    }
    .width('23%')
    .padding({ top: 12, bottom: 12 })
    .borderRadius(10)
    .backgroundColor(bgColor)
    .margin({ left: '1%', right: '1%' })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RiskDistributionCard() {
    Column() {
      Row() {
        Text('风险分布')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
        Text('总人数 ' + this.summary.totalStudents.toString())
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
      }
      .width('100%')

      Row() {
        Column() {
          Column()
            .layoutWeight(1)
          Row() {
            Column()
              .width(12)
              .height(12)
              .borderRadius(3)
              .backgroundColor(Colors.SUCCESS)
            Text('低风险')
              .fontSize(12)
              .fontColor(Colors.TEXT_SECONDARY)
              .margin({ left: 6 })
            Blank()
            Text(this.summary.riskDistribution[0].toString())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
          }
          .width('100%')

          Row() {
            Column()
              .width(12)
              .height(12)
              .borderRadius(3)
              .backgroundColor(Colors.WARNING)
            Text('中风险')
              .fontSize(12)
              .fontColor(Colors.TEXT_SECONDARY)
              .margin({ left: 6 })
            Blank()
            Text(this.summary.riskDistribution[1].toString())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            Column()
              .width(12)
              .height(12)
              .borderRadius(3)
              .backgroundColor('#F97316')
            Text('高风险')
              .fontSize(12)
              .fontColor(Colors.TEXT_SECONDARY)
              .margin({ left: 6 })
            Blank()
            Text(this.summary.riskDistribution[2].toString())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            Column()
              .width(12)
              .height(12)
              .borderRadius(3)
              .backgroundColor(Colors.ERROR)
            Text('极高风险')
              .fontSize(12)
              .fontColor(Colors.TEXT_SECONDARY)
              .margin({ left: 6 })
            Blank()
            Text(this.summary.riskDistribution[3].toString())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .layoutWeight(1)
        .padding({ right: 16 })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(14)
    .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
  }

  @Builder
  ModuleListItem(module: ModuleEntry) {
    Row() {
      Text(module.icon)
        .fontSize(28)
      Column() {
        Text(module.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Text(module.subtitle)
          .fontSize(11)
          .fontColor(Colors.TEXT_HINT)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
      .layoutWeight(1)

      Text('→')
        .fontSize(16)
        .fontColor(Colors.TEXT_HINT)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(12)
    .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 1 })
    .margin({ bottom: 10 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: module.route })
    })
  }

  build() {
    Column() {
      this.TopBar()

      Scroll() {
        Column() {
          this.StatsBar()
          this.RiskDistributionCard()

          Text('功能模块')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
            .alignSelf(ItemAlign.Start)
            .padding({ left: 16, top: 20, bottom: 10 })

          ForEach(this.mainModules, (module: ModuleEntry) => {
            this.ModuleListItem(module)
          })
        }
        .padding({ bottom: 20 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
