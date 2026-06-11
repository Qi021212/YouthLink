// features/student/model/MoodRecord.ets

/**
 * 情绪标签类型
 */
export enum MoodTag {
  HAPPY = '开心',
  NORMAL = '一般',
  CONFUSED = '迷茫',
  DOWN = '低落',
  SAD = '悲伤'
}

/**
 * 情绪对应的分值（用于趋势图）
 */
export const MoodScoreMap: Record<MoodTag, number> = {
  [MoodTag.HAPPY]: 100,
  [MoodTag.NORMAL]: 70,
  [MoodTag.CONFUSED]: 50,
  [MoodTag.DOWN]: 40,
  [MoodTag.SAD]: 20
};

/**
 * 情绪记录实体
 */
@Observed
export class MoodRecord {
  id: string = '';
  moodTag: MoodTag = MoodTag.NORMAL;
  content: string = '';
  score: number = 70;
  timestamp: number = 0;

  constructor(moodTag: MoodTag, content: string, timestamp: number) {
    this.id = `${timestamp}_${Math.random().toString(36).substring(2, 8)}`;
    this.moodTag = moodTag;
    this.content = content;
    this.score = MoodScoreMap[moodTag];
    this.timestamp = timestamp;
  }
}


export class StoredMoodRecord {
  id: string = '';
  moodTag: MoodTag = MoodTag.NORMAL;
  content: string = '';
  score: number = 70;
  timestamp: number = 0;

  constructor(record: MoodRecord) {
    this.id = record.id;
    this.moodTag = record.moodTag;
    this.content = record.content;
    this.score = record.score;
    this.timestamp = record.timestamp;
  }

  // 从 JSON 对象创建（用于反序列化）
  static fromJson(json: Record<string, Object>): StoredMoodRecord {
    const stored = new StoredMoodRecord(new MoodRecord(MoodTag.NORMAL, '', 0));
    stored.id = json.id as string;
    stored.moodTag = json.moodTag as MoodTag;
    stored.content = json.content as string;
    stored.score = json.score as number;
    stored.timestamp = json.timestamp as number;
    return stored;
  }

  // 转换为 MoodRecord
  toMoodRecord(): MoodRecord {
    const record = new MoodRecord(this.moodTag, this.content, this.timestamp);
    record.id = this.id;
    record.score = this.score;
    return record;
  }
}

/**
 * 周趋势数据点（用于图表）
 */
export class WeeklyTrendPoint {
  date: string = '';
  fullDate: number = 0;
  score: number = 0;
  moodTag?: MoodTag;

  constructor(date: string, fullDate: number, score: number, moodTag?: MoodTag) {
    this.date = date;
    this.fullDate = fullDate;
    this.score = score;
    this.moodTag = moodTag;
  }
}