@CustomDialog
export struct ConfirmDialog {
  controller: CustomDialogController
  title: string = '提示'
  message: string = ''
  confirmText: string = '确定'
  cancelText: string = '取消'
  onConfirm: () => void = () => {}

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')
        .margin({ top: 24, bottom: 12 })

      Text(this.message)
        .fontSize(14)
        .fontColor('#6B7280')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })
        .margin({ bottom: 24 })

      Row() {
        Button(this.cancelText)
          .fontSize(14)
          .fontColor('#6B7280')
          .backgroundColor('#F3F4F6')
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.controller.close()
          })

        Button(this.confirmText)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#4A90D9')
          .borderRadius(8)
          .layoutWeight(1)
          .height(44)
          .margin({ left: 12 })
          .onClick(() => {
            this.controller.close()
            this.onConfirm()
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 24 })
    }
  }
}
