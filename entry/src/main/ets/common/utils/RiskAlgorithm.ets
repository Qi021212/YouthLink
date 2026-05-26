import { getString, putString } from './StorageUtil'

export interface HistoryRecord {
  tag: string
  score: number
}

export interface RiskOption {
  id: string
  text: string
  score: number
}

export interface RiskQuestion {
  id: string
  type: string
  title: string
  tags?: string[]
  options?: RiskOption[]
}

export interface RiskBehavior {
  enterTime: number
  totalDuration: number
  modifyCount: number
}

export class RiskAlgorithm {
  private static readonly RISK_THRESHOLD = 3.0

  // 🌟 算法升级 1：建立本地情感词汇判定库
  private static readonly HIGH_RISK_WORDS: string[] = ['死', '绝望', '抑郁', '撑不下去', '失眠', '崩溃', '痛苦', '没意义']
  private static readonly MILD_RISK_WORDS: string[] = ['累', '烦', '焦虑', '迷茫', '孤单', '压力大', '心慌', '睡不着']
  private static readonly POSITIVE_WORDS: string[] = ['开心', '成就感', '顺利', '感谢', '期待', '放松', '好转', '希望']

  /**
   * 读取并判定近期的风险标签
   */
  static async calculateRecentRisks(): Promise<string[]> {
    const historyJson = await getString('LAST_SEMI_MONTHLY_SCORES', '[]')
    let historyData: HistoryRecord[] = []

    try {
      historyData = JSON.parse(historyJson) as HistoryRecord[]
    } catch (e) {
      console.error('历史记录解析失败:', e)
      return []
    }

    return historyData
      .filter((item: HistoryRecord) => item.score <= RiskAlgorithm.RISK_THRESHOLD)
      .map((item: HistoryRecord) => item.tag)
  }

  /**
   * 🌟 算法升级 2：核心文本语义分析方法
   */
  private static analyzeTextContent(text: string): number {
    let riskScore = 3 // 默认中性 3 分

    // 1. 优先匹配高危词汇（一票否决，极度危险）
    for (let i = 0; i < RiskAlgorithm.HIGH_RISK_WORDS.length; i++) {
      if (text.includes(RiskAlgorithm.HIGH_RISK_WORDS[i])) {
        return 1 // 直接判定为 1 分（最高预警等级）
      }
    }

    // 2. 匹配轻度风险词汇
    let mildCount = 0
    for (let i = 0; i < RiskAlgorithm.MILD_RISK_WORDS.length; i++) {
      if (text.includes(RiskAlgorithm.MILD_RISK_WORDS[i])) {
        mildCount++
      }
    }

    if (mildCount >= 2) {
      return 2 // 包含多个轻度负面词，判定为 2 分
    } else if (mildCount === 1) {
      riskScore = 2.5 // 单个轻度负面词，轻微降分
    }

    // 3. 匹配积极词汇（如果没有高危词，且存在积极词，可以加分）
    if (riskScore >= 3) {
      for (let i = 0; i < RiskAlgorithm.POSITIVE_WORDS.length; i++) {
        if (text.includes(RiskAlgorithm.POSITIVE_WORDS[i])) {
          return 5 // 充满正能量，判定为 5 分
        }
      }
    }

    return riskScore // 如果没有任何匹配，返回默认分数或单轻度词分数
  }

  /**
   * 交卷时调用：处理本次问卷数据，量化分值并自动保存
   */
  static async evaluateAndSave(
    questions: RiskQuestion[],
    answers: Record<string, string | number>,
    behaviors: Record<string, RiskBehavior>
  ): Promise<void> {
    const tagSum: Record<string, number> = {}
    const tagCount: Record<string, number> = {}

    questions.forEach((q: RiskQuestion) => {
      const answer = answers[q.id]
      if (answer === undefined) return

      let scoreValue: number = -1

      if (q.type === 'SINGLE_CHOICE' && q.options) {
        const selectedOption = q.options.find((opt: RiskOption) => opt.id === answer)
        if (selectedOption) {
          scoreValue = selectedOption.score
        }
      }
      else if (q.type === 'SLIDER') {
        scoreValue = ((answer as number) / 10) * 4 + 1
      }
      else if (q.type === 'TEXT') {
        // 🌟 算法升级 3：多模态交叉判定（语义 + 行为）
        const textAnswer = answer as string
        let contentScore = 3

        // 解析写了什么（语义）
        if (textAnswer && textAnswer.trim().length > 0) {
          contentScore = RiskAlgorithm.analyzeTextContent(textAnswer)
        }

        // 解析是怎么写的（行为）
        const behavior = behaviors[q.id]
        let finalTextScore = contentScore

        if (behavior) {
          // 如果用户写下了积极的内容（如"开心"），但行为上却极度异常（停留>2分钟 且 修改>10次）
          // 算法判定其可能在进行“强颜欢笑”或“反复犹豫是否倾诉”，此时进行惩罚降分
          if (behavior.totalDuration > 120000 && behavior.modifyCount >= 10) {
            finalTextScore = Math.min(contentScore, 2)
          }
          // 反之，如果触发了轻度负面词（得2分），但停留极长、狂删改，说明陷入重度内耗，直接降为1分
          else if (contentScore <= 2.5 && (behavior.totalDuration > 120000 || behavior.modifyCount >= 8)) {
            finalTextScore = 1
          }
        }

        scoreValue = finalTextScore
      }

      if (scoreValue !== -1 && q.tags) {
        q.tags.forEach((tag: string) => {
          if (!tagSum[tag]) {
            tagSum[tag] = 0
            tagCount[tag] = 0
          }
          tagSum[tag] += scoreValue
          tagCount[tag] += 1
        })
      }
    })

    const newScores: HistoryRecord[] = []
    const tags = Object.keys(tagSum)
    for (let i = 0; i < tags.length; i++) {
      const tag = tags[i]
      newScores.push({
        tag: tag,
        score: tagSum[tag] / tagCount[tag]
      })
    }

    try {
      await putString('LAST_SEMI_MONTHLY_SCORES', JSON.stringify(newScores))
      console.info('【Engine】多模态画像计算完成并存入本地:', JSON.stringify(newScores))
    } catch (e) {
      console.error('【Engine】画像数据保存失败:', e)
    }
  }
}