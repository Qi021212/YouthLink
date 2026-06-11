import { DatabaseHelper } from '../../../common/utils/DatabaseHelper';
import { CaseData } from '../model/CaseData';
import { CaseItem } from './CaseItem';

@Entry
@Component
struct CaseListPage {
  @State caseList: CaseData[] = [];

  async aboutToAppear() {
    // 1. 获取单例
    const db = DatabaseHelper.getInstance();
    // 2. 调用实例方法
    this.caseList = await db.getAllCases();
  }

  build() {
    Column() {
      List() {
        ForEach(this.caseList, (item: CaseData) => {
          ListItem() {
            CaseItem({ item: item })
          }
        })
      }
      Button('新建个案').onClick(() => {
        // 跳转或弹出个案表单
      })
    }
  }
}