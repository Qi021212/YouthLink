import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { AuthManager } from '../../../core/auth/AuthManager'
import { UserInfoJson } from '../../../common/model/UserInfo'
import { RiskAlgorithm, ReportSummary } from '../../../common/utils/RiskAlgorithm'
import { ActivityPage } from './ActivityPage'
import { BookingHistorySummary } from '../model/BookingModel'
import { BookingService } from '../service/BookingService'

interface ModuleCard {
  title: string
  subtitle: string
  route: string
  bgColor: string
  icon: string
}

@Entry
@Component
struct StudentHomePage {
  @State userName: string = '同学'
  @State currentIndex: number = 0

  @State historyReports: Array<ReportSummary> = [];

  @State bookingHistoryList: BookingHistorySummary[] = [];

  private tabsController: TabsController = new TabsController()

  // 调节练习卡片数据
  private moduleCards: ModuleCard[] = [
    {
      title: '沉浸式呼吸',
      subtitle: '跟随节奏，平复焦虑',
      route: RouterPath.BREATHING,
      bgColor: Colors.BREATHING_INHALE,
      icon: '🫁'
    },
    {
      title: '专注追踪',
      subtitle: '心流练习，转移注意力',
      route: RouterPath.ATTENTION,
      bgColor: Colors.MORANDI_BLUE,
      icon: '🎯'
    },
    {
      title: '节律敲击',
      subtitle: '触觉释放，宣泄情绪',
      route: RouterPath.RHYTHM,
      bgColor: Colors.MORANDI_PURPLE,
      icon: '🥁'
    },
    {
      title: '波形静观',
      subtitle: '视觉跟随，平静思绪',
      route: RouterPath.CALM_WAVE,
      bgColor: Colors.MORANDI_PURPLE,
      icon: '🌊'
    }
  ]

  async loadBookingHistory() {
    const bookingService = BookingService.getInstance();
    await bookingService.init(getContext(this));
    this.bookingHistoryList = await bookingService.getBookingHistoryList();
    console.info(`加载到 ${this.bookingHistoryList.length} 条预约历史`);
  }

  // 定义一个加载历史的方法，在 aboutToAppear() 或者页面的 onPageShow() 里调用它
  async loadHistoryReports() {
    this.historyReports = await RiskAlgorithm.getHistoryList(getContext(this));
  }

  // 格式化时间戳为简短时间显示
  private formatTimeFromTimestamp(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const now: Date = new Date();
    const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const targetDate: Date = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    const diffDays: number = Math.floor((today.getTime() - targetDate.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return '今天';
    } else if (diffDays === 1) {
      return '昨天';
    } else if (diffDays < 7) {
      return `${diffDays}天前`;
    } else {
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    }
  }

  aboutToAppear(): void {
    // 1. 静默触发异步历史报告拉取
    this.loadHistoryReports();

    // 2. 正常的同步状态获取
    const authManager = AuthManager.getInstance();
    const memName = authManager.getUserName();
    if (memName.length > 0) {
      this.userName = memName;
    } else {
      // 3. 将原本的 await 语句改用原生的 .then() 异步链式调用
      authManager.getUserInfoJson().then((json: string) => {
        try {
          const info: UserInfoJson = JSON.parse(json) as UserInfoJson;
          if (info.name && info.name.length > 0) {
            this.userName = info.name;
            authManager.setUserName(info.name);
          } else if (info.uid && info.uid.length > 0) {
            this.userName = info.uid;
            authManager.setUserName(info.uid);
          }
        } catch (err) {
          console.error('解析缓存用户信息失败:', err);
        }
      });
    }

    // 加载预约历史
    this.loadBookingHistory();
  }

  // 添加 onPageShow 方法，每次显示页面时刷新历史记录
  onPageShow(): void {
    // 每次回到首页时刷新预约历史
    this.loadBookingHistory();
  }

  onLogout(): void {
    AlertDialog.show({
      title: '退出登录',
      message: '确定要退出登录吗？',
      confirm: {
        value: '确定',
        action: () => {
          const authManager = AuthManager.getInstance()
          authManager.logout()
          router.replaceUrl({ url: RouterPath.LOGIN })
        }
      },
      cancel: () => {
      }
    })
  }

  // 顶部用户信息栏 - 右上角退出按钮
  @Builder
  UserHeader() {
    Column() {
      Row() {
        Column() {
          Text(`你好，${this.userName}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_ON_PRIMARY)

          Text('今天感觉怎么样？')
            .fontSize(14)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(0.8)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 退出按钮 - 简洁的文字样式
        Text('退出')
          .fontSize(14)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .opacity(0.8)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => {
            this.onLogout()
          })
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

  // 调节练习列表构建器
  @Builder
  RegulationExercises() {
    Column() {
      Text('调节练习')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      List() {
        ForEach(this.moduleCards, (item: ModuleCard) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.icon)
                  .fontSize(32)
              }
              .width(60)
              .height(60)
              .borderRadius(14)
              .backgroundColor(item.bgColor + '25')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text(item.title)
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

              Image($r('app.media.startIcon'))
                .width(18)
                .height(18)
                .fillColor(Colors.TEXT_HINT)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(14)
            .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
            .onClick(() => {
              router.pushUrl({ url: item.route })
            })
            .animation({ duration: 250, curve: Curve.Friction })
            .stateStyles({
              pressed: {
                .scale({ x: 0.96, y: 0.96 })
                .opacity(0.9)
              },
              normal: {
                .scale({ x: 1.0, y: 1.0 })
                .opacity(1.0)
              }
            })
          }
          .margin({ bottom: 14 })
        })
      }
      .width('100%')
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0 })
    }
    .width('100%')
    .padding(24)
    .layoutWeight(1)
  }

  // 底部 TabBar 组件
  @Builder
  TabBuilder(title: string, targetIndex: number, iconStr: string) {
    Column() {
      Text(iconStr)
        .fontSize(20)
        .margin({ bottom: 4 })
        .opacity(this.currentIndex === targetIndex ? 1 : 0.5)
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
        .fontSize(11)
        .fontWeight(this.currentIndex === targetIndex ? 500 : 400)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex
      this.tabsController.changeIndex(targetIndex)
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {

      // ---------- 第 1 个 Tab：首页 ----------
      TabContent() {
        Column() {
          this.UserHeader()

          Column() {
            // 日常记录功能入口
            Row() {
              Column() {
                Text('📝')
                  .fontSize(32)
              }
              .width(60)
              .height(60)
              .borderRadius(14)
              .backgroundColor(Colors.MORANDI_GREEN + '25')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text('日常记录')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Colors.TEXT_PRIMARY)

                Text('记录每日心情与感受')
                  .fontSize(12)
                  .fontColor(Colors.TEXT_SECONDARY)
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 14 })
              .layoutWeight(1)

              Image($r('app.media.startIcon'))
                .width(18)
                .height(18)
                .fillColor(Colors.TEXT_HINT)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(14)
            .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
            .margin({ bottom: 24 })
            .onClick(() => {
              router.pushUrl({ url: RouterPath.MOOD_CHECK_IN })
            })

            // 快捷入口标题
            Text('快捷功能')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .margin({ bottom: 16 })
              .alignSelf(ItemAlign.Start)

            // 四个快捷入口卡片
            Grid() {
              GridItem() {
                Column() {
                  Text('🧘')
                    .fontSize(28)
                    .margin({ bottom: 8 })
                  Text('自助调节')
                    .fontSize(13)
                    .fontColor(Colors.TEXT_PRIMARY)
                }
                .width('100%')
                .height(80)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(Colors.BREATHING_INHALE + '20')
                .borderRadius(12)
                .onClick(() => {
                  this.currentIndex = 1
                  this.tabsController.changeIndex(1)
                })
                .animation({ duration: 250, curve: Curve.Friction })
                .stateStyles({
                  pressed: {
                    .scale({ x: 0.94, y: 0.94 })
                    .opacity(0.8)
                  },
                  normal: {
                    .scale({ x: 1.0, y: 1.0 })
                    .opacity(1.0)
                  }
                })
              }

              GridItem() {
                Column() {
                  Text('📊')
                    .fontSize(28)
                    .margin({ bottom: 8 })
                  Text('半月报')
                    .fontSize(13)
                    .fontColor(Colors.TEXT_PRIMARY)
                }
                .width('100%')
                .height(80)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(Colors.MORANDI_BLUE + '20')
                .borderRadius(12)
                .onClick(() => {
                  this.currentIndex = 2
                  this.tabsController.changeIndex(2)
                })
                .animation({ duration: 250, curve: Curve.Friction })
                .stateStyles({
                  pressed: {
                    .scale({ x: 0.94, y: 0.94 })
                    .opacity(0.8)
                  },
                  normal: {
                    .scale({ x: 1.0, y: 1.0 })
                    .opacity(1.0)
                  }
                })
              }

              GridItem() {
                Column() {
                  Text('💬')
                    .fontSize(28)
                    .margin({ bottom: 8 })
                  Text('咨询预约')
                    .fontSize(13)
                    .fontColor(Colors.TEXT_PRIMARY)
                }
                .width('100%')
                .height(80)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(Colors.MORANDI_PURPLE + '20')
                .borderRadius(12)
                .onClick(() => {
                  this.currentIndex = 3
                  this.tabsController.changeIndex(3)
                })
                .animation({ duration: 250, curve: Curve.Friction })
                .stateStyles({
                  pressed: {
                    .scale({ x: 0.94, y: 0.94 })
                    .opacity(0.8)
                  },
                  normal: {
                    .scale({ x: 1.0, y: 1.0 })
                    .opacity(1.0)
                  }
                })
              }

              GridItem() {
                Column() {
                  Text('🎉')
                    .fontSize(28)
                    .margin({ bottom: 8 })
                  Text('活动预约')
                    .fontSize(13)
                    .fontColor(Colors.TEXT_PRIMARY)
                }
                .width('100%')
                .height(80)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(Colors.MORANDI_GREEN + '20')
                .borderRadius(12)
                .onClick(() => {
                  this.currentIndex = 4
                  this.tabsController.changeIndex(4)
                })
                .animation({ duration: 250, curve: Curve.Friction })
                .stateStyles({
                  pressed: {
                    .scale({ x: 0.94, y: 0.94 })
                    .opacity(0.8)
                  },
                  normal: {
                    .scale({ x: 1.0, y: 1.0 })
                    .opacity(1.0)
                  }
                })
              }
            }
            .columnsTemplate('1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width('100%')
            .height(180)
          }
          .width('100%')
          .padding(24)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('首页', 0, '🏠'))

      // ---------- 第 2 个 Tab：自助调节 ----------
      TabContent() {
        Column() {
          this.UserHeader()
          this.RegulationExercises()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('自助调节', 1, '🧘'))

      // 3. 🌟 修改后的 TabContent 代码：
      // ---------- 第 3 个 Tab：半月报 ----------
      TabContent() {
        Column() {
          this.UserHeader()

          Column() {
            // 评估入口卡片
            Column() {
              Row() {
                Column() {
                  Text('半月报自适应回顾')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Colors.TEXT_PRIMARY)
                  Text('智能评估最近两周的心理画像与可信度')
                    .fontSize(12)
                    .fontColor(Colors.TEXT_SECONDARY)
                    .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()

                Text('📊')
                  .fontSize(28)
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(16)
            .shadow({ radius: 6, color: '#0A000000', offsetY: 2 })
            .margin({ bottom: 20 })
            .onClick(() => {
              router.pushUrl({ url: RouterPath.SEMI_MONTHLY })
            })

            // 历史报告板块
            Column() {
              Text('历史报告')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
                .margin({ bottom: 12 })
                .alignSelf(ItemAlign.Start)

              // 🌟 核心重构：判断有无历史报告数据
              if (this.historyReports.length === 0) {
                Column() {
                  Text('暂无历史报告')
                    .fontSize(14)
                    .fontColor(Colors.TEXT_HINT)
                    .margin({ top: 20, bottom: 20 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                // 有数据时展示滚动列表
                List({ space: 10 }) {
                  ForEach(this.historyReports, (report: ReportSummary) => {
                    ListItem() {
                      Row() {
                        Column() {
                          Text(`心理健康评估报告`)
                            .fontSize(15)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(Colors.TEXT_PRIMARY)
                          Text(`评估时间: ${report.dateStr}`)
                            .fontSize(12)
                            .fontColor(Colors.TEXT_SECONDARY)
                            .margin({ top: 4 })
                        }
                        .alignItems(HorizontalAlign.Start)

                        Blank()

                        Text('查看详情 ›')
                          .fontSize(13)
                          .fontColor(Colors.PRIMARY)
                      }
                      .width('100%')
                      .padding(14)
                      .backgroundColor('#F7F8FA')
                      .borderRadius(12)
                      .onClick(() => {
                        // 🌟 点击跳转到画像结果页，并把这封报告独有的时间戳通过路由参数传过去
                        router.pushUrl({
                          url: 'features/student/pages/PortraitResultPage',
                          params: {
                            'historicalTimestamp': report.timestamp // 关键传参！
                          }
                        })
                      })
                    }
                  }, (report: ReportSummary) => report.timestamp.toString())
                }
                .width('100%')
                .layoutWeight(1) // 让列表自动填满卡片剩余高度
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(16)
            .layoutWeight(1) // 撑开历史卡片，使其具有自适应容器高度
          }
          .width('100%')
          .padding(24)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('半月报', 2, '📊'))


      // ---------- 第 4 个 Tab：咨询预约 ----------
      TabContent() {
        Column() {
          // 1. 顶部的通用蓝色用户信息栏保持统一
          this.UserHeader()

          // 2. 咨询预约内容
          Column() {
            // 预约入口卡片
            Column() {
              Row() {
                Column() {
                  Text('咨询预约')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Colors.TEXT_PRIMARY)
                  Text('心理咨询室辅导预约')
                    .fontSize(12)
                    .fontColor(Colors.TEXT_SECONDARY)
                    .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)

                Blank()

                Text('💬')
                  .fontSize(28)
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(16)
            .shadow({ radius: 6, color: '#0A000000', offsetY: 2 })
            .margin({ bottom: 20 })
            .onClick(() => {
              router.pushUrl({ url: RouterPath.ROOM_BOOKING })
            })

            // 历史预约记录
            Column() {
              Text('历史预约记录')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
                .margin({ bottom: 12 })
                .alignSelf(ItemAlign.Start)

              if (this.bookingHistoryList.length === 0) {
                Text('暂无历史预约记录')
                  .fontSize(14)
                  .fontColor(Colors.TEXT_HINT)
                  .padding(20)
              } else {
                List({ space: 10 }) {
                  ForEach(this.bookingHistoryList.slice(0, 3), (record: BookingHistorySummary) => {
                    ListItem() {
                      Row() {
                        Column() {
                          Text(`${record.room} · ${record.slot}`)
                            .fontSize(14)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(Colors.TEXT_PRIMARY)
                          Text(`预约时间：${record.dateStr} · 咨询师：${record.consultantName}`)
                            .fontSize(12)
                            .fontColor(Colors.TEXT_SECONDARY)
                            .margin({ top: 4 })
                        }
                        .alignItems(HorizontalAlign.Start)

                        Blank()

                        Text(this.formatTimeFromTimestamp(record.timestamp))
                          .fontSize(12)
                          .fontColor(Colors.TEXT_HINT)
                      }
                      .width('100%')
                      .padding(14)
                      .backgroundColor('#F7F8FA')
                      .borderRadius(12)
                    }
                  }, (record: BookingHistorySummary) => record.id)
                }
                .width('100%')
                .height(200)
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(16)
          }
          .width('100%')
          .padding(24)
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('咨询预约', 3, '💬'))

      // ---------- 第 5 个 Tab：活动预约 ----------
      TabContent() {
        Column() {
          // 1. 顶部的通用蓝色用户信息栏保持统一
          this.UserHeader()

          // 2. 🌟 核心修改：直接实例化你的活动预约动态子页面
          // 将当前的 currentIndex 传递进去，激活它的 @Watch 刷新机制
          ActivityPage({ parentCurrentIndex: this.currentIndex })
            .layoutWeight(1) // 撑满除 Header 外的剩余全部高度
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('活动预约', 4, '🎉'))

    }
    .scrollable(false)
    .backgroundColor(Colors.SURFACE)
    .onChange((index: number) => {
      this.currentIndex = index
      // 只要切到第 3 个 Tab（半月报，索引为 2），就强行静默刷新一次本地 SQLite
      if (index === 2) {
        this.loadHistoryReports()
      }
    })
  }
}