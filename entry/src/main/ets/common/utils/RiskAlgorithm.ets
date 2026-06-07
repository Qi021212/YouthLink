import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// --- 原有接口模型保持不变 ---
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

export interface ReportSummary {
  timestamp: number;
  dateStr: string;
  topRisk?: string; // 可选：展示当时最严重的风险项标签
}

export class RiskAlgorithm {
  private static readonly RISK_THRESHOLD = 3.0

  // 数据库管理相关成员
  private static store: relationalStore.RdbStore | null = null;
  private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'MentalHealth.db', // 与 M9 其他模块使用同一个数据库文件，保持高内聚
    securityLevel: relationalStore.SecurityLevel.S1
  };

  // 判定词库保持不变
  private static readonly HIGH_RISK_WORDS: string[] = ['死', '绝望', '抑郁', '撑不下去', '失眠', '崩溃', '痛苦', '没意义']
  private static readonly MILD_RISK_WORDS: string[] = ['累', '烦', '焦虑', '迷茫', '孤单', '压力大', '心慌', '睡不着']
  private static readonly POSITIVE_WORDS: string[] = ['开心', '成就感', '顺利', '感谢', '期待', '放松', '好转', '希望']

  /**
   * 🌟 内部私有方法：初始化/获取 SQLite 数据库实例并建表
   */
  private static async getStore(context: common.Context): Promise<relationalStore.RdbStore> {
    if (RiskAlgorithm.store) {
      return RiskAlgorithm.store;
    }
    RiskAlgorithm.store = await relationalStore.getRdbStore(context, RiskAlgorithm.STORE_CONFIG);

    // 创建风险画像评估分数表 (增加 timestamp 区分批次)
    const SQL_CREATE_TABLE = `
      CREATE TABLE IF NOT EXISTS RiskScore (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag TEXT,
        score REAL,
        timestamp INTEGER
      )
    `;
    await RiskAlgorithm.store.executeSql(SQL_CREATE_TABLE);

    // 🌟 2. 新增：创建 AI 文本报告缓存表（时间戳作为唯一主键）
    const SQL_CREATE_AI_TABLE = `
      CREATE TABLE IF NOT EXISTS AiReport (
        timestamp INTEGER PRIMARY KEY,
        aiText TEXT
      )
    `;
    await RiskAlgorithm.store.executeSql(SQL_CREATE_AI_TABLE);

    return RiskAlgorithm.store;
  }

  /**
   * 🌟 新增静态方法：将 AI 文本报告落盘保存
   */
  static async saveAiReport(context: common.Context, timestamp: number, aiText: string): Promise<void> {
    try {
      const store = await RiskAlgorithm.getStore(context);
      let valueBucket: relationalStore.ValuesBucket = {
        timestamp: timestamp,
        aiText: aiText
      };
      // 使用 ConflictResolution.REPLACE 确保重复写入时自动覆盖
      await store.insert('AiReport', valueBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      hilog.info(0x0000, 'YouthLink', '==== 成功将 AI 文本归档至 SQLite ====');
    } catch (e) {
      hilog.error(0x0000, 'YouthLink', 'AI 文本归档失败: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 🌟 新增静态方法：从本地 SQLite 提取存好的 AI 文本
   */
  static async getAiReport(context: common.Context, timestamp: number): Promise<string> {
    try {
      const store = await RiskAlgorithm.getStore(context);
      let predicates = new relationalStore.RdbPredicates('AiReport');
      predicates.equalTo('timestamp', timestamp);

      let resultSet = await store.query(predicates);
      let cachedText = '';
      if (resultSet.goToFirstRow()) {
        cachedText = resultSet.getString(resultSet.getColumnIndex('aiText'));
      }
      resultSet.close();
      return cachedText;
    } catch (e) {
      hilog.error(0x0000, 'YouthLink', '读取本地历史 AI 报告失败: %{public}s', JSON.stringify(e));
      return '';
    }
  }

  /**
   * 🌟 新增：供外部页面（如雷达图结果页）直接调用，拉取最近一次的完整评分数组
   */
  static async getLatestScores(context: common.Context): Promise<HistoryRecord[]> {
    try {
      const store = await RiskAlgorithm.getStore(context);
      let predicates = new relationalStore.RdbPredicates('RiskScore');
      // 按时间戳倒序排列，优先查到最新的一次交卷批次
      predicates.orderByDesc('timestamp');

      let resultSet = await store.query(predicates);
      let latestScores: HistoryRecord[] = [];

      if (resultSet.goToFirstRow()) {
        // 拿到最新一条记录的时间戳作为“当前批次锚点”
        let latestTimestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));

        do {
          let currentTimestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
          // 一旦时间戳对不上了，说明已经读到上上一次的旧数据了，直接截断跳出
          if (currentTimestamp !== latestTimestamp) {
            break;
          }

          let tag = resultSet.getString(resultSet.getColumnIndex('tag'));
          let score = resultSet.getDouble(resultSet.getColumnIndex('score'));
          latestScores.push({ tag: tag, score: score });

        } while (resultSet.goToNextRow());
      }
      resultSet.close();
      return latestScores;
    } catch (e) {
      hilog.error(0x0000, 'YouthLink', 'SQLite读取最新画像分数失败: %{public}s', JSON.stringify(e));
      return [];
    }
  }

  /**
   * 修改：读取并判定近期的风险标签（用于自适应抽题分流匹配）
   */
  static async calculateRecentRisks(context: common.Context): Promise<string[]> {
    // 直接复用上面的多维查询方法
    const historyData = await RiskAlgorithm.getLatestScores(context);

    return historyData
      .filter((item: HistoryRecord) => item.score <= RiskAlgorithm.RISK_THRESHOLD)
      .map((item: HistoryRecord) => item.tag);
  }

  /**
   * 核心文本语义分析方法（保持不变）
   */
  private static analyzeTextContent(text: string): number {
    let riskScore = 3;
    for (let i = 0; i < RiskAlgorithm.HIGH_RISK_WORDS.length; i++) {
      if (text.includes(RiskAlgorithm.HIGH_RISK_WORDS[i])) return 1;
    }
    let mildCount = 0;
    for (let i = 0; i < RiskAlgorithm.MILD_RISK_WORDS.length; i++) {
      if (text.includes(RiskAlgorithm.MILD_RISK_WORDS[i])) mildCount++;
    }
    if (mildCount >= 2) return 2;
    else if (mildCount === 1) riskScore = 2.5;

    if (riskScore >= 3) {
      for (let i = 0; i < RiskAlgorithm.POSITIVE_WORDS.length; i++) {
        if (text.includes(RiskAlgorithm.POSITIVE_WORDS[i])) return 5;
      }
    }
    return riskScore;
  }

  /**
   * 修改：交卷时调用，处理数据量化，并批量存入 SQLite 数据库
   */
  static async evaluateAndSave(
    context: common.Context, // 🌟 引入上下文
    questions: RiskQuestion[],
    answers: Record<string, string | number>,
    behaviors: Record<string, RiskBehavior>
  ): Promise<number> {
    const tagSum: Record<string, number> = {};
    const tagCount: Record<string, number> = {};

    questions.forEach((q: RiskQuestion) => {
      const answer = answers[q.id];
      if (answer === undefined) return;

      let scoreValue: number = -1;

      if (q.type === 'SINGLE_CHOICE' && q.options) {
        const selectedOption = q.options.find((opt: RiskOption) => opt.id === answer);
        if (selectedOption) scoreValue = selectedOption.score;
      }
      else if (q.type === 'SLIDER') {
        scoreValue = ((answer as number) / 10) * 4 + 1;
      }
      else if (q.type === 'TEXT') {
        const textAnswer = answer as string;
        let contentScore = 3;
        if (textAnswer && textAnswer.trim().length > 0) {
          contentScore = RiskAlgorithm.analyzeTextContent(textAnswer);
        }

        const behavior = behaviors[q.id];
        let finalTextScore = contentScore;

        if (behavior) {
          if (behavior.totalDuration > 120000 && behavior.modifyCount >= 10) {
            finalTextScore = Math.min(contentScore, 2);
          }
          else if (contentScore <= 2.5 && (behavior.totalDuration > 120000 || behavior.modifyCount >= 8)) {
            finalTextScore = 1;
          }
        }
        scoreValue = finalTextScore;
      }

      if (scoreValue !== -1 && q.tags) {
        q.tags.forEach((tag: string) => {
          if (!tagSum[tag]) {
            tagSum[tag] = 0;
            tagCount[tag] = 0;
          }
          tagSum[tag] += scoreValue;
          tagCount[tag] += 1;
        });
      }
    });

    const newScores: HistoryRecord[] = [];
    const tags = Object.keys(tagSum);
    for (let i = 0; i < tags.length; i++) {
      const tag = tags[i];
      newScores.push({
        tag: tag,
        score: tagSum[tag] / tagCount[tag]
      });
    }

    const batchTimestamp = Date.now(); // 本批次的核心时间戳
    try {
      // 🌟 执行 SQLite 批量事务落盘
      const store = await RiskAlgorithm.getStore(context);
      const batchTimestamp = Date.now(); // 统一本批次的时间戳

      // 开启本地事务，确保高吞吐数据安全性
      store.beginTransaction();
      for (let i = 0; i < newScores.length; i++) {
        let valueBucket: relationalStore.ValuesBucket = {
          tag: newScores[i].tag,
          score: newScores[i].score,
          timestamp: batchTimestamp
        };
        await store.insert('RiskScore', valueBucket);
      }
      store.commit(); // 提交事务

      hilog.info(0x0000, 'YouthLink', '【Engine】多模态画像已成功持久化至本地 SQLite，批次: %{public}d', batchTimestamp);
      return batchTimestamp;
    } catch (e) {
      hilog.error(0x0000, 'YouthLink', '【Engine】画像数据写入 SQLite 失败: %{public}s', JSON.stringify(e));
      return batchTimestamp;
    }
  }

  /**
   * 🌟 历史报告功能：获取去重后的历史交卷批次列表
   */
  static async getHistoryList(context: common.Context): Promise<ReportSummary[]> {
    try {
      const store = await RiskAlgorithm.getStore(context);
      let predicates = new relationalStore.RdbPredicates('RiskScore');
      // 按时间戳分组去重，并按时间倒序排列（最近的报告在最上面）
      predicates.groupBy(['timestamp']).orderByDesc('timestamp');

      let resultSet = await store.query(predicates);
      let list: ReportSummary[] = [];

      if (resultSet.goToFirstRow()) {
        do {
          let ts = resultSet.getLong(resultSet.getColumnIndex('timestamp'));

          // 简易时间格式化：将时间戳转为 2026-05-28 16:50 格式
          const date = new Date(ts);
          const dateStr = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;

          list.push({
            timestamp: ts,
            dateStr: dateStr
          });
        } while (resultSet.goToNextRow());
      }
      resultSet.close();
      return list;
    } catch (e) {
      console.error('获取历史报告列表失败:', JSON.stringify(e));
      return [];
    }
  }

  /**
   * 🌟 历史报告功能：根据特定的时间戳拉取那一批次的多维分数
   */
  static async getScoresByTimestamp(context: common.Context, timestamp: number): Promise<HistoryRecord[]> {
    try {
      const store = await RiskAlgorithm.getStore(context);
      let predicates = new relationalStore.RdbPredicates('RiskScore');
      predicates.equalTo('timestamp', timestamp); // 精准匹配时间戳

      let resultSet = await store.query(predicates);
      let records: HistoryRecord[] = [];

      if (resultSet.goToFirstRow()) {
        do {
          let tag = resultSet.getString(resultSet.getColumnIndex('tag'));
          let score = resultSet.getDouble(resultSet.getColumnIndex('score'));
          records.push({ tag: tag, score: score });
        } while (resultSet.goToNextRow());
      }
      resultSet.close();
      return records;
    } catch (e) {
      console.error('获取指定批次分数失败:', JSON.stringify(e));
      return [];
    }
  }
}
