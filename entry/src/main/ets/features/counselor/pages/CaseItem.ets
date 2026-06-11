// CaseItem.ets
import { CaseRow } from '../../../common/utils/DatabaseHelper'; // 确保路径正确

@Component
export struct CaseItem {
  @ObjectLink item: CaseRow; // 如果是复杂对象，建议加 @Observed 装饰器

  build() {
    Column() {
      Text(this.item.studentName).fontSize(18)
      Text(this.item.status).fontSize(14)
    }
    .padding(10)
    .width('100%')
  }
}