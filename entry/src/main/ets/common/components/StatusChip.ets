import { Colors } from '../constants/Colors'

@Component
export struct StatusChip {
  @Prop label: string
  @Prop type: string = 'default'

  private bgColor(): string {
    if (this.type === 'success') return Colors.SUCCESS + '20'
    if (this.type === 'warning') return Colors.WARNING + '20'
    if (this.type === 'error') return Colors.ERROR + '20'
    if (this.type === 'info') return Colors.INFO + '20'
    return '#E5E7EB'
  }

  private textColor(): string {
    if (this.type === 'success') return Colors.SUCCESS
    if (this.type === 'warning') return Colors.WARNING
    if (this.type === 'error') return Colors.ERROR
    if (this.type === 'info') return Colors.INFO
    return Colors.TEXT_SECONDARY
  }

  build() {
    Text(this.label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.textColor())
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(4)
      .backgroundColor(this.bgColor())
  }
}
