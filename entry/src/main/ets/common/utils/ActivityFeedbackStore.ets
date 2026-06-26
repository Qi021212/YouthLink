import { getString, putString } from './StorageUtil'

// 单个活动的评分聚合
export interface ActivityFeedback {
  count: number       // 评分人次
  totalScore: number  // 累计分值（用于算平均）
}

// 学生端评分与学校端聚合共用的同一份存储 key
const ACTIVITY_FEEDBACK_KEY: string = 'shared_activity_feedback'

/**
 * 活动评分的共享存储。
 * - 学生端：参加活动后提交评分（submit）
 * - 学校端：聚合展示平均满意度与推荐率（getAverage / loadAll）
 * 两端读写同一个 preferences key，实现跨端联动。
 */
export class ActivityFeedbackStore {
  // 学生提交一条评分（1-5）
  static async submit(activityId: string, score: number): Promise<void> {
    const map: Record<string, ActivityFeedback> = await ActivityFeedbackStore.loadAll()
    let fb: ActivityFeedback | undefined = map[activityId]
    if (fb === undefined) {
      fb = { count: 0, totalScore: 0 }
    }
    fb.count = fb.count + 1
    fb.totalScore = fb.totalScore + score
    map[activityId] = fb
    await putString(ACTIVITY_FEEDBACK_KEY, JSON.stringify(map))
  }

  // 读取全部活动的评分聚合
  static async loadAll(): Promise<Record<string, ActivityFeedback>> {
    const json: string = await getString(ACTIVITY_FEEDBACK_KEY, '{}')
    try {
      return JSON.parse(json) as Record<string, ActivityFeedback>
    } catch (e) {
      return {}
    }
  }

  // 某个活动的平均分（无评分返回 0）
  static getAverage(map: Record<string, ActivityFeedback>, activityId: string): number {
    const fb: ActivityFeedback | undefined = map[activityId]
    if (fb !== undefined && fb.count > 0) {
      return fb.totalScore / fb.count
    }
    return 0
  }

  // 某个活动的评分人次
  static getCount(map: Record<string, ActivityFeedback>, activityId: string): number {
    const fb: ActivityFeedback | undefined = map[activityId]
    if (fb !== undefined) {
      return fb.count
    }
    return 0
  }
}
