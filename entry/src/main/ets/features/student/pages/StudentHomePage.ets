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
  // 用于控制底部导航栏的状态
  @State currentIndex: number = 0
  private tabsController: TabsController = new TabsController()
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
        .fontSize(12)
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
    //外层容器修改为Tabs组件
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {

      // ---------- 第 1 个 Tab：首页内容 ----------
      TabContent() {
        Column() {
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

              Circle({ width: 48, height: 48 })
                .fill(Colors.TEXT_ON_PRIMARY + '30')
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

          Row() {
            Text('退出登录')
              .fontSize(14)
              .fontColor(Colors.TEXT_HINT)
              .onClick(() => {
                this.onLogout()
              })
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Colors.CARD_BG)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('首页', 0, '🏠'))

      // ---------- 第 2 个 Tab：打卡 (成员B负责的 M2) ----------
      TabContent() {
        Column() {
          Text('情绪感知打卡区').fontSize(20).fontColor(Colors.TEXT_PRIMARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('记录', 1, '📝'))

      // ---------- 第 3 个 Tab：活动 (M9) ----------
      TabContent() {
        Column() {
          Text('心理健康活动推荐').fontSize(20).fontColor(Colors.TEXT_PRIMARY)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('活动', 2, '🎉'))

      // ---------- 第 4 个 Tab：我的 (M7 + 退出登录) ----------
      TabContent() {
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
          .width('90%')
          .padding(20)
          .backgroundColor(Colors.CARD_BG)
          .borderRadius(16)
          .shadow({ radius: 6, color: '#0A000000', offsetY: 2 })
          .margin({ bottom: 40 })
          .onClick(() => {
            router.pushUrl({ url: RouterPath.SEMI_MONTHLY })
          })

          // 退出登录按钮保持不变
          Button('退出登录')
            .width('80%')
            .height(44)
            .backgroundColor(Colors.CARD_BG)
            .fontColor(Colors.ERROR)
            .shadow({ radius: 2, color: '#0A000000', offsetY: 1 })
            .onClick(() => {
              this.onLogout()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Colors.BACKGROUND)
      }
      .tabBar(this.TabBuilder('我的', 3, '👤'))

    }
    .scrollable(false) // 禁止左右滑动，避免与内部页面的手势冲突
    .backgroundColor(Colors.SURFACE)
    .onChange((index: number) => {
      this.currentIndex = index
    })
  }
}
