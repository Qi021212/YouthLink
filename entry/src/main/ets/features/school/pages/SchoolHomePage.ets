import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'

@Entry
@Component
struct SchoolHomePage {
  build() {
    Column() {
      Row() {
        Text('校级心理中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#6366F1')
      .padding({ top: 24 })

      Column() {
        Text('管理后台建设中...')
          .fontSize(16)
          .fontColor('#6B7280')
          .margin({ top: 60 })

        Text('功能模块开发中')
          .fontSize(13)
          .fontColor('#9CA3AF')
          .margin({ top: 8 })

        Button('返回登录')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(Colors.PRIMARY)
          .borderRadius(10)
          .height(44)
          .width(160)
          .margin({ top: 24 })
          .onClick(() => {
            router.back()
          })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F5F8')
  }
}
