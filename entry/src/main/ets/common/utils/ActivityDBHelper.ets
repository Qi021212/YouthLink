import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MentalActivity } from '../../features/student/model/Activity'; // 请确保有这个基础接口

export class ActivityDBHelper {
  private static store: relationalStore.RdbStore | null = null;
  private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'MentalHealth.db', // 保持数据库文件统一
    securityLevel: relationalStore.SecurityLevel.S1
  };

  /**
   * 初始化并创建活动表
   */
  private static async getStore(context: common.Context): Promise<relationalStore.RdbStore> {
    if (ActivityDBHelper.store) {
      return ActivityDBHelper.store;
    }

    // 1. 先用局部变量拿着，千万别急着给全局静态变量 ActivityDBHelper.store 赋值！
    const rdbStore = await relationalStore.getRdbStore(context, ActivityDBHelper.STORE_CONFIG);

    // 2. 同步建立活动表
    const SQL_CREATE_TABLE = `
      CREATE TABLE IF NOT EXISTS MentalActivity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        type TEXT,
        targetState TEXT,
        currentQuota INTEGER,
        maxQuota INTEGER,
        time TEXT,
        location TEXT
      )
    `;
    await rdbStore.executeSql(SQL_CREATE_TABLE);

    // 3. 传入局部变量，确保把 6 条初始数据稳稳当当地砸进磁盘
    await ActivityDBHelper.seedMockActivities(rdbStore);

    // 4. 🌟 确保存储和写入万无一失了，再放开全局锁，供外界后续的查询使用
    ActivityDBHelper.store = rdbStore;
    return ActivityDBHelper.store;
  }

  /**
   * 植入初始活动数据
   */
  private static async seedMockActivities(store: relationalStore.RdbStore): Promise<void> {
    let predicates = new relationalStore.RdbPredicates('MentalActivity');
    let resultSet = await store.query(predicates);

    if (resultSet.rowCount === 0) {
      hilog.info(0x0000, 'YouthLink', '活动库为空，开始初始化活动池...');
      const mockPool: Array<relationalStore.ValuesBucket> = [
        { title: '正念冥想与深层呼吸减压沙龙', type: '沉浸沙龙', targetState: '焦虑', currentQuota: 5, maxQuota: 20, time: '2026-06-12 19:00', location: '心理咨询中心 201 室' },
        { title: '高效时间管理与期末抗压专家讲座', type: '心理讲座', targetState: '压力大', currentQuota: 48, maxQuota: 50, time: '2026-06-15 14:30', location: '教学楼大礼堂' },
        { title: '深层睡眠音疗与静心催眠体验课', type: '沉浸体验', targetState: '失眠', currentQuota: 15, maxQuota: 15, time: '2026-06-16 20:00', location: '素质拓展中心艺体室' },
        { title: '社交恐惧与人际交往心理打破工作坊', type: '互动表达', targetState: '社交', currentQuota: 2, maxQuota: 12, time: '2026-06-18 16:00', location: '团委活动室 105' },
        { title: '抑郁低落情绪宣泄与色彩绘画疗愈', type: '艺术疗愈', targetState: '抑郁', currentQuota: 6, maxQuota: 10, time: '2026-06-20 09:30', location: '美育基地工作室' },
        { title: '应对迷茫：大学生职业生涯心理沙盘', type: '沙盘游戏', targetState: '迷茫', currentQuota: 1, maxQuota: 6, time: '2026-06-22 15:00', location: '心理健康发展中心' },
        { title: '颂钵声音疗愈与芳香舒缓工作坊', type: '音疗体验', targetState: '焦虑', currentQuota: 0, maxQuota: 15, time: '2026-06-24 19:30', location: '素质拓展中心 302' },
        { title: '周五‘重力释放’击打与情绪宣泄局', type: '动态宣泄', targetState: '压力大', currentQuota: 12, maxQuota: 30, time: '2026-06-26 18:30', location: '体育馆负一楼拳击操房' },
        { title: '深夜树洞：失眠星人白噪音围炉夜话', type: '线上互助', targetState: '失眠', currentQuota: 8, maxQuota: 40, time: '2026-06-27 22:00', location: 'YouthLink 线上多功能厅' },
        { title: '‘撕掉标签’趣味心理不设防社交破冰派对', type: '桌游互动', targetState: '社交', currentQuota: 18, maxQuota: 20, time: '2026-06-29 14:00', location: '心理咨询中心大厅' },
        { title: '向阳而生：多肉植物种植与情绪绿化园艺课', type: '园艺疗愈', targetState: '抑郁', currentQuota: 2, maxQuota: 8, time: '2026-07-02 10:00', location: '学校后花园温室花房' },
        { title: '从零出发：破除自我怀疑的成长心态工作坊', type: '心理团辅', targetState: '迷茫', currentQuota: 4, maxQuota: 12, time: '2026-07-05 16:00', location: '行政楼 405 会议室' }
      ];

      store.beginTransaction();
      for (let i = 0; i < mockPool.length; i++) {
        await store.insert('MentalActivity', mockPool[i]);
      }
      store.commit();
    }
    resultSet.close();
  }

  /**
   * 🌟 智能契合推荐：根据传入的用户近期风险标签数组，联合查询匹配的活动
   */
  static async queryRecommended(context: common.Context, riskTags: string[]): Promise<MentalActivity[]> {
    if (!riskTags || riskTags.length === 0) {
      return [];
    }

    const store = await ActivityDBHelper.getStore(context);
    let predicates = new relationalStore.RdbPredicates('MentalActivity');

    // 显式循环重新推入，将包裹了 @State 代理的外壳彻底剥离，还原为 C++ NAPI 认识的绝对纯净数组
    const pureTags: Array<string> = [];
    riskTags.forEach((tag: string) => {
      if (tag) {
        pureTags.push(tag);
      }
    });

    // 带着完全脱壳后的纯净数组去查条件，绝对不会再触发 401 报错
    predicates.in('targetState', pureTags);

    let resultSet = await store.query(predicates);
    return ActivityDBHelper.convertResultSet(resultSet);
  }

  /**
   * 全量活动查询（支持模糊搜索筛选）
   */
  static async queryAll(context: common.Context, keyword: string = ''): Promise<MentalActivity[]> {
    const store = await ActivityDBHelper.getStore(context);
    let predicates = new relationalStore.RdbPredicates('MentalActivity');

    if (keyword.trim().length > 0) {
      predicates.like('title', `%${keyword}%`);
    }

    let resultSet = await store.query(predicates);
    return ActivityDBHelper.convertResultSet(resultSet);
  }

  /**
   * 报名操作（实时更新本地名额并落盘）
   */
  static async enroll(context: common.Context, id: number): Promise<boolean> {
    const store = await ActivityDBHelper.getStore(context);
    let predicates = new relationalStore.RdbPredicates('MentalActivity');
    predicates.equalTo('id', id);

    let resultSet = await store.query(predicates);
    let list = ActivityDBHelper.convertResultSet(resultSet);

    if (list.length === 0 || list[0].currentQuota >= list[0].maxQuota) {
      return false; // 活动不存在或已满员
    }

    let valueBucket: relationalStore.ValuesBucket = {
      currentQuota: list[0].currentQuota + 1
    };

    let updatePredicates = new relationalStore.RdbPredicates('MentalActivity');
    updatePredicates.equalTo('id', id);
    let affectedRows = await store.update(valueBucket, updatePredicates);

    return affectedRows > 0;
  }

  /**
   * 🌟 新增：取消报名操作（实时扣减本地名额并落盘）
   */
  static async cancelEnroll(context: common.Context, id: number): Promise<boolean> {
    const store = await ActivityDBHelper.getStore(context);
    let predicates = new relationalStore.RdbPredicates('MentalActivity');
    predicates.equalTo('id', id);

    let resultSet = await store.query(predicates);
    let list = ActivityDBHelper.convertResultSet(resultSet);

    // 容错：如果活动不存在，或者当前报名人数本来就是 0，就没法再减了
    if (list.length === 0 || list[0].currentQuota <= 0) {
      return false;
    }

    // 人数安全减 1
    let valueBucket: relationalStore.ValuesBucket = {
      currentQuota: list[0].currentQuota - 1
    };

    let updatePredicates = new relationalStore.RdbPredicates('MentalActivity');
    updatePredicates.equalTo('id', id);
    let affectedRows = await store.update(valueBucket, updatePredicates);

    return affectedRows > 0;
  }

  /**
   * 结果集安全转换，规避 ArkTS 严格检查
   */
  private static convertResultSet(resultSet: relationalStore.ResultSet): MentalActivity[] {
    let resultList: MentalActivity[] = [];
    if (resultSet.goToFirstRow()) {
      do {
        resultList.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          title: resultSet.getString(resultSet.getColumnIndex('title')),
          type: resultSet.getString(resultSet.getColumnIndex('type')),
          targetState: resultSet.getString(resultSet.getColumnIndex('targetState')),
          currentQuota: resultSet.getLong(resultSet.getColumnIndex('currentQuota')),
          maxQuota: resultSet.getLong(resultSet.getColumnIndex('maxQuota')),
          time: resultSet.getString(resultSet.getColumnIndex('time')),
          location: resultSet.getString(resultSet.getColumnIndex('location'))
        });
      } while (resultSet.goToNextRow());
    }
    resultSet.close();
    return resultList;
  }
}