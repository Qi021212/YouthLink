export interface MentalActivity {
  id: number          // 活动唯一标识（SQLite 自增主键）
  title: string       // 活动标题（如：正念冥想沙龙）
  type: string        // 活动类型（如：沉浸体验、心理讲座）
  targetState: string // 调理针对的心理状态（如：焦虑、失眠，用于算法匹配）
  currentQuota: number // 当前已报名人数
  maxQuota: number    // 该活动的最大名额上限
  time: string
  location: string
}