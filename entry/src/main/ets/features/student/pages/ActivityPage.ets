import { MentalActivity } from '../model/Activity';
import { ActivityDBHelper } from '../../../common/utils/ActivityDBHelper';
import { RiskAlgorithm } from '../../../common/utils/RiskAlgorithm'; // 引入半月报算法
import { promptAction } from '@kit.ArkUI';
import { ActivityFeedbackStore } from '../../../common/utils/ActivityFeedbackStore';

@Component
export struct ActivityPage {
  @Prop @Watch('onTabActive') parentCurrentIndex: number = 0;

  @State searchKeyword: string = '';
  @State userRecentRisks: Array<string> = []; // 动态存储用户的风险标签
  @State recommendedActivities: Array<MentalActivity> = [];
  @State allActivities: Array<MentalActivity> = [];
  @State isPageLoading: boolean = true;
  @State enrolledIds: Array<number> = [];
  // 评价弹窗状态
  @State showRatingSheet: boolean = false;
  @State ratingActivityId: number = 0;
  @State ratingActivityTitle: string = '';
  @State ratingScore: number = 5;

  // 🌟 核心修复：把漏掉的监听回调方法补在这里！
  onTabActive() {
    // 当父组件切换到第 5 个 Tab（活动预约，索引为 4）时，触发本页 SQLite 重刷
    if (this.parentCurrentIndex === 4) {
      this.refreshPageData();
    }
  }

  aboutToAppear() {
    this.refreshPageData();
  }

  /**
   * 🌟 核心修复 1：将英文画像标签映射为活动库的中文标签
   */
  private mapTagsToChinese(englishTags: string[]): string[] {
    const tagMap: Record<string, string> = {
      'ANXIETY': '焦虑',
      'SLEEP_HEALTH': '失眠',
      'SOCIAL': '社交',
      'EMOTION': '抑郁',
      'RESILIENCE': '压力大',
      'MINDSET': '压力大',
      'CAREER': '迷茫'
    };
    let chineseTags: string[] = [];
    englishTags.forEach((tag: string) => {
      if (tag) {
        // 强转大写并剔除两端空格
        const secureTag = tag.toUpperCase().trim();
        if (tagMap[secureTag]) {
          chineseTags.push(tagMap[secureTag]);
        }
      }
    });
    return chineseTags;
  }

  /**
   * 核心联调：打通半月报数据，实现无缝动态推荐
   */
  async refreshPageData() {
    let ctx = getContext(this);
    this.isPageLoading = true;

    console.info('YouthLink_Debug', '=================== 活动页开始触发动态刷新 ===================');

    // --- 模块 A：独立加载“契合推荐”板块 ---
    try {
      const englishRisks = await RiskAlgorithm.calculateRecentRisks(ctx);
      console.info('YouthLink_Debug', '【1.半月报原始标签】: ' + JSON.stringify(englishRisks));

      // 拿到最原始、纯净的中文标签普通数组
      const chineseTags = this.mapTagsToChinese(englishRisks);
      console.info('YouthLink_Debug', '【2.翻译后的中文标签】: ' + JSON.stringify(chineseTags));

      // 🌟 核心刷新：赋值给状态机供页面渲染
      this.userRecentRisks = chineseTags;

      // 🌟 核心修改：传参时直接把最干净的局部变量 chineseTags 送入数据库，实施双层保险
      this.recommendedActivities = [...await ActivityDBHelper.queryRecommended(ctx, chineseTags)];
      console.info('YouthLink_Debug', '【3.契合推荐命中活动数】: ' + this.recommendedActivities.length);
    } catch (e) {
      console.error('YouthLink_Debug', '❌ 契合推荐板块全面崩溃，原因: ', JSON.stringify(e));
      this.recommendedActivities = [];
    }

    // --- 模块 B：全量活动大盘 ---
    try {
      this.allActivities = [...await ActivityDBHelper.queryAll(ctx, this.searchKeyword)];
    } catch (e) {
      console.error('YouthLink_Debug', '❌ 全量活动大盘加载失败:', JSON.stringify(e));
      this.allActivities = [];
    } finally {
      this.isPageLoading = false;
    }
  }

  async handleEnroll(activity: MentalActivity) {
    // 拦截机制：如果已经报名过了，直接拦截
    if (this.enrolledIds.includes(activity.id)) {
      return;
    }
    let ctx = getContext(this);
    let success = await ActivityDBHelper.enroll(ctx, activity.id);
    if (success) {
      promptAction.showToast({ message: '报名成功！名额已实时刷新。' });

      // 将当前 ID 锁死，界面按钮文案会立刻变为“已报名”并置灰
      this.enrolledIds = [...this.enrolledIds, activity.id];

      // 触发底层重刷
      this.refreshPageData();
    } else {
      promptAction.showToast({ message: '报名失败，名额已满员' });
    }
  }

  /**
   * 🌟 动作 B：新增取消报名动作
   */
  async handleCancelEnroll(activity: MentalActivity) {
    let ctx = getContext(this);
    let success = await ActivityDBHelper.cancelEnroll(ctx, activity.id);
    if (success) {
      promptAction.showToast({ message: '已成功取消报名，名额已安全释放。' });
      // 从本地状态锁中无缝剔除
      this.enrolledIds = this.enrolledIds.filter((id: number) => id !== activity.id);
      this.refreshPageData(); // 驱动 SQLite 重新查询，得益于之前的 Key 因子，界面人数会啪的一下减 1
    } else {
      promptAction.showToast({ message: '取消报名失败' });
    }
  }

  // 打开评价弹窗（仅对已报名活动开放）
  openRating(activity: MentalActivity) {
    this.ratingActivityId = activity.id;
    this.ratingActivityTitle = activity.title;
    this.ratingScore = 5;
    this.showRatingSheet = true;
  }

  // 提交评分 → 写入与学校端共享的反馈存储
  async submitRating() {
    await ActivityFeedbackStore.submit('ACT-' + this.ratingActivityId.toString(), this.ratingScore);
    this.showRatingSheet = false;
    promptAction.showToast({ message: '感谢你的评价！' });
  }

  build() {
    Stack() {
      Column() {
      // 1. 顶栏搜索过滤区
      Row() {
        Search({ value: this.searchKeyword, placeholder: '搜索感兴趣的疗愈活动...' })
          .onChange((value: string) => {
            this.searchKeyword = value;
            this.refreshPageData(); // 键入时即时触发 SQLite 的 Like 模糊检索
          })
          .onSubmit(() => {
            this.refreshPageData();
          })
          .width('100%')
          .backgroundColor('#F5F5F5')
      }
      .padding(16)

      if (this.isPageLoading) {
        Column() {
          LoadingProgress().width(48).height(48).color('#007DFF')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 14 }) {

          // 2. 契合推荐板块（只有当用户近期有风险标签、且存在匹配活动、且未在搜索时才抬头展示）
          if (this.searchKeyword.trim() === '' && this.recommendedActivities.length > 0) {
            ListItem() {
              Column() {
                Row() {
                  Text('🎯 契合推荐')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#007DFF')
                  Text(` (基于您半月报评定的 [${this.userRecentRisks.join('/')}] 状态)`)
                    .fontSize(12)
                    .fontColor('#666666')
                }
                .width('100%')
                .margin({ bottom: 10 })

                ForEach(this.recommendedActivities, (item: MentalActivity) => {
                  this.ActivityRowCard(item, true)
                }, (item: MentalActivity) => item.id.toString() + '_' + item.currentQuota.toString()) // 🌟 核心修正：人数变了，Key 必变，强制刷新
              }
              .padding({ left: 16, right: 16, top: 4 })
            }
          }

          // 3. 全量活动板块
          ListItem() {
            Text(this.searchKeyword.trim() === '' ? '全部心理健康活动' : `关于 "${this.searchKeyword}" 的筛选结果`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .padding({ left: 16, top: 4 })
          }

          ForEach(this.allActivities, (item: MentalActivity) => {
            ListItem() {
              this.ActivityRowCard(item, false)
            }
            .padding({ left: 16, right: 16 })
          }, (item: MentalActivity) => item.id.toString() + '_' + item.currentQuota.toString()) // 🌟 核心修正：人数变了，Key 必变，强制刷新
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')

      if (this.showRatingSheet) {
        this.RatingSheet()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 抽离的自适应卡片组件
  @Builder ActivityRowCard(activity: MentalActivity, isRecommend: boolean) {
    Row() {
      Column() {
        Text(activity.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111111')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(activity.type)
            .fontSize(11)
            .fontColor('#007DFF')
            .backgroundColor('#E6F2FF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)

          Text(`调理针对: ${activity.targetState}`)
            .fontSize(12)
            .fontColor(isRecommend ? '#FF9800' : '#888888')
            .fontWeight(isRecommend ? FontWeight.Medium : FontWeight.Normal)
        }
        .margin({ top: 6, bottom: 8 })

        Column({ space: 4 }) {
          Text(`🕒 时间: ${activity.time}`)
            .fontSize(12)
            .fontColor('#777777')
          Text(`📍 地点: ${activity.location}`)
            .fontSize(12)
            .fontColor('#777777')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 8 })

        // 实时名额更新渲染
        Text(`已报名: ${activity.currentQuota} / ${activity.maxQuota} 人`)
          .fontSize(13)
          .fontColor(activity.currentQuota >= activity.maxQuota ? '#FF4D4F' : '#52C41A')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 动态报名按钮 + 评价入口
      Column({ space: 6 }) {
        Button(
          this.enrolledIds.includes(activity.id) ? '取消报名' : // 已报名时，按钮变成取消入口
            (activity.currentQuota >= activity.maxQuota ? '已满员' : '即刻加入')
        )
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(
            this.enrolledIds.includes(activity.id) ? '#FF4D4F' :  // 已报名转为红色警告色，提示可以取消
              (activity.currentQuota >= activity.maxQuota ? '#E5E5E5' : '#007DFF')
          )
          .fontColor('#FFFFFF')
          // 如果是已报名状态，必须允许其再次点击（即 enabled 设为 true）！
          .enabled(activity.currentQuota < activity.maxQuota || this.enrolledIds.includes(activity.id))
          .height(32)
          .borderRadius(16)
          .onClick(() => {
            // 路由分流
            if (this.enrolledIds.includes(activity.id)) {
              this.handleCancelEnroll(activity); // 触发取消
            } else {
              this.handleEnroll(activity); // 触发报名
            }
          })

        // 仅对已报名的活动开放「评价」，评分写入与学校端共享的反馈存储
        if (this.enrolledIds.includes(activity.id)) {
          Button('评价')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#FFF7E6')
            .fontColor('#FF9800')
            .height(32)
            .borderRadius(16)
            .onClick(() => { this.openRating(activity) })
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F7F8FA')
    .borderRadius(16)
    .margin({ bottom: 4 })
  }

  // 学生评价弹窗（1-5 星）
  @Builder RatingSheet() {
    Column() {
      Column()
        .width('100%')
        .layoutWeight(1)
        .onClick(() => { this.showRatingSheet = false })

      Column() {
        Row() {
          Text('活动评价')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111111')
          Blank()
          Text('✕')
            .fontSize(18)
            .fontColor('#999999')
            .onClick(() => { this.showRatingSheet = false })
        }
        .width('100%')
        .margin({ bottom: 8 })

        Text(this.ratingActivityTitle)
          .fontSize(13)
          .fontColor('#888888')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 20 })

        Row() {
          ForEach([1, 2, 3, 4, 5], (star: number) => {
            Text(star <= this.ratingScore ? '★' : '☆')
              .fontSize(36)
              .fontColor('#FF9800')
              .margin({ right: 8 })
              .onClick(() => { this.ratingScore = star })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 24 })

        Button('提交评价')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(10)
          .height(46)
          .width('100%')
          .onClick(() => { this.submitRating() })
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.4)')
  }
}