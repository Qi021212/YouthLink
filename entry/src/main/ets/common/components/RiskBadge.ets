@Component
export struct RiskBadge {
  @Prop riskLevel: number = 0

  private riskColors: string[] = ['#34D399', '#FBBF24', '#F97316', '#EF4444']
  private riskLabels: string[] = ['安全', '关注', '预警', '高危']

  build() {
    Text(this.riskLabels[this.riskLevel] || '未知')
      .fontSize(11)
      .fontColor('#FFFFFF')
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(10)
      .backgroundColor(this.riskColors[this.riskLevel] || '#9CA3AF')
  }
}
