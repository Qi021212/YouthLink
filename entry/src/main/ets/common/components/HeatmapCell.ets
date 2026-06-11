@Component
export struct HeatmapCell {
  @Prop className: string = ''
  @Prop studentCount: number = 0
  @Prop riskLevel: number = 0
  @Prop isSelected: boolean = false
  onCellClick: () => void = () => {}

  private riskColors: string[] = ['#D1FAE5', '#FEF3C7', '#FED7AA', '#FEE2E2']
  private riskBorderColors: string[] = ['#34D399', '#FBBF24', '#F97316', '#EF4444']
  private riskLabels: string[] = ['低', '中', '险', '危']

  build() {
    Column() {
      Text(this.className)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A2E')

      Text(`${this.studentCount}人`)
        .fontSize(11)
        .fontColor('#6B7280')
        .margin({ top: 4 })

      Text(this.riskLabels[this.riskLevel] || '?')
        .fontSize(10)
        .fontColor(this.riskBorderColors[this.riskLevel] || '#9CA3AF')
        .margin({ top: 2 })
    }
    .width('44%')
    .height(90)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.riskColors[this.riskLevel])
    .borderRadius(12)
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected
        ? this.riskBorderColors[this.riskLevel]
        : '#E5E7EB'
    })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.onCellClick()
    })
  }
}
