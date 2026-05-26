import http from '@ohos.net.http'
import { HistoryRecord } from '../../../common/utils/RiskAlgorithm'

// 🌟 修复 arkts-no-any-unknown：为大模型返回的 JSON 建立强类型接口
interface DeepSeekMessage {
  content: string
}

interface DeepSeekChoice {
  message: DeepSeekMessage
}

interface DeepSeekResponse {
  choices: DeepSeekChoice[]
}

export class AIPortraitService {
  private static readonly API_KEY = 'sk-903bff872b57412ba1f8826e6d4f41bf'
  private static readonly API_URL = 'https://api.deepseek.com/chat/completions'

  /**
   * 向大模型请求心理画像
   * @param scores 各个维度的平均分记录
   * @param fullQaHistory 本次问卷所有题目的详细问答文本历史
   */
  static async generatePortrait(scores: HistoryRecord[], fullQaHistory: string): Promise<string> {
    const scoreSummary = scores.map((s: HistoryRecord) => `【${s.tag}】维度得分: ${s.score.toFixed(1)}分 (满分5分)`).join('\n')

    const systemPrompt = `你现在是"心助小饼干"APP的首席AI心理辅导员。你的任务是根据用户本次半月报所有题目的具体回答内容和多维度得分，为TA生成一份极具针对性的细致【心理画像】。
规则要求：
1. 语气必须温暖、包容、充满同理心，避免机械化。
2. 结合TA的各个维度得分和具体的题目回答，指出TA最近在哪些具体的事情上（如某道题表现出的睡眠或学业困扰）遇到了坎坷。
3. 如果用户在主观题中表达了具体的心事，必须予以温柔、关切的回应和鼓励。
4. 结尾给出2条具体、实用的心理调节建议。
5. 字数控制在 300 字左右，分段清晰。`

    // 🌟 将全量问答数据倒给 AI
    const userPrompt = `【基础维度得分】\n${scoreSummary}\n\n【用户各题详细作答记录】\n${fullQaHistory}\n\n请根据上述真实完整的数据，为该同学生成专属心理画像。`

    const httpRequest = http.createHttp()
    try {
      const response = await httpRequest.request(
        AIPortraitService.API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${AIPortraitService.API_KEY}`
          },
          extraData: {
            model: "deepseek-chat",
            messages: [
              { role: "system", content: systemPrompt },
              { role: "user", content: userPrompt }
            ],
            temperature: 0.7,
            max_tokens: 600
          },
          readTimeout: 15000,
          connectTimeout: 15000
        }
      )

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as DeepSeekResponse
        return result.choices[0].message.content
      } else {
        return '抱歉，小饼干的 AI 大脑开小差了，没能生成画像。但请记住，无论分数如何，你都是最棒的！'
      }
    } catch (error) {
      return '网络信号似乎走丢了，请稍后再试。'
    } finally {
      httpRequest.destroy()
    }
  }
}