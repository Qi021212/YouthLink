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
      cancel: () => {}
    })
  }

  build() {
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
        .padding({ left: 24, right: 24, top: 16, bottom: 16 })
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
}
