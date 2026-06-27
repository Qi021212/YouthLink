// ============================================================
// 修改后的 CounselorHomePage.ets（去掉旧台账功能）
// ============================================================

import { router, promptAction } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { AuthManager } from '../../../core/auth/AuthManager'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { common } from '@kit.AbilityKit'
import { UserInfoJson, RoleType } from '../../../common/model/UserInfo'
import { RiskBadge } from '../../../common/components/RiskBadge'
import { WarningEvent } from '../model/WarningEvent'
import { CounselorService } from '../service/CounselorService'
import { CounselorStorage } from '../service/CounselorStorage'

// ============================================================
// 导入台账页面
// ============================================================
import { FamilyCoopPage } from './FamilyCoopPage'

class QuickAction {
  label: string
  subtitle: string
  icon: string
  color: string
  route: string

  constructor(label: string, subtitle: string, icon: string, color: string, route: string) {
    this.label = label
    this.subtitle = subtitle
    this.icon = icon
    this.color = color
    this.route = route
  }
}

class AlertSummaryItem {
  label: string
  count: string
  color: string

  constructor(label: string, count: string, color: string) {
    this.label = label
    this.count = count
    this.color = color
  }
}

@Entry
@Component
struct CounselorHomePage {
  @State currentTab: number = 0
  @State warningEvents: WarningEvent[] = []
  @State userName: string = ''
  @State userAvatarChar: string = ''
  @State todayWarningCount: number = 3
  @State pendingCount: number = 5
  @State resolvedCount: number = 12
  @State activeClass: string = '计算机2401'
  @State studentCount: number = 312
  @State monthlyFollowUp: number = 24
  @State managedClasses: string[] = ['计算机2401', '计算机2402', '软件2401', '软件2402', '网络2401', '网络2402']

  private service: CounselorService = new CounselorService()

  private quickActions: QuickAction[] = [
    new QuickAction('班级热力图', '可视化监测班级心理态势', '🗺️', '#4A90D9', RouterPath.HEATMAP),
    new QuickAction('预警追踪', 'AI前哨实时预警跟进', '⚡', '#F97316', RouterPath.WARNING_TIMELINE),
    new QuickAction('风险清单', '重点关注学生明细', '📋', '#EF4444', 'features/counselor/pages/RiskListPage'),
    new QuickAction('半月报预审', '智能评估半月报告', '📊', '#8B5CF6', 'features/counselor/pages/ReportAuditPage'),
    new QuickAction('联系台账', '家校协作沟通记录', '📒', '#10B981', 'features/counselor/pages/FamilyCoopPage'),
    new QuickAction('咨询预约', '心理辅导预约管理', '📅', '#F59E0B', 'features/counselor/pages/ConsultManagePage')
  ]

  private alertSummary: AlertSummaryItem[] = [
    new AlertSummaryItem('高危', '2', '#EF4444'),
    new AlertSummaryItem('预警', '4', '#F97316'),
    new AlertSummaryItem('关注', '7', '#FBBF24')
  ]

  aboutToAppear(): void {
    this.loadUserInfo()
    this.loadWarnings()
    this.loadPersistedPreferences()
  }

  async loadPersistedPreferences() {
    let ctx = getContext(this);
    this.activeClass = await CounselorStorage.getClass(ctx);
  }

  private verifyOperationPermission(actionName: string): boolean {
    const currentRole: RoleType = RoleType.COUNSELOR;
    if (currentRole !== RoleType.COUNSELOR && currentRole !== RoleType.SCHOOL_ADMIN) {
      AlertDialog.show({
        title: '🔒 权限拦截',
        message: `您无权执行【${actionName}】。`,
        confirm: { value: '关闭', action: () => { } }
      });
      return false;
    }
    return true;
  }

  private async loadUserInfo(): Promise<void> {
    const authManager = AuthManager.getInstance()
    const json = await authManager.getUserInfoJson()
    try {
      const info: UserInfoJson = JSON.parse(json) as UserInfoJson
      if (info.name && info.name.length > 0) {
        this.userName = info.name
        this.userAvatarChar = info.name.charAt(0)
      } else if (info.uid && info.uid.length > 0) {
        this.userName = info.uid
        this.userAvatarChar = info.uid.charAt(0)
      }
    } catch (err) {
      this.userName = '辅导员'
      this.userAvatarChar = '辅'
    }
    if (this.userName.length === 0) {
      this.userName = '辅导员'
      this.userAvatarChar = '辅'
    }
  }

  private getTimeGreeting(): string {
    const hour = new Date().getHours()
    if (hour >= 6 && hour < 12) { return '上午好' }
    if (hour >= 12 && hour < 14) { return '中午好' }
    if (hour >= 14 && hour < 18) { return '下午好' }
    return '晚上好'
  }

  async loadWarnings(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance()
      if (!dbHelper.isReady()) {
        await dbHelper.ensureInit(getContext(this) as common.UIAbilityContext)
      }
    } catch (err) { }
    const data: WarningEvent[] = await this.service.fetchWarningEvents()
    this.warningEvents = data
    this.calculateDynamicMetrics(data)
  }

  private calculateDynamicMetrics(data: WarningEvent[]): void {
    if (!data || data.length === 0) return;

    let high = 0;
    let warning = 0;
    let watch = 0;

    data.forEach(event => {
      const level = event.riskLevel?.toString() || '';
      if (level.includes('红') || level.includes('3') || level.includes('高危')) {
        high++;
      } else if (level.includes('橙') || level.includes('黄') || level.includes('2') || level.includes('1') || level.includes('预警')) {
        warning++;
      } else {
        watch++;
      }
    });

    this.alertSummary = [
      new AlertSummaryItem('高危', high.toString(), '#EF4444'),
      new AlertSummaryItem('预警', warning.toString(), '#F97316'),
      new AlertSummaryItem('关注', watch.toString(), '#FBBF24')
    ];

    this.todayWarningCount = high;
    this.pendingCount = warning;
  }

  // ============================================================
  // 跳转到台账页面
  // ============================================================
  private navigateToFamilyCoop(): void {
    if (this.verifyOperationPermission('查看联系台账')) {
      router.pushUrl({ url: 'features/counselor/pages/FamilyCoopPage' })
    }
  }

  build() {
    Column() {
      Stack() {
        if (this.currentTab === 0) {
          this.buildWorkbench()
        } else if (this.currentTab === 1) {
          this.buildAlertCenter()
        } else if (this.currentTab === 2) {
          // ============================================================
          // 联系台账 Tab：直接嵌入 FamilyCoopPage 组件
          // ============================================================
          FamilyCoopPage()
        } else {
          this.buildProfile()
        }
      }
      .layoutWeight(1)

      this.buildBottomBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  // ============================================================
  // 工作台 Tab
  // ============================================================
  @Builder
  buildWorkbench(): void {
    Column() {
      this.buildGreeting()

      Scroll() {
        Column() {
          this.buildStatRow()
          this.buildQuickList()
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
  buildGreeting(): void {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(this.activeClass)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_ON_PRIMARY)

            Select(this.managedClasses.map((cls): SelectOption => ({ value: cls } as SelectOption)))
              .selected(0)
              .value('切换班级')
              .font({ size: 12 })
              .fontColor(Colors.TEXT_ON_PRIMARY)
              .backgroundColor('rgba(255,255,255,0.15)')
              .margin({ left: 10 })
              .onSelect(async (idx: number, value: string) => {
                if (!this.verifyOperationPermission('管理班级动态切换')) return;
                let ctx = getContext(this);
                this.activeClass = value;
                await CounselorStorage.saveClass(ctx, value);
                promptAction.showToast({ message: `已切入 ${value} 数据核心` });
              })
          }

          Text(this.userName + '，' + this.getTimeGreeting())
            .fontSize(13)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(0.7)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 44, height: 44 })
            .fill('rgba(255,255,255,0.2)')
          Text(this.userAvatarChar).fontSize(18).fontColor(Colors.TEXT_ON_PRIMARY)
        }
      }
      .width('100%')
      .padding({
        left: 24,
        right: 24,
        top: 16,
        bottom: 16
      })
    }
    .width('100%')
    .backgroundColor(Colors.PRIMARY)
    .borderRadius({ bottomLeft: 24, bottomRight: 24 })
  }

  @Builder
  buildStatRow(): void {
    Row() {
      Column() {
        Text(this.todayWarningCount.toString())
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#EF4444')
        Text('今日预警')
          .fontSize(12)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })

      Column()
        .width(1)
        .height(40)
        .backgroundColor('#F3F4F6')

      Column() {
        Text(this.pendingCount.toString())
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F97316')
        Text('待处理')
          .fontSize(12)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })

      Column()
        .width(1)
        .height(40)
        .backgroundColor('#F3F4F6')

      Column() {
        Text(this.resolvedCount.toString())
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#34D399')
        Text('本月已处理')
          .fontSize(12)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .padding({ left: 4, right: 4 })
    }
    .width('88%')
    .padding({ top: 12, bottom: 12, left: 8, right: 8 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(14)
    .shadow({ radius: 8, color: Colors.SHADOW, offsetY: 2 })
    .margin({ top: 16 })
  }

  @Builder
  buildQuickList(): void {
    Column() {
      Text('功能入口')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ top: 24, bottom: 16 })
        .alignSelf(ItemAlign.Start)

      ForEach(this.quickActions, (item: QuickAction) => {
        Row() {
          Column() {
            Text(item.icon)
              .fontSize(28)
          }
          .width(60)
          .height(60)
          .borderRadius(14)
          .backgroundColor(item.color + '20')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(item.label)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)

            Text(item.subtitle)
              .fontSize(12)
              .fontColor(Colors.TEXT_SECONDARY)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 14 })
          .layoutWeight(1)

          Text('>')
            .fontSize(16)
            .fontColor(Colors.TEXT_HINT)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Colors.CARD_BG)
        .borderRadius(14)
        .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
        .margin({ bottom: 12 })
        .onClick(() => {
          if (this.verifyOperationPermission(item.label)) {
            if (item.label === '联系台账') {
              this.navigateToFamilyCoop()
            } else if (item.label === '班级热力图') {
              router.pushUrl({ url: item.route, params: { activeClassName: this.activeClass } })
            } else {
              router.pushUrl({ url: item.route })
            }
          }
        })
      })
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
  }

  // ============================================================
  // 预警中心 Tab
  // ============================================================
  @Builder
  buildAlertCenter(): void {
    Scroll() {
      Column() {
        Text('预警中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .alignSelf(ItemAlign.Start)
          .padding({ top: 16, left: 24, bottom: 14 })

        Row() {
          ForEach(this.alertSummary, (item: AlertSummaryItem) => {
            Column() {
              Text(item.count)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(item.color)
              Text(item.label)
                .fontSize(12)
                .fontColor(Colors.TEXT_SECONDARY)
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .height(72)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(12)
            .margin({ left: 6, right: 6 })
            .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 1 })
          })
        }
        .width('100%')
        .padding({ left: 18, right: 18 })

        Text('最新预警事件')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .alignSelf(ItemAlign.Start)
          .padding({ top: 22, left: 24, bottom: 10 })

        ForEach(this.warningEvents, (event: WarningEvent) => {
          this.buildWarningCard(event)
        })

        if (this.warningEvents.length === 0) {
          Text('暂无预警事件')
            .fontSize(14)
            .fontColor(Colors.TEXT_HINT)
            .margin({ top: 40 })
        }
      }
      .padding({ bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  buildWarningCard(event: WarningEvent): void {
    Row() {
      Column() {
        Row() {
          Text(event.studentName)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
          Text('·')
            .fontSize(15)
            .fontColor(Colors.TEXT_HINT)
            .margin({ left: 6, right: 6 })
          Text(event.eventType)
            .fontSize(13)
            .fontColor('#F97316')
          Blank()
          RiskBadge({ riskLevel: event.riskLevel })
        }
        .width('100%')

        Text(event.description)
          .fontSize(13)
          .fontColor(Colors.TEXT_SECONDARY)
          .lineHeight(18)
          .margin({ top: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(event.timestamp)
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
          Blank()
          Text('查看 →')
            .fontSize(12)
            .fontColor(Colors.PRIMARY)
            .onClick(() => {
              router.pushUrl({ url: RouterPath.WARNING_TIMELINE })
            })
        }
        .width('100%')
        .margin({ top: 10 })
      }
      .layoutWeight(1)
    }
    .width('88%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(14)
    .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
    .margin({ bottom: 12 })
  }

  // ============================================================
  // 我的 Tab
  // ============================================================
  @Builder
  buildProfile(): void {
    Scroll() {
      Column() {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 64, height: 64 })
              .fill('rgba(74,144,217,0.15)')
            Text(this.userAvatarChar).fontSize(26).fontColor(Colors.PRIMARY)
          }
          .margin({ top: 32 })

          Text(this.userName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
            .margin({ top: 12 })

          Text('计算机学院2024级辅导员')
            .fontSize(13)
            .fontColor(Colors.TEXT_SECONDARY)
            .margin({ top: 4 })

          Row() {
            Column() {
              Text(this.managedClasses.length.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Colors.TEXT_PRIMARY)
              Text('管辖班级').fontSize(11).fontColor(Colors.TEXT_SECONDARY).margin({ top: 2 })
            }
            .layoutWeight(1)

            Column() {
              Text(this.studentCount.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Colors.TEXT_PRIMARY)
              Text('学生总数').fontSize(11).fontColor(Colors.TEXT_SECONDARY).margin({ top: 2 })
            }
            .layoutWeight(1)

            Column() {
              Text(this.monthlyFollowUp.toString()).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Colors.TEXT_PRIMARY)
              Text('本月跟进').fontSize(11).fontColor(Colors.TEXT_SECONDARY).margin({ top: 2 })
            }
            .layoutWeight(1)
          }
          .width('84%')
          .margin({ top: 24, bottom: 28 })
          .padding({ top: 16, bottom: 16 })
          .backgroundColor(Colors.BACKGROUND)
          .borderRadius(12)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Text('设置')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .alignSelf(ItemAlign.Start)
          .padding({ left: 24, bottom: 10 })

        this.buildProfileItem('账号与安全', '管理密码与登录方式', () => {
          if (!this.verifyOperationPermission('修改密码')) return;
          router.pushUrl({ url: 'features/auth/pages/ChangePasswordPage' });
        })

        this.buildProfileItem('数据范围', `当前管辖：${this.managedClasses.length}个班级`, () => {
          AlertDialog.show({
            title: '管辖班级清单',
            message: this.managedClasses.join('\n'),
            confirm: {
              value: '关闭',
              action: () => { }
            }
          });
        })

        this.buildProfileItem('关于青心链', 'v1.0.0 辅导员生产版', () => {
          AlertDialog.show({
            title: '关于青心链',
            message: '青心链心理预警系统 v1.0.0\n专为高校辅导员设计，提供班级心理态势感知与危机闭环管理。\n开发者：软件工程小组',
            confirm: {
              value: '确定',
              action: () => { }
            }
          });
        })

        Button('退出登录')
          .fontSize(15)
          .fontColor('#EF4444')
          .backgroundColor('#FEE2E2')
          .borderRadius(12)
          .height(46)
          .width('88%')
          .margin({ top: 28, bottom: 40 })
          .onClick(() => {
            AlertDialog.show({
              title: '退出确认',
              message: '确定要退出登录吗？',
              confirm: {
                value: '退出',
                action: async () => {
                  const authManager = AuthManager.getInstance()
                  await authManager.logout()
                  router.replaceUrl({ url: RouterPath.LOGIN })
                }
              },
              cancel: () => { }
            })
          })
      }
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  buildProfileItem(title: string, subtitle: string, onClickAction?: () => void): void {
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
        onClickAction();
      }
    })
  }

  // ============================================================
  // 底部导航栏
  // ============================================================
  @Builder
  buildBottomBar(): void {
    Row() {
      this.buildTabItem('工作台', '◉', 0)
      this.buildTabItem('预警中心', '⚡', 1)
      this.buildTabItem('联系台账', '📒', 2)
      this.buildTabItem('我的', '⊙', 3)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor(Colors.SURFACE)
    .border({ width: { top: 1 }, color: '#F3F4F6' })
  }

  @Builder
  buildTabItem(label: string, icon: string, index: number): void {
    Column() {
      Text(icon)
        .fontSize(20)
        .fontColor(this.currentTab === index ? Colors.PRIMARY : Colors.TEXT_HINT)
      Text(label)
        .fontSize(11)
        .fontColor(this.currentTab === index ? Colors.PRIMARY : Colors.TEXT_HINT)
        .margin({ top: 2 })
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (index === 1) {
        router.pushUrl({ url: RouterPath.WARNING_TIMELINE })
      } else {
        this.currentTab = index
      }
    })
  }
}