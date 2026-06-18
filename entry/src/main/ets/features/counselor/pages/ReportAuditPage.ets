// entry/src/main/ets/features/counselor/pages/ReportAuditPage.ets
import { router, promptAction } from '@kit.ArkUI';
import { Colors } from '../../../common/constants/Colors';
import { ReportData } from '../../../common/model/ReportModel';
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ReportAuditPage {
  @State currentTab: number = 0; // 0: 待审, 1: 历史
  @State isBatchMode: boolean = false;
  @State selectedIds: string[] = [];
  @State reportList: ReportData[] = [];

  aboutToAppear() {
    this.loadRealData();
  }

  // 🌟 每次页面重新显示（比如从详情页返回）时，自动拉取最新数据
  async onPageShow() {
    await this.loadRealData();
  }

  // 🌟 从 SQLite 真实加载数据
  async loadRealData() {
    const db = DatabaseHelper.getInstance();
    await db.ensureInit(getContext(this) as common.UIAbilityContext);
    this.reportList = await db.getAllReports();
  }

  toggleSelectAll() {
    const pendingList = this.reportList.filter(item => item.status === 'pending');
    if (this.selectedIds.length === pendingList.length) {
      this.selectedIds = [];
    } else {
      this.selectedIds = pendingList.map(item => item.id);
    }
  }

  // 🌟 真实执行批量数据库更新
  async batchProcess(action: 'approve' | 'reject') {
    if (this.selectedIds.length === 0) {
      promptAction.showToast({ message: '请先选择半月报' });
      return;
    }

    const newStatus = action === 'approve' ? 'approved' : 'rejected';
    const db = DatabaseHelper.getInstance();

    // 批量更新数据库
    for (const id of this.selectedIds) {
      await db.updateReportStatus(id, newStatus);
    }

    promptAction.showToast({ message: `已成功${action === 'approve' ? '通过' : '驳回'} ${this.selectedIds.length} 份报告` });

    // 重置状态并刷新列表
    this.selectedIds = [];
    this.isBatchMode = false;
    await this.loadRealData();
  }

  build() {
    Column() {
      // 头部导航
      Row() {
        Text('< 返回').fontSize(16).fontColor(Colors.PRIMARY).onClick(() => router.back())
        Text('半月报 AI 预审').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text(this.isBatchMode ? '取消' : '批量管理')
          .fontSize(15).fontColor(Colors.PRIMARY)
          .onClick(() => {
            this.isBatchMode = !this.isBatchMode;
            this.selectedIds = [];
          })
      }.width('100%').padding(16).backgroundColor(Colors.SURFACE)

      // Tab栏
      Row() {
        Text('待审核').fontSize(16).fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentTab === 0 ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
          .border({ width: { bottom: this.currentTab === 0 ? 2 : 0 }, color: Colors.PRIMARY })
          .padding({ bottom: 8 })
          .onClick(() => this.currentTab = 0)

        Text('审核历史').fontSize(16).fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.currentTab === 1 ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
          .border({ width: { bottom: this.currentTab === 1 ? 2 : 0 }, color: Colors.PRIMARY })
          .padding({ bottom: 8 }).margin({ left: 32 })
          .onClick(() => this.currentTab = 1)
      }.width('100%').padding({ left: 24, top: 10 }).backgroundColor(Colors.SURFACE)

      // 列表区
      List({ space: 12 }) {
        ForEach(this.reportList.filter(r => this.currentTab === 0 ? r.status === 'pending' : r.status !== 'pending'), (item: ReportData) => {
          ListItem() {
            Row() {
              if (this.isBatchMode && this.currentTab === 0) {
                Checkbox({ name: item.id })
                  .select(this.selectedIds.includes(item.id))
                  .onChange((value: boolean) => {
                    if (value) this.selectedIds.push(item.id);
                    else this.selectedIds = this.selectedIds.filter(id => id !== item.id);
                  }).margin({ right: 12 })
              }

              Column() {
                Row() {
                  Text(item.studentName).fontSize(16).fontWeight(FontWeight.Bold)
                  Text(item.className).fontSize(12).fontColor(Colors.TEXT_HINT).margin({ left: 8 })
                  Blank()
                  Text(item.status === 'pending' ? '待处理' : (item.status === 'approved' ? '已通过' : '已驳回'))
                    .fontSize(12)
                    .fontColor(item.status === 'pending' ? '#F59E0B' : (item.status === 'approved' ? '#10B981' : '#EF4444'))
                }.width('100%')

                Text(`AI摘要：${item.aiCounselorSummary}`).fontSize(13).fontColor(Colors.TEXT_SECONDARY).margin({ top: 8 }).maxLines(2)

                // 可信度进度条
                Row() {
                  Text('可信度:').fontSize(12).fontColor(Colors.TEXT_HINT)
                  Progress({ value: item.aiScore, total: 100, type: ProgressType.Linear })
                    .color(item.aiScore > 80 ? '#10B981' : (item.aiScore > 50 ? '#F59E0B' : '#EF4444'))
                    .width('50%').margin({ left: 8, right: 8 })
                  Text(`${item.aiScore}分`).fontSize(12).fontWeight(FontWeight.Bold)
                    .fontColor(item.aiScore > 80 ? '#10B981' : (item.aiScore > 50 ? '#F59E0B' : '#EF4444'))
                }.width('100%').margin({ top: 12 })
              }
              .layoutWeight(1)
              .padding(16)
              .backgroundColor(Colors.CARD_BG)
              .borderRadius(12)
              .onClick(() => {
                if (!this.isBatchMode) {
                  // 将完整对象转为 JSON 传递，规避复杂对象在路由中丢失或类型报错
                  router.pushUrl({ url: 'features/counselor/pages/ReportDetailPage', params: { reportJson: JSON.stringify(item) } })
                }
              })
            }.width('100%').padding({ left: 16, right: 16 })
          }
        })
      }.layoutWeight(1).margin({ top: 12 })

      // 批量操作底部栏
      if (this.isBatchMode && this.currentTab === 0) {
        Row() {
          Checkbox().onChange(() => this.toggleSelectAll())
            .select(this.selectedIds.length > 0 &&
              this.selectedIds.length === this.reportList.filter(r => r.status === 'pending').length)
          Text('全选').fontSize(14).margin({ right: 16 })
          Text(`已选 ${this.selectedIds.length} 项`).fontSize(14).fontColor(Colors.TEXT_SECONDARY).layoutWeight(1)

          Button('批量驳回')
            .backgroundColor(Colors.ERROR)
            .height(40)
            .margin({ right: 12 })
            .onClick(async () => {
              if (this.selectedIds.length === 0) {
                promptAction.showToast({ message: '请先选择要操作的报告' });
                return;
              }

              try {
                let ctx = getContext(this) as common.UIAbilityContext;
                const db = DatabaseHelper.getInstance();
                await db.ensureInit(ctx);

                // 遍历更新选中的报告状态
                for (let id of this.selectedIds) {
                  await db.updateReportStatus(id, 'rejected');
                }

                promptAction.showToast({ message: `已批量驳回 ${this.selectedIds.length} 份报告` });

                // 🌟 修改这里：使用当前类中定义的变量和方法
                this.isBatchMode = false;     // 原为: this.isSelectionMode = false
                this.selectedIds = [];
                await this.loadRealData();    // 原为: await this.loadReports()

              } catch (err) {
                console.error('批量驳回失败:', JSON.stringify(err));
              }
            })

          Button('批量通过')
            .backgroundColor(Colors.SUCCESS)
            .height(40)
            .onClick(async () => {
              if (this.selectedIds.length === 0) {
                promptAction.showToast({ message: '请先选择要操作的报告' });
                return;
              }

              try {
                let ctx = getContext(this) as common.UIAbilityContext;
                const db = DatabaseHelper.getInstance();
                await db.ensureInit(ctx);

                // 遍历更新选中的报告状态
                for (let id of this.selectedIds) {
                  await db.updateReportStatus(id, 'approved');
                }

                promptAction.showToast({ message: `成功通过 ${this.selectedIds.length} 份报告` });

                // 🌟 修改这里：使用当前类中定义的变量和方法
                this.isBatchMode = false;     // 原为: this.isSelectionMode = false
                this.selectedIds = [];
                await this.loadRealData();    // 原为: await this.loadReports()

              } catch (err) {
                console.error('批量通过失败:', JSON.stringify(err));
              }
            })
        }.width('100%').height(60).backgroundColor(Colors.SURFACE).padding({ left: 16, right: 16 })
        .border({ width: { top: 1 }, color: '#EEEEEE' })
      }
    }.width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }
}