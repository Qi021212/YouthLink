import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { AuthManager } from '../../../core/auth/AuthManager'
import { initStorage } from '../../../common/utils/StorageUtil'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { RouterPath } from '../../../common/constants/RouterPath'
import { Colors } from '../../../common/constants/Colors'

@Entry
@Component
struct SplashPage {
  @State loadingText: string = '正在加载...'
  @State opacityValue: number = 0
  @State logoScale: number = 0.8
  @State subtitleOpacity: number = 0
  @State loadingOpacity: number = 0
  @State bgHue: number = 0

  aboutToAppear(): void {
    this.initApp()
  }

  async initApp(): Promise<void> {
    this.animateIntro()

    try {
      await initStorage(getContext(this))
    } catch (err) {
    }

    try {
      const dbHelper = DatabaseHelper.getInstance()
      await dbHelper.init(getContext(this) as common.UIAbilityContext)
    } catch (err) {
    }

    try {
      const authManager = AuthManager.getInstance()
      const hasSession = await authManager.restoreSession()

      this.opacityValue = 1
      this.logoScale = 1.0
      this.subtitleOpacity = 1
      this.loadingOpacity = 1
      this.loadingText = hasSession ? '欢迎回来' : '欢迎使用青心链'

      setTimeout(() => {
        if (hasSession) {
          router.replaceUrl({ url: RouterPath.STUDENT_HOME })
        } else {
          router.replaceUrl({ url: RouterPath.LOGIN })
        }
      }, 1800)
    } catch (err) {
      setTimeout(() => {
        router.replaceUrl({ url: RouterPath.LOGIN })
      }, 1000)
    }
  }

  animateIntro(): void {
    this.bgHue = 0
    const loopAnim = () => {
    }
    loopAnim()
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 120, height: 120 })
              .fill(Colors.TEXT_ON_PRIMARY + '20')
              .opacity(this.opacityValue)
              .animation({ duration: 1200, curve: Curve.EaseOut })

            Circle({ width: 90, height: 90 })
              .fill(Colors.TEXT_ON_PRIMARY + '35')
              .opacity(this.opacityValue)
              .animation({ duration: 1000, curve: Curve.EaseOut })

            Text('心')
              .fontSize(42)
              .fontColor(Colors.TEXT_ON_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .opacity(this.opacityValue)
              .scale({ x: this.logoScale, y: this.logoScale })
              .animation({ duration: 1000, curve: Curve.EaseOut })
          }
          .width(120)
          .height(120)
          .margin({ bottom: 24 })

          Text('青心链')
            .fontSize(38)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(this.opacityValue)
            .scale({ x: this.logoScale, y: this.logoScale })
            .animation({ duration: 800, curve: Curve.EaseInOut })

          Text('YouthLink')
            .fontSize(14)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(this.subtitleOpacity * 0.75)
            .margin({ top: 8 })
            .animation({ duration: 600, curve: Curve.EaseInOut })

          Text('青春同行，从心出发')
            .fontSize(13)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(this.subtitleOpacity * 0.55)
            .margin({ top: 36 })
            .animation({ duration: 800, curve: Curve.EaseInOut })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 60 })

        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(Colors.TEXT_ON_PRIMARY)
            .opacity(this.loadingOpacity)

          Text(this.loadingText)
            .fontSize(13)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .opacity(this.loadingOpacity * 0.7)
            .margin({ left: 10 })
        }
        .opacity(this.loadingOpacity)
        .animation({ duration: 400, curve: Curve.EaseInOut })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.PRIMARY)
  }
}
