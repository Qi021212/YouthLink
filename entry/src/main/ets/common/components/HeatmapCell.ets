class CustomGradient {
  colors: Array<[string, number]> = []
  direction: GradientDirection = GradientDirection.RightBottom
}

@Component
export struct HeatmapCell {
  @Prop className: string = ''
  @Prop studentCount: number = 0
  @Prop riskLevel: number = 0
  @Prop isSelected: boolean = false
  onCellClick: () => void = () => {}

  @State isHovered: boolean = false
  @State isPressed: boolean = false

  private riskGradients: CustomGradient[] = [
    { colors: [['#34D399', 0.0], ['#10B981', 1.0]], direction: GradientDirection.RightBottom }, // Green
    { colors: [['#FCD34D', 0.0], ['#F59E0B', 1.0]], direction: GradientDirection.RightBottom }, // Yellow
    { colors: [['#FB923C', 0.0], ['#EA580C', 1.0]], direction: GradientDirection.RightBottom }, // Orange
    { colors: [['#F87171', 0.0], ['#EF4444', 1.0]], direction: GradientDirection.RightBottom }  // Red
  ]
  private riskShadowColors: string[] = ['rgba(16,185,129,0.3)', 'rgba(245,158,11,0.3)', 'rgba(234,88,12,0.3)', 'rgba(239,68,68,0.3)']
  private riskLabels: string[] = ['安全', '关注', '预警', '高危']
  private riskIcons: Resource[] = [$r('sys.symbol.checkmark_circle_fill'), $r('sys.symbol.exclamationmark_circle_fill'), $r('sys.symbol.exclamationmark_triangle_fill'), $r('sys.symbol.xmark_circle_fill')]

  build() {
    Column() {
      Row() {
        SymbolGlyph(this.riskIcons[this.riskLevel])
          .fontSize(16)
          .fontColor(['#FFFFFF'])
        Text(this.riskLabels[this.riskLevel])
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ left: 4 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ left: 12, top: 12 })

      Blank()

      Column() {
        Text(this.className)
          .fontSize(16)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#FFFFFF')
        Text(`${this.studentCount} 名学生`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.8)')
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, bottom: 12 })
    }
    .width('46%')
    .height(110)
    .linearGradient(this.riskGradients[this.riskLevel])
    .borderRadius(16)
    .shadow({ 
      radius: this.isHovered || this.isSelected ? 16 : 8, 
      color: this.riskShadowColors[this.riskLevel], 
      offsetY: this.isHovered || this.isSelected ? 8 : 4 
    })
    .border({
      width: this.isSelected ? 2 : 0,
      color: '#FFFFFF'
    })
    .scale({ x: this.isPressed ? 0.96 : (this.isHovered ? 1.02 : 1.0), y: this.isPressed ? 0.96 : (this.isHovered ? 1.02 : 1.0) })
    .animation({ duration: 250, curve: Curve.Friction })
    .margin({ bottom: 16 })
    .onClick(() => {
      this.onCellClick()
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) this.isPressed = true
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.isPressed = false
    })
  }
}
