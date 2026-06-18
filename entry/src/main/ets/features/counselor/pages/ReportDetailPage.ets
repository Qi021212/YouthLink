// entry/src/main/ets/features/counselor/pages/ReportDetailPage.ets
import { router, promptAction } from '@kit.ArkUI';
import { Colors } from '../../../common/constants/Colors';
import { ReportData } from '../../../common/model/ReportModel';
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ReportDetailPage {
  @State report: ReportData = new ReportData();

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params.reportJson) {
      let parsed = JSON.parse(params.reportJson) as ReportData;
      this.report.id = parsed.id;
      this.report.studentName = parsed.studentName;
      this.report.className = parsed.className;
      this.report.aiScore = parsed.aiScore;
      this.report.aiCounselorSummary = parsed.aiCounselorSummary;
      this.report.aiStudentPortrait = parsed.aiStudentPortrait;
      this.report.riskLevel = parsed.riskLevel;
      this.report.status = parsed.status;
      this.report.qaHistory = parsed.qaHistory;
      this.report.submitTime = parsed.submitTime;
    }
  }

  // 🌟 真实执行数据库更新
  async processReport(status: string) {
    const db = DatabaseHelper.getInstance();
    const success = await db.updateReportStatus(this.report.id, status);

    if (success) {
      this.report.status = status; // 更新 UI
      promptAction.showToast({ message: '审核操作已保存' });
      // 延迟一下再返回，体验更好
      setTimeout(() => { router.back() }, 500);
    } else {
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回').fontSize(16).fontColor(Colors.PRIMARY).onClick(() => router.back())
        Text('报告详情').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Text('      ').width(40)
      }.width('100%').padding(16).backgroundColor(Colors.SURFACE)

      Scroll() {
        Column({ space: 16 }) {
          // 基础信息
          Column() {
            Text(this.report.studentName).fontSize(20).fontWeight(FontWeight.Bold)
            Text(this.report.className).fontSize(13).fontColor(Colors.TEXT_SECONDARY).margin({ top: 4 })
          }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(Colors.CARD_BG).borderRadius(12)

          // 审核历史进度条
          Column() {
            Text('审核流转进度').fontSize(15).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
            Row() {
              this.buildTimelineNode('学生提交', true, true)
              this.buildTimelineNode('AI 预审', true, this.report.status !== 'pending')
              this.buildTimelineNode('辅导员审核', this.report.status !== 'pending', false)
            }.width('100%').justifyContent(FlexAlign.Center)
          }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(Colors.CARD_BG).borderRadius(12)

          // AI 分析结论
          Column() {
            Row() {
              Text('🤖 AI 智能诊断').fontSize(15).fontWeight(FontWeight.Bold).fontColor(Colors.PRIMARY)
              Blank()
              Text(this.report.riskLevel).fontSize(12).fontColor(this.report.aiScore < 60 ? '#EF4444' : '#10B981')
                .backgroundColor(this.report.aiScore < 60 ? '#FEE2E2' : '#D1FAE5').padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
            }.width('100%')
            Text(this.report.aiCounselorSummary).fontSize(14).fontColor(Colors.TEXT_PRIMARY).margin({ top: 12 }).lineHeight(20)
          }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor('#F0F9FF').borderRadius(12).border({ width: 1, color: '#BAE6FD' })

          // 答卷详情展示
          Column() {
            Text('📝 原始答卷详情').fontSize(15).fontWeight(FontWeight.Bold).margin({ bottom: 12 })
            Text(this.report.qaHistory)
              .fontSize(14)
              .fontColor(Colors.TEXT_SECONDARY)
              .lineHeight(24)
          }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(Colors.CARD_BG).borderRadius(12)

        }.padding(16)
      }.layoutWeight(1).scrollBar(BarState.Off)

      // 底部操作区
      if (this.report.status === 'pending') {
        // 底部操作栏
        Row() {
          Button('驳回修改')
            .backgroundColor(Colors.ERROR)
            .layoutWeight(1)
            .margin({ right: 10 })
            .onClick(async () => {
              try {
                let ctx = getContext(this) as common.UIAbilityContext;
                const db = DatabaseHelper.getInstance();
                await db.ensureInit(ctx);

                // 更新状态为 rejected
                await db.updateReportStatus(this.report.id, 'rejected');

                promptAction.showToast({ message: '已驳回，学生将收到重新提交通知' });
                router.back(); // 操作完返回上一页
              } catch (err) {
                console.error('驳回失败:', JSON.stringify(err));
                promptAction.showToast({ message: '操作失败，请重试' });
              }
            })

          Button('审核通过')
            .backgroundColor(Colors.SUCCESS)
            .layoutWeight(1)
            .onClick(async () => {
              try {
                let ctx = getContext(this) as common.UIAbilityContext;
                const db = DatabaseHelper.getInstance();
                await db.ensureInit(ctx);

                // 更新状态为 approved
                await db.updateReportStatus(this.report.id, 'approved');

                promptAction.showToast({ message: '审核已通过' });
                router.back(); // 操作完返回上一页
              } catch (err) {
                console.error('通过失败:', JSON.stringify(err));
                promptAction.showToast({ message: '操作失败，请重试' });
              }
            })
        }
      }
    }.width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }

  @Builder buildTimelineNode(label: string, isCompleted: boolean, hasLine: boolean) {
    Row() {
      Column() {
        Circle({ width: 12, height: 12 }).fill(isCompleted ? Colors.PRIMARY : '#D1D5DB')
        Text(label).fontSize(11).fontColor(isCompleted ? Colors.TEXT_PRIMARY : Colors.TEXT_HINT).margin({ top: 4 })
      }.width(60)

      if (hasLine) {
        Line().width(40).height(2).backgroundColor(isCompleted ? Colors.PRIMARY : '#D1D5DB').margin({ bottom: 16 })
      }
    }
  }
}