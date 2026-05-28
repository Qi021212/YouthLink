import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { RouterPath } from '../../../common/constants/RouterPath'
import { AuthManager } from '../../../core/auth/AuthManager'
import { UserInfoJson } from '../../../common/model/UserInfo'

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

  async aboutToAppear(): Promise<void> {
    const authManager = AuthManager.getInstance()
    const json = await authManager.getUserInfoJson()
    try {
      const info: UserInfoJson = JSON.parse(json) as UserInfoJson
      if (info.name) {
        this.userName = info.name
      } else if (info.uid) {
        this.userName = info.uid
      }
    } catch (err) {
    }
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
            // .onClick(() => {
            //   // 跳转到日常记录页面
            //   router.pushUrl({ url: RouterPath.DAILY_RECORD })
            // })

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

      // ---------- 第 3 个 Tab：半月报 ----------
      TabContent() {
        Column() {
          this.UserHeader()

          Column() {
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

            // 历史报告
            Column() {
              Text('历史报告')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
                .margin({ bottom: 12 })
                .alignSelf(ItemAlign.Start)

              Text('暂无历史报告')
                .fontSize(14)
                .fontColor(Colors.TEXT_HINT)
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
      .tabBar(this.TabBuilder('半月报', 2, '📊'))

      // ---------- 第 4 个 Tab：咨询预约 ----------
      TabContent() {
        Column() {
          this.UserHeader()

          Column() {
            Text('咨询预约')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .margin({ bottom: 16 })

            Text('心理咨询预约功能')
              .fontSize(14)
              .fontColor(Colors.TEXT_SECONDARY)

            Column() {
              Text('💬')
                .fontSize(48)
                .margin({ bottom: 12 })
              Text('功能开发中...')
                .fontSize(14)
                .fontColor(Colors.TEXT_HINT)
            }
            .width('100%')
            .height(160)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(16)
            .margin({ top: 20 })
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
          this.UserHeader()

          Column() {
            Text('活动预约')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .margin({ bottom: 16 })

            Text('心理健康活动推荐与预约')
              .fontSize(14)
              .fontColor(Colors.TEXT_SECONDARY)

            Column() {
              Text('🎉')
                .fontSize(48)
                .margin({ bottom: 12 })
              Text('功能开发中...')
                .fontSize(14)
                .fontColor(Colors.TEXT_HINT)
            }
            .width('100%')
            .height(160)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(16)
            .margin({ top: 20 })
          }
          .width('100%')
          .padding(24)
          .layoutWeight(1)
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
    })
  }
}