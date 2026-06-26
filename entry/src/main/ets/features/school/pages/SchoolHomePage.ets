import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { DashboardSummary } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { AuthManager } from '../../../core/auth/AuthManager'
import { UserInfoJson } from '../../../common/model/UserInfo'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { common } from '@kit.AbilityKit'

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

class TodoEntry {
  title: string = ''
  desc: string = ''
  icon: string = ''
  route: string = ''
  constructor(title: string, desc: string, icon: string, route: string) {
    this.title = title
    this.desc = desc
    this.icon = icon
    this.route = route
  }
}

@Entry
@Component
struct SchoolHomePage {
  @State currentTab: number = 0
  @State summary: DashboardSummary = new DashboardSummary()
  @State isLoading: boolean = true
  @State userName: string = '管理员'
  @State userAvatarChar: string = '管'
  private service: SchoolService = new SchoolService()

  private mainModules: ModuleEntry[] = [
    new ModuleEntry('📞', 'AI热线监控', '实时通话/AI分析', RouterPath.HOTLINE, Colors.PRIMARY),
    new ModuleEntry('📋', '工单管理', '工单处理/跟踪', RouterPath.WORK_ORDER_LIST, '#6366F1'),
    new ModuleEntry('📅', '预约排班', '排班/预约管理', RouterPath.SCHEDULE, '#10B981'),
    new ModuleEntry('📝', '面询记录', '咨询记录查询', RouterPath.VISIT_RECORD, '#F59E0B'),
    new ModuleEntry('⚠️', '高危跟进', '重点学生追踪', RouterPath.FOLLOW_UP, Colors.ERROR),
    new ModuleEntry('🎯', '心理活动', '活动发布/效能', RouterPath.ACTIVITY_MANAGE, '#EC4899')
  ]

  private todoList: TodoEntry[] = [
    new TodoEntry('热线通话巡视', '关注AI热线中的高危对话', '📞', RouterPath.HOTLINE),
    new TodoEntry('待处理工单', '查看并分配新增工单', '📋', RouterPath.WORK_ORDER_LIST),
    new TodoEntry('预约确认', '确认今日咨询预约安排', '📅', RouterPath.SCHEDULE),
    new TodoEntry('跟进任务', '检查高危学生跟进进度', '⚠️', RouterPath.FOLLOW_UP)
  ]

  aboutToAppear(): void {
    this.loadUserInfo()
    this.loadSummary()
  }

  // 从详情/子页面返回时刷新总览，保证跨端数据变化能及时反映
  onPageShow(): void {
    this.loadSummary()
  }

  async loadUserInfo(): Promise<void> {
    const authManager = AuthManager.getInstance()
    const json = await authManager.getUserInfoJson()
    try {
      const info: UserInfoJson = JSON.parse(json) as UserInfoJson
      if (info.name && info.name.length > 0) {
        this.userName = info.name
        this.userAvatarChar = info.name.charAt(0)
      }
    } catch (e) {
      this.userName = '管理员'
      this.userAvatarChar = '管'
    }
  }

  async loadSummary(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      // 读取 reports / students 表前确保数据库已初始化（与辅导员端一致）
      await DatabaseHelper.getInstance().ensureInit(ctx)
      this.summary = await this.service.fetchDashboardSummary(ctx)
    } catch (e) {
      this.summary = new DashboardSummary()
    } finally {
      this.isLoading = false
    }
  }

  private getTimeGreeting(): string {
    const hour = new Date().getHours()
    if (hour >= 6 && hour < 12) { return '上午好' }
    if (hour >= 12 && hour < 14) { return '中午好' }
    if (hour >= 14 && hour < 18) { return '下午好' }
    return '晚上好'
  }

  build() {
    Column() {
      Stack() {
        if (this.currentTab === 0) {
          this.buildHomeTab()
        } else if (this.currentTab === 1) {
          this.buildWorkbenchTab()
        } else {
          this.buildProfileTab()
        }
      }
      .layoutWeight(1)

      this.BottomBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  /* ======================== 首页 Tab ======================== */
  @Builder
  buildHomeTab(): void {
    Column() {
      this.HomeHeader()
      Scroll() {
        Column() {
          this.StatsGrid()
          this.RiskCard()
          this.TodayOverview()
        }
        .padding({ bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HomeHeader() {
    Column() {
      Row() {
        Column() {
          Text(this.userName + '，' + this.getTimeGreeting())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_ON_PRIMARY)
          Text('校级心理中心 · 管理后台')
            .fontSize(13)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(0.8)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 44, height: 44 })
            .fill('rgba(255,255,255,0.25)')
          Text(this.userAvatarChar)
            .fontSize(18)
            .fontColor(Colors.TEXT_ON_PRIMARY)
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 20 })
    }
    .width('100%')
    .backgroundColor(Colors.PRIMARY)
    .borderRadius({ bottomLeft: 24, bottomRight: 24 })
  }

  @Builder
  StatsGrid() {
    Column() {
      Text('数据概览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .alignSelf(ItemAlign.Start)
        .padding({ left: 4, top: 6, bottom: 6 })

      Grid() {
        GridItem() {
          this.StatCell('进行中通话', this.summary.activeCalls.toString(), Colors.WARNING)
        }
        GridItem() {
          this.StatCell('待处理工单', this.summary.pendingOrders.toString(), '#6366F1')
        }
        GridItem() {
          this.StatCell('今日预约', this.summary.todayAppointments.toString(), Colors.SUCCESS)
        }
        GridItem() {
          this.StatCell('待跟进', this.summary.uncompletedFollowUps.toString(), Colors.ERROR)
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
    .margin({ top: 16 })
  }

  @Builder
  StatCell(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(12)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(14)
    .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 2 })
  }

  @Builder
  RiskCard() {
    Column() {
      Row() {
        Text('风险分布')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
        Text('全校在册 ' + this.summary.totalStudents.toString() + ' 人')
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
      }
      .width('100%')
      .margin({ bottom: 14 })

      Row() {
        this.RiskBar('低风险', this.summary.riskDistribution[0], Colors.SUCCESS)
        this.RiskBar('中风险', this.summary.riskDistribution[1], Colors.WARNING)
        this.RiskBar('高风险', this.summary.riskDistribution[2], '#F97316')
        this.RiskBar('极高风险', this.summary.riskDistribution[3], Colors.ERROR)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(14)
    .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 2 })
    .margin({ left: 20, right: 20, top: 16 })
  }

  @Builder
  RiskBar(label: string, count: number, color: string) {
    Column() {
      Text(count.toString())
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  TodayOverview() {
    Column() {
      Row() {
        Text('今日待办')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .margin({ bottom: 10 })

      ForEach(this.todoList, (item: TodoEntry) => {
        this.TodoItem(item.title, item.desc, item.icon, item.route)
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(14)
    .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 2 })
    .margin({ left: 20, right: 20, top: 16 })
  }

  @Builder
  TodoItem(title: string, desc: string, icon: string, route: string) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })
      Column() {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Text(desc)
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('>')
        .fontSize(14)
        .fontColor(Colors.TEXT_HINT)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderRadius(8)
    .onClick(() => {
      router.pushUrl({ url: route })
    })
  }

  /* ======================== 工作台 Tab ======================== */
  @Builder
  buildWorkbenchTab(): void {
    Column() {
      Row() {
        Text('工作台')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 8 })

      Scroll() {
        Grid() {
          ForEach(this.mainModules, (item: ModuleEntry) => {
            GridItem() {
              this.ModuleCard(item)
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(14)
        .rowsGap(14)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ModuleCard(item: ModuleEntry) {
    Column() {
      Column() {
        Text(item.icon)
          .fontSize(36)
      }
      .width(56)
      .height(56)
      .borderRadius(16)
      .backgroundColor(item.color + '18')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ top: 14 })

      Text(item.subtitle)
        .fontSize(11)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(16)
    .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 2 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      router.pushUrl({ url: item.route })
    })
  }

  /* ======================== 我的 Tab ======================== */
  @Builder
  buildProfileTab(): void {
    Scroll() {
      Column() {
        // 个人信息卡片
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 72, height: 72 })
              .fill(Colors.PRIMARY + '25')
            Text(this.userAvatarChar)
              .fontSize(30)
              .fontColor(Colors.PRIMARY)
          }
          .margin({ top: 28 })

          Text(this.userName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
            .margin({ top: 14 })

          Text('校级心理中心')
            .fontSize(13)
            .fontColor(Colors.TEXT_SECONDARY)
            .margin({ top: 4 })

          Row() {
            Column() {
              Text(this.summary.totalStudents.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.TEXT_PRIMARY)
              Text('全校学生')
                .fontSize(11)
                .fontColor(Colors.TEXT_HINT)
                .margin({ top: 2 })
            }
            .layoutWeight(1)

            Column() {
              Text(this.summary.todayAppointments.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.TEXT_PRIMARY)
              Text('今日预约')
                .fontSize(11)
                .fontColor(Colors.TEXT_HINT)
                .margin({ top: 2 })
            }
            .layoutWeight(1)

            Column() {
              Text(this.summary.activeCalls.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.TEXT_PRIMARY)
              Text('活跃热线')
                .fontSize(11)
                .fontColor(Colors.TEXT_HINT)
                .margin({ top: 2 })
            }
            .layoutWeight(1)
          }
          .width('84%')
          .margin({ top: 24 })
          .padding({ top: 14, bottom: 14 })
          .backgroundColor(Colors.BACKGROUND)
          .borderRadius(12)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 设置
        Text('设置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .alignSelf(ItemAlign.Start)
          .padding({ left: 24, top: 28, bottom: 10 })

        this.SettingsItem('账号与安全', '修改密码与安全设置', () => {
          router.pushUrl({ url: 'features/auth/pages/ChangePasswordPage' })
        })

        this.SettingsItem('通知设置', '管理预警推送与提醒', () => {
        })

        this.SettingsItem('关于青心链', 'v1.0.0 校级心理中心版', () => {
        })

        // 退出登录
        Button('退出登录')
          .fontSize(15)
          .fontColor('#EF4444')
          .backgroundColor('#FEE2E2')
          .borderRadius(12)
          .height(48)
          .width('88%')
          .margin({ top: 32, bottom: 40 })
          .onClick(() => {
            const authManager = AuthManager.getInstance()
            authManager.logout()
            router.replaceUrl({ url: RouterPath.LOGIN })
          })
      }
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  SettingsItem(title: string, subtitle: string, onClickAction?: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor(Colors.TEXT_PRIMARY)
        Text(subtitle)
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(16)
        .fontColor(Colors.TEXT_HINT)
    }
    .width('88%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      if (onClickAction) {
        onClickAction()
      }
    })
  }

  /* ======================== 底部导航栏 ======================== */
  @Builder
  BottomBar() {
    Row() {
      this.TabItem('首页', '🏠', 0)
      this.TabItem('工作台', '💼', 1)
      this.TabItem('我的', '👤', 2)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor(Colors.CARD_BG)
    .border({ width: { top: 1 }, color: '#F3F4F6' })
  }

  @Builder
  TabItem(label: string, icon: string, index: number) {
    Column() {
      Text(icon)
        .fontSize(22)
        .opacity(this.currentTab === index ? 1 : 0.5)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? Colors.PRIMARY : Colors.TEXT_HINT)
        .margin({ top: 3 })
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentTab = index
    })
  }
}
