// entry/src/main/ets/features/counselor/pages/TimelineItem.ets
import { CommunicationRecord } from '../model/CaseData';

@Component
export struct TimelineItem {
  @ObjectLink record: CommunicationRecord; // 使用 @ObjectLink 保持响应式

  build() {
    Row({ space: 10 }) {
      Column() {
        Circle({ width: 10, height: 10 }).fill(Color.Blue)
        Line().width(2).height(40).backgroundColor('#D3D3D3')
      }.width(20)
      Column() {
        Text(this.record.type).fontSize(14).fontWeight(FontWeight.Bold)
        Text(this.record.content).fontSize(12).fontColor(Color.Gray)
      }.alignItems(HorizontalAlign.Start)
    }.padding(5)
  }
}