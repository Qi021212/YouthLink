import { router } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'
import { Colors } from '../../../common/constants/Colors'
import { RouterIndex } from '../../../router/RouterIndex'
import {
  RiskAlgorithm,
  RiskQuestion,
  RiskBehavior,
  RiskOption
} from '../../../common/utils/RiskAlgorithm'
import { ReportData } from '../../../common/model/ReportModel';
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper';

// --- 数据模型定义 ---
interface SurveyOption {
  id: string
  text: string
  score: number
}

interface SurveyQuestion {
  id: string
  type: 'SINGLE_CHOICE' | 'TEXT' | 'SLIDER'
  title: string
  tags?: string[]
  options?: SurveyOption[]
}

// 隐性行为追踪数据模型
interface BehaviorRecord {
  enterTime: number     // 进入该题的时间戳（不上传，仅做本地计算）
  totalDuration: number // 累计停留总时长（毫秒）
  modifyCount: number   // 修改答案的次数
}

interface SurveyPayload {
  answers: Record<string, string | number>
  behaviors: Record<string, BehaviorRecord>
}

@Entry
@Component
struct SemiMonthlyPage {
  @State currentIndex: number = 0
  private lastIndex: number = 0 // 用于记录切换前的题目索引

  @State answers: Record<string, string | number> = {}

  // 🌟 新增：存储所有题目的行为轨迹
  @State behaviors: Record<string, BehaviorRecord> = {}

  private swiperController: SwiperController = new SwiperController()

  @State isLoading: boolean = true

  // 模拟从后端拉取的自适应问卷题目
  private questions: SurveyQuestion[] = [ ]

  async aboutToAppear() {
    await this.loadAndExtractQuestions(15) // 每次抽取 15 道题
  }

  async loadAndExtractQuestions(extractCount: number) {
    this.isLoading = true
    try {
      // 1. 解析本地全量题库
      const context = getContext(this)
      // 如果文件不存在或路径不对，这里会抛出异常进入 catch
      const rawFileContent = await context.resourceManager.getRawFileContent('questions.json')
      const jsonString = util.TextDecoder.create('utf-8').decodeToString(rawFileContent)
      const allQuestions: SurveyQuestion[] = JSON.parse(jsonString) as SurveyQuestion[]

      // 2. 读取用户的近期风险画像（模拟从 StorageUtil 获取）
      // 现在换成动态算法计算：
      const userRecentRisks: string[] = await RiskAlgorithm.calculateRecentRisks(getContext(this))
      let extracted: SurveyQuestion[] = []

      // 3. 如果用户状态完全健康（无风险标签），则回退到全量随机盲抽
      if (userRecentRisks.length === 0) {
        // 🐛 这里已修复：改为赋值给局部变量 extracted，而不是直接赋值给 this.questions
        extracted = this.getRandomSubArray(allQuestions, extractCount)
      } else {
        // 4. 智能自适应分流：将题库划分为【高相关池】和【普通池】
        const targetedPool = allQuestions.filter(q => q.tags && q.tags.some(tag => userRecentRisks.includes(tag)))
        const generalPool = allQuestions.filter(q => !q.tags || !q.tags.some(tag => userRecentRisks.includes(tag)))

        // 5. 权重分配策略：60% 为针对性题目，40% 为其他维度的随机题目（防止陷入信息茧房，探索潜在的新问题）
        let targetedQuota = Math.floor(extractCount * 0.6)

        // 容错处理：如果高相关题库数量不够，就全拿出来
        if (targetedPool.length < targetedQuota) {
          targetedQuota = targetedPool.length
        }
        const generalQuota = extractCount - targetedQuota

        // 6. 分别从两个池子里随机抽取
        const selectedTargeted = this.getRandomSubArray(targetedPool, targetedQuota)
        const selectedGeneral = this.getRandomSubArray(generalPool, generalQuota)

        // 7. 合并后【再次洗牌】！
        // 极其重要：打乱顺序是为了防止用户连续做到 6 道关于睡眠的题而产生枯燥感或防备心理
        extracted = this.getRandomSubArray([...selectedTargeted, ...selectedGeneral], extractCount)
      }

      // 8. 初始化行为追踪
      let tempBehaviors: Record<string, BehaviorRecord> = {}
      extracted.forEach((q) => {
        tempBehaviors[q.id] = { enterTime: 0, totalDuration: 0, modifyCount: 0 } as BehaviorRecord
      })
      if (extracted.length > 0) {
        tempBehaviors[extracted[0].id].enterTime = Date.now()
      }

      // 🌟 核心修复：调整赋值顺序
      this.behaviors = tempBehaviors
      this.currentIndex = 0      // 必须先重置当前题号为 0
      this.lastIndex = 0         // 必须先重置上一题号为 0
      this.questions = extracted // 最后再赋值给 questions 触发 UI 渲染

    } catch (err) {
      console.error('自适应抽题引擎加载失败:', err)
    } finally {
      setTimeout(() => { this.isLoading = false }, 500)
    }
  }

  // 经典洗牌算法 (保持不变)
  private getRandomSubArray(arr: SurveyQuestion[], count: number): SurveyQuestion[] {
    const result = [...arr]
    let m = result.length
    while (m > 0) {
      const i = Math.floor(Math.random() * m--)
      const temp = result[m]
      result[m] = result[i]
      result[i] = temp
    }
    return result.slice(0, count)
  }

  // 🌟 新增：统一的答案与行为记录更新器
  updateAnswerAndBehavior(questionId: string, newValue: string | number) {
    const oldValue = this.answers[questionId]

    // 只有当答案真正发生改变时，才记录为“修改”
    if (oldValue !== newValue) {
      this.answers[questionId] = newValue

      // 如果这不是第一次作答（oldValue有值），则算作一次修改
      if (oldValue !== undefined) {
        this.behaviors[questionId].modifyCount += 1
      }
    }
  }

  // 单选题点击逻辑
  handleSingleChoice(questionId: string, optionId: string) {
    this.updateAnswerAndBehavior(questionId, optionId)

    if (this.currentIndex < this.questions.length - 1) {
      // 延时翻页，保证 UI 动画流畅
      setTimeout(() => {
        this.swiperController.showNext()
      }, 300)
    }
  }

  // 提交问卷与埋点数据
  async submitSurvey() {
    const finalId = this.questions[this.currentIndex].id
    const now = Date.now()
    this.behaviors[finalId].totalDuration += (now - this.behaviors[finalId].enterTime)

    // 1. 移交公用引擎进行分数判定与持久化
    const currentBatchTimestamp = await RiskAlgorithm.evaluateAndSave(getContext(this), this.questions, this.answers, this.behaviors)

    // 核心新增：基于行为数据的“防糊弄”可信度算法 (0-100分)
    let totalDurationMs = 0;
    let totalModifications = 0;

    // 汇总所有题目的作答时间和修改次数
    Object.values(this.behaviors).forEach(b => {
      totalDurationMs += b.totalDuration;
      totalModifications += b.modifyCount;
    });

    // 计算平均每题耗时 (毫秒)
    const avgTimePerQuestion = totalDurationMs / this.questions.length;
    let credibility = 100;

    // 惩罚机制 1：作答过快（秒选）
    if (avgTimePerQuestion < 1200) {
      // 平均每题不到 1.2 秒，几乎没看题，重度瞎填
      credibility -= 50;
    } else if (avgTimePerQuestion < 2500) {
      // 平均每题不到 2.5 秒，敷衍了事
      credibility -= 20;
    }

    // 惩罚机制 2：零思考、零修改且速度偏快
    if (totalModifications === 0 && avgTimePerQuestion < 3000) {
      credibility -= 10;
    }

    // 边界保护
    credibility = Math.max(0, Math.min(100, Math.round(credibility)));

    // 🚀 核心升级：问卷全量动态答案语义序列化
    let qaTextList: string[] = []

    this.questions.forEach((q: RiskQuestion) => {
      const answer = this.answers[q.id]
      if (answer === undefined) {
        return // 跳过未做的题
      }

      let actualAnswerText = ''

      // 如果是单选题，遍历找到对应的选项文本，确保 AI 读到的是字面意思而不是 ID 编码
      if (q.type === 'SINGLE_CHOICE' && q.options) {
        const matchedOption = q.options.find((opt: RiskOption) => opt.id === answer)
        if (matchedOption) {
          actualAnswerText = matchedOption.text
        }
      }
      // 如果是滑动条或主观题，直接转换或提取文本内容
      else if (q.type === 'SLIDER') {
        actualAnswerText = `${answer}分（0-10分制）`
      }
      else if (q.type === 'TEXT') {
        actualAnswerText = answer.toString()
      }

      qaTextList.push(`问题：${q.title}\n回答：${actualAnswerText}`)
    })

    // 将所有题目的问答用双换行拼接成一段宏大的文本日志
    const fullQaHistory = qaTextList.join('\n\n')

    // 3. 路由跳转并传递数据至画像页 (将原本单一的树洞文本升级为全量回答历史)
    RouterIndex.replace('features/student/pages/PortraitResultPage', {
      'fullQaHistory': fullQaHistory,
      'currentTimestamp': currentBatchTimestamp, // 👈 传过去，方便结果页拿到 AI 文本后跟它绑定
      'credibilityScore': credibility
    })
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(64).height(64).color(Colors.PRIMARY)
          Text('正在为您生成专属评估问卷...').fontSize(16).fontColor(Colors.TEXT_SECONDARY).margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.questions || this.questions.length === 0) {
        Column() {
          Text('⚠️ 题库加载失败').fontSize(22).fontWeight(FontWeight.Bold).fontColor(Colors.ERROR).margin({ bottom: 12 })
          Text('未能读取到本地题库文件').fontSize(16).fontColor(Colors.TEXT_PRIMARY)
          Text('请确保文件位于: entry/src/main/resources/rawfile/questions.json').fontSize(12).fontColor(Colors.TEXT_SECONDARY).margin({ top: 8, bottom: 24 }).textAlign(TextAlign.Center)
          Button('返回').backgroundColor(Colors.PRIMARY).onClick(() => router.back())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding(24)
      } else {
        // 顶部导航与进度条
        Row() {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
            .onClick(() => router.back())

          Progress({ value: this.currentIndex + 1, total: this.questions.length, type: ProgressType.Linear })
            .color(Colors.PRIMARY)
            .layoutWeight(1)
            .margin({ left: 16, right: 16 })

          Text(`${this.currentIndex + 1}/${this.questions.length}`)
            .fontColor(Colors.TEXT_SECONDARY)
            .fontSize(14)
        }
        .width('100%')
        .padding(24)

        // 核心组件：Swiper 容器
        Swiper(this.swiperController) {
          ForEach(this.questions, (item: SurveyQuestion) => {
            Column() {
              Text(item.title)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)
                .margin({ bottom: 32 })
                .width('100%')

              // 根据题型动态渲染对应的 UI 组件
              if (item.type === 'SINGLE_CHOICE' && item.options) {
                ForEach(item.options, (opt: SurveyOption) => {
                  Button(opt.text)
                    .width('100%')
                    .height(56)
                    .backgroundColor(this.answers[item.id] === opt.id ? Colors.PRIMARY : Colors.CARD_BG)
                    .fontColor(this.answers[item.id] === opt.id ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)
                    .margin({ bottom: 16 })
                    .borderRadius(12)
                    .onClick(() => this.handleSingleChoice(item.id, opt.id))
                })
              } else if (item.type === 'SLIDER') {
                Slider({
                  value: (this.answers[item.id] as number) || 5,
                  min: 0, max: 10, step: 1,
                  style: SliderStyle.OutSet
                })
                  .blockColor(Colors.PRIMARY)
                  .trackColor(Colors.SURFACE)
                  .selectedColor(Colors.PRIMARY)
                  .showSteps(true)
                  // 🌟 滑动条松手时才触发更新，避免滑动过程中产生大量无效的 modifyCount
                  .onChange((value: number, mode: SliderChangeMode) => {
                    if (mode === SliderChangeMode.End) {
                      this.updateAnswerAndBehavior(item.id, value)
                    }
                  })
              } else if (item.type === 'TEXT') {
                TextArea({ placeholder: '在此倾听你的声音...' })
                  .height(150)
                  .backgroundColor(Colors.CARD_BG)
                  // 🌟 文本框失去焦点时才触发更新，避免每敲一个字就算一次修改
                  .onBlur(() => {
                    // 注意：ArkTS TextArea 的 value 需要单独绑定状态或在 onChange 里获取
                    // 简易起见，此处假设通过控制器或组件绑定获取最新文本
                  })
                  .onChange((value: string) => {
                    this.updateAnswerAndBehavior(item.id, value)
                  })
              }
            }
            .width('100%')
            .height('100%')
            .padding(24)
            .alignItems(HorizontalAlign.Start)
          })
        }
        .index($$this.currentIndex)
        .loop(false)
        .indicator(false)
        .disableSwipe(true)
        // 🌟 核心埋点：监听题目切换，计算停留时长
        .onChange((newIndex: number) => {
          // 安全护栏 1：如果没有题目，直接中断
          if (!this.questions || this.questions.length === 0) return;

          const now = Date.now()
          const prevId = this.questions[this.lastIndex]?.id
          const currId = this.questions[newIndex]?.id

          // 安全护栏 2：必须确保 id 和 behaviors[id] 均已定义，才进行时长累加
          if (prevId && this.behaviors[prevId]) {
            this.behaviors[prevId].totalDuration += (now - this.behaviors[prevId].enterTime)
          }
          if (currId && this.behaviors[currId]) {
            this.behaviors[currId].enterTime = now
          }

          this.lastIndex = newIndex
          this.currentIndex = newIndex
        })
        .layoutWeight(1)

        // 底部操作区
        Row() {
          if (this.currentIndex > 0) {
            Button('上一题').backgroundColor(Colors.SURFACE).fontColor(Colors.TEXT_PRIMARY)
              .onClick(() => this.swiperController.showPrevious())
          }
          Blank()
          if (this.currentIndex === this.questions.length - 1) {
            Button('生成我的画像').backgroundColor(Colors.PRIMARY).fontColor(Colors.TEXT_ON_PRIMARY)
              .onClick(() => this.submitSurvey())
          } else if (this.questions[this.currentIndex]?.type !== 'SINGLE_CHOICE') {
            // 🌟 核心修复：上面这里的 type 前面一定要加上 ? 号！
            Button('下一题').backgroundColor(Colors.PRIMARY).fontColor(Colors.TEXT_ON_PRIMARY)
              .onClick(() => this.swiperController.showNext())
          }
        }
        .width('100%')
        .padding(24)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}