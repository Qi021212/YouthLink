// features/student/pages/MoodCheckInPage.ets

import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { MoodService } from '../service/MoodService';
import { MoodTag, MoodRecord, WeeklyTrendPoint } from '../model/MoodRecord';

@Entry
@Component
struct MoodCheckInPage {
  @State selectedMood: MoodTag = MoodTag.NORMAL;
  @State moodContent: string = '';
  @State weeklyTrend: WeeklyTrendPoint[] = [];
  @State hasTodayRecord: boolean = false;
  @State todayRecord: MoodRecord | null = null;
  @State motivationQuote: string = '记录此刻的心情，看见真实的自己';
  @State isLoading: boolean = true;
  @State allRecords: MoodRecord[] = [];
  @State isRefreshing: boolean = false;  // 新增：刷新状态

  private moodService: MoodService = MoodService.getInstance();

  private moodOptions: MoodTag[] = [MoodTag.HAPPY, MoodTag.NORMAL, MoodTag.CONFUSED, MoodTag.DOWN, MoodTag.SAD];

  private getMoodEmoji(mood: MoodTag): string {
    switch (mood) {
      case MoodTag.HAPPY: return '😊';
      case MoodTag.NORMAL: return '😐';
      case MoodTag.CONFUSED: return '😕';
      case MoodTag.DOWN: return '😔';
      case MoodTag.SAD: return '😢';
      default: return '😐';
    }
  }

  aboutToAppear(): void {
    this.initPage();
  }

  // 新增：初始化页面，等待服务准备好
  private async initPage(): Promise<void> {
    this.isLoading = true;
    // 等待 MoodService 初始化完成
    await this.moodService.waitForReady();
    await this.loadData();
    this.isLoading = false;
  }

  // 获取今天的所有记录
  private getTodayRecords(): MoodRecord[] {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayStartTime = todayStart.getTime();
    const todayEndTime = todayStartTime + 24 * 60 * 60 * 1000;

    const allRecords = this.moodService.getAllRecords(100);
    const todayRecords: MoodRecord[] = [];
    for (const record of allRecords) {
      if (record.timestamp >= todayStartTime && record.timestamp < todayEndTime) {
        todayRecords.push(record);
      }
    }
    // 按时间倒序（最新的在上面）
    todayRecords.sort((a, b) => b.timestamp - a.timestamp);
    return todayRecords;
  }

  async loadData(): Promise<void> {
    // 重新获取趋势数据
    const newTrend = await this.moodService.getWeeklyTrend();
    this.weeklyTrend = [...newTrend];

    // 获取今天的记录
    const todayRecords = this.getTodayRecords();
    this.allRecords = [...todayRecords];

    // 重新检查今日打卡状态
    this.hasTodayRecord = this.moodService.hasTodayRecord();

    if (this.hasTodayRecord) {
      this.todayRecord = this.moodService.getTodayRecord();
      if (this.todayRecord) {
        this.selectedMood = this.todayRecord.moodTag;
        this.moodContent = this.todayRecord.content;
        this.motivationQuote = this.moodService.getMotivationQuote(this.selectedMood);
      }
    } else {
      this.motivationQuote = '记录此刻的心情，看见真实的自己';
    }
  }

  // 新增：手动刷新数据
  private async refreshData(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    await this.loadData();
    this.isRefreshing = false;
    promptAction.showToast({
      message: '刷新成功',
      duration: 1000
    });
  }

  async submitCheckIn(): Promise<void> {
    if (this.hasTodayRecord) {
      const actionResult = await promptAction.showDialog({
        title: '提示',
        message: '今天已经打卡过了，是否覆盖之前的记录？',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '覆盖', color: '#FF9800' }
        ]
      });
      if (actionResult.index !== 1) {
        return;
      }
    }

    const success = await this.moodService.addMoodRecord(this.selectedMood, this.moodContent);
    if (success) {
      this.motivationQuote = this.moodService.getMotivationQuote(this.selectedMood);
      await this.loadData();
      promptAction.showToast({
        message: this.hasTodayRecord ? '已覆盖今日情绪记录' : '打卡成功！',
        duration: 1500
      });
    } else {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 1500
      });
    }
  }

  // 计算柱子高度
  private getBarHeight(score: number): number {
    return Math.max(4, score / 100 * 80);
  }

  // 获取柱子颜色
  private getBarColor(moodTag?: MoodTag): string {
    if (!moodTag) {
      return '#E0E0E0';
    }
    switch (moodTag) {
      case MoodTag.HAPPY: return '#4CAF50';
      case MoodTag.NORMAL: return '#2196F3';
      case MoodTag.CONFUSED: return '#9C27B0';
      case MoodTag.DOWN: return '#FF9800';
      case MoodTag.SAD: return '#F44336';
      default: return '#BDBDBD';
    }
  }

  // 计算本周情绪均值
  private getWeeklyAverageScore(): number {
    if (this.weeklyTrend.length === 0) {
      return 0;
    }
    let sum: number = 0;
    let count: number = 0;
    for (const point of this.weeklyTrend) {
      if (point.moodTag !== undefined) {
        sum += point.score;
        count++;
      }
    }
    if (count === 0) {
      return 0;
    }
    return sum / count;
  }

  // 获取情绪均值描述文字
  private getAverageScoreDescription(): string {
    const avgScore = this.getWeeklyAverageScore();
    if (avgScore === 0) {
      return '暂无打卡数据';
    } else if (avgScore >= 70) {
      return '整体平稳';
    } else if (avgScore >= 50) {
      return '略有波动';
    } else {
      return '需关注自己';
    }
  }

  // 判断本周是否有打卡记录
  private hasAnyRecordThisWeek(): boolean {
    for (const point of this.weeklyTrend) {
      if (point.moodTag !== undefined) {
        return true;
      }
    }
    return false;
  }

  // 格式化时间
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${hour}:${minute}`;
  }

  // 获取情绪标签的中文显示
  private getMoodTagText(moodTag: MoodTag): string {
    switch (moodTag) {
      case MoodTag.HAPPY: return '开心';
      case MoodTag.NORMAL: return '一般';
      case MoodTag.CONFUSED: return '迷茫';
      case MoodTag.DOWN: return '低落';
      case MoodTag.SAD: return '悲伤';
      default: return '一般';
    }
  }

  build() {
    Column() {
      // 顶部区域（包含标语和刷新按钮）
      this.buildHeader();

      if (this.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#FF9800')
            .margin({ top: 100 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.buildMotivationCard();
            this.buildMoodSelector();
            this.buildOptionalInput();
            this.buildSubmitButton();
            this.buildTrendChart();
            this.buildHistoryList();
          }
          .padding({ left: 20, right: 20, bottom: 20 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // 顶部区域（包含标语和刷新按钮）
  @Builder
  buildHeader() {
    Row() {
      // 左侧占位
      Row()
        .width(40)

      // 中间标语
      Text('记录此刻的心情，看见真实的自己')
        .fontSize(12)
        .fontColor('#999999')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧刷新按钮
      Button() {
        if (this.isRefreshing) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color('#FF9800')
        } else {
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(18)
            .fontColor(['#666666'])
        }
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .onClick(() => {
        this.refreshData();
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .padding({ top: 12, bottom: 12, left: 12, right: 12 })
  }

  @Builder
  buildMotivationCard() {
    Column() {
      Text(this.motivationQuote)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .margin({ top: 16, bottom: 20 })
    .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
  }

  @Builder
  buildMoodSelector() {
    Column() {
      Text('今天的心情是...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.moodOptions, (mood: MoodTag) => {
          this.buildMoodButton(mood)
        }, (mood: MoodTag) => mood.toString())
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width('100%')
    }
    .margin({ bottom: 20 })
  }

  @Builder
  buildMoodButton(mood: MoodTag) {
    Column() {
      Text(this.getMoodEmoji(mood))
        .fontSize(32)
        .margin({ bottom: 6 })
      Text(mood)
        .fontSize(13)
        .fontColor(this.selectedMood === mood ? '#FF9800' : '#666666')
        .fontWeight(this.selectedMood === mood ? FontWeight.Medium : FontWeight.Normal)
    }
    .padding({ top: 10, bottom: 10, left: 8, right: 8 })
    .borderRadius(30)
    .backgroundColor(this.selectedMood === mood ? '#FFF3E0' : Color.White)
    .onClick(() => {
      this.selectedMood = mood;
      // 无论是否已打卡，点击标签都更新激励语
      this.motivationQuote = this.moodService.getMotivationQuote(this.selectedMood);
    })
  }

  @Builder
  buildOptionalInput() {
    Column() {
      Text('写一句（可选）')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      TextArea({ placeholder: '记录此刻的想法...', text: this.moodContent })
        .placeholderColor('#CCCCCC')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .maxLength(200)
        .onChange((value: string) => {
          this.moodContent = value;
        })
        .height(100)
    }
    .margin({ bottom: 20 })
  }

  @Builder
  buildSubmitButton() {
    Button(this.hasTodayRecord ? '覆盖今日记录' : '💖 轻松打卡')
      .width('100%')
      .height(50)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor('#FF9800')
      .borderRadius(25)
      .onClick(() => {
        this.submitCheckIn();
      })
      .margin({ bottom: 20 })
  }

  @Builder
  buildTrendChart() {
    Column() {
      Row() {
        Text('📈 本周情绪趋势')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Text('波动越平缓，状态越稳定')
          .fontSize(11)
          .fontColor('#999999')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.weeklyTrend.length > 0 && this.hasAnyRecordThisWeek()) {
        Row() {
          ForEach(this.weeklyTrend, (point: WeeklyTrendPoint, index: number) => {
            this.buildTrendBar(point)
          }, (point: WeeklyTrendPoint, index: number) => `${point.date}_${index}`)
        }
        .width('100%')
        .padding({ top: 12, bottom: 8 })
        .backgroundColor(Color.White)
        .borderRadius(16)

        if (this.getWeeklyAverageScore() > 0) {
          Text(`本周情绪均值 ${Math.round(this.getWeeklyAverageScore())} 分 · ${this.getAverageScoreDescription()}`)
            .fontSize(11)
            .fontColor('#888888')
            .margin({ top: 12 })
            .alignSelf(ItemAlign.Start)
        }
      } else {
        Text('暂无数据，完成打卡后显示趋势')
          .fontSize(13)
          .fontColor('#999999')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .margin({ top: 8 })
  }

  @Builder
  buildTrendBar(point: WeeklyTrendPoint) {
    Column() {
      Column()
        .width(16)
        .height(this.getBarHeight(point.score))
        .backgroundColor(this.getBarColor(point.moodTag))
        .borderRadius(8)
        .margin({ bottom: 6 })
      Text(point.date)
        .fontSize(11)
        .fontColor('#666666')
    }
    .width(`${100 / 7}%`)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildHistoryList() {
    Column() {
      Row() {
        Text('📋 今日记录')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Text(`共 ${this.allRecords.length} 条`)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 20, bottom: 12 })
      .alignSelf(ItemAlign.Start)

      if (this.allRecords.length > 0) {
        Column() {
          ForEach(this.allRecords, (record: MoodRecord) => {
            this.buildHistoryItem(record)
          }, (record: MoodRecord) => record.id)
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
      } else {
        Text('今日暂无记录，快来打卡吧～')
          .fontSize(13)
          .fontColor('#999999')
          .padding(30)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .margin({ bottom: 20 })
  }

  @Builder
  buildHistoryItem(record: MoodRecord) {
    Row() {
      Row() {
        Text(this.getMoodEmoji(record.moodTag))
          .fontSize(24)
          .margin({ right: 12 })
        Column() {
          Text(this.getMoodTagText(record.moodTag))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          if (record.content.length > 0) {
            Text(record.content.length > 20 ? record.content.substring(0, 20) + '...' : record.content)
              .fontSize(12)
              .fontColor('#999999')
              .maxLines(1)
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)

      Text(this.formatTime(record.timestamp))
        .fontSize(11)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({
      width: { bottom: 1 },
      color: '#F0F0F0'
    })
  }
}

export default MoodCheckInPage;