import { relationalStore } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { CaseData } from '../../features/counselor/model/CaseData';
import { ReportData } from '../../common/model/ReportModel';

const DB_NAME = 'YouthLink.db'
const TABLE_STUDENTS = 'students'
const TABLE_COUNSELORS = 'counselors'
const TABLE_SCHOOL_CENTER = 'school_center'

export interface StudentRow {
  id: number
  uid: string
  name: string
  passwordHash: string
  createdAt: string
}

export interface StaffRow {
  id: number
  uid: string
  name: string
  passwordHash: string
  createdAt: string
}

// 个案数据模型
export interface CaseRow {
  id: string;
  studentName: string;
  parentPhone: string;
  deadline: number;
  status: string;
  createdAt: number;
}

// 沟通记录模型
export interface RecordRow {
  id: string;
  caseId: string;
  content: string;
  type: string;
  timestamp: number;
}

export interface HotlineCallRow {
  callId: string;
  callerName: string;
  callerStudentId: string;
  phoneNumber: string;
  startTime: string;
  duration: number;
  status: number;
  riskLevel: number;
  tags: string[];
  aiSummary: string;
}

export interface WorkOrderRow {
  orderId: string;
  relatedCallId: string;
  studentName: string;
  studentId: string;
  type: string;
  description: string;
  status: number;
  assignedTo: string;
  createdAt: string;
  updatedAt: string;
  riskLevel: number;
}

function stringToUint8Array(str: string): Uint8Array {
  const bytes: number[] = []
  for (let i = 0; i < str.length; i++) {
    const code = str.charCodeAt(i)
    if (code <= 0x7F) {
      bytes.push(code)
    } else if (code <= 0x7FF) {
      bytes.push(0xC0 | (code >> 6), 0x80 | (code & 0x3F))
    } else if (code <= 0xFFFF) {
      bytes.push(0xE0 | (code >> 12), 0x80 | ((code >> 6) & 0x3F), 0x80 | (code & 0x3F))
    }
  }
  return new Uint8Array(bytes)
}

function uint8ArrayToHex(data: Uint8Array): string {
  const hexChars = '0123456789abcdef'
  let result = ''
  for (let i = 0; i < data.length; i++) {
    result += hexChars.charAt((data[i] >>> 4) & 0x0F)
    result += hexChars.charAt(data[i] & 0x0F)
  }
  return result
}

export function hashPassword(password: string): string {
  const salt = 'YouthLink_Salt_2024'
  const combined = salt + password + salt.split('').reverse().join('')
  const data = stringToUint8Array(combined)

  let h1 = 0x67452301
  let h2 = 0xEFCDAB89
  let h3 = 0x98BADCFE
  let h4 = 0x10325476
  let h5 = 0xC3D2E1F0

  for (let i = 0; i < data.length; i++) {
    const b = data[i]
    const k = b * (i + 1) * 0x5BD1E995
    h1 = ((h1 ^ k) * 0x5BD1E995) >>> 0
    h2 = ((h2 ^ ((k >>> 16) & 0xFFFF)) * 0x85EBCA77) >>> 0
    h3 = ((h3 ^ ((k >>> 8) & 0xFF)) * 0xC2B2AE35) >>> 0
    h4 = ((h4 ^ k) * 0x27D4EB2F) >>> 0
    h5 = ((h5 ^ (b * 0x9E3779B1)) * 0x165667B1) >>> 0
  }

  const totalLen = data.length * 8
  h1 = (h1 ^ totalLen) >>> 0
  h2 = (h2 ^ (totalLen >>> 8)) >>> 0
  h3 = (h3 ^ ((totalLen >>> 16) & 0xFF)) >>> 0
  h4 = (h4 ^ h2) >>> 0
  h5 = (h5 ^ h1) >>> 0

  const result = new Uint8Array(20)
  const values = [h1, h2, h3, h4, h5]
  for (let i = 0; i < 5; i++) {
    const v = values[i]
    result[i * 4] = (v >>> 24) & 0xFF
    result[i * 4 + 1] = (v >>> 16) & 0xFF
    result[i * 4 + 2] = (v >>> 8) & 0xFF
    result[i * 4 + 3] = v & 0xFF
  }

  return uint8ArrayToHex(result)
}

export class DatabaseHelper {
  private static instance: DatabaseHelper
  private rdbStore: relationalStore.RdbStore | null = null
  private initialized: boolean = false

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized && this.rdbStore !== null) {
      return
    }

    this.initialized = false
    this.rdbStore = null

    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }

    this.rdbStore = await relationalStore.getRdbStore(context, config)

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_STUDENTS} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    `)

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_COUNSELORS} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    `)

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_SCHOOL_CENTER} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    `)

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS cases (
        id TEXT PRIMARY KEY,
        student_name TEXT NOT NULL,
        parent_phone TEXT NOT NULL,
        deadline INTEGER NOT NULL,
        status TEXT DEFAULT '进行中',
        created_at INTEGER
      )
    `);

    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS records (
        id TEXT PRIMARY KEY,
        case_id TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY(case_id) REFERENCES cases(id)
      )
    `);

    // 新增：创建半月报表
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS reports (
        id TEXT PRIMARY KEY,
        student_name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        submit_time INTEGER NOT NULL,
        ai_score INTEGER NOT NULL,
        ai_counselor_summary TEXT NOT NULL,
        ai_student_portrait TEXT NOT NULL,
        risk_level TEXT NOT NULL,
        status TEXT NOT NULL,
        qa_history TEXT NOT NULL
      )
    `);

    // 新增：学校端热线记录
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS hotline_calls (
        call_id TEXT PRIMARY KEY,
        caller_name TEXT NOT NULL,
        caller_student_id TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        start_time TEXT NOT NULL,
        duration INTEGER NOT NULL,
        status INTEGER NOT NULL,
        risk_level INTEGER NOT NULL,
        tags TEXT NOT NULL,
        ai_summary TEXT NOT NULL
      )
    `);

    // 新增：学校端工单
    await this.rdbStore.executeSql(`
      CREATE TABLE IF NOT EXISTS work_orders (
        order_id TEXT PRIMARY KEY,
        related_call_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        student_id TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        status INTEGER NOT NULL,
        assigned_to TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        risk_level INTEGER NOT NULL
      )
    `);

    this.initialized = true
  }

  async ensureInit(context: common.UIAbilityContext): Promise<boolean> {
    if (this.initialized && this.rdbStore !== null) {
      return true
    }
    try {
      await this.init(context)
      return this.initialized && this.rdbStore !== null
    } catch (err) {
      return false
    }
  }

  isReady(): boolean {
    return this.initialized && this.rdbStore !== null
  }

  async registerStudent(uid: string, name: string, password: string): Promise<boolean> {
    if (!this.rdbStore) {
      return false
    }

    const exists = await this.findByUid(uid)
    if (exists !== null) {
      return false
    }

    const passwordHash = hashPassword(password)
    const valueBucket: relationalStore.ValuesBucket = {
      'uid': uid,
      'name': name,
      'password_hash': passwordHash
    }

    await this.rdbStore.insert(TABLE_STUDENTS, valueBucket)
    return true
  }

  async findByUid(uid: string): Promise<StudentRow | null> {
    if (!this.rdbStore) {
      return null
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_STUDENTS)
    predicates.equalTo('uid', uid)

    const resultSet = await this.rdbStore.query(predicates)

    if (resultSet.goToFirstRow()) {
      const row: StudentRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        uid: resultSet.getString(resultSet.getColumnIndex('uid')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        passwordHash: resultSet.getString(resultSet.getColumnIndex('password_hash')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at'))
      }
      resultSet.close()
      return row
    }

    resultSet.close()
    return null
  }

  async validateLogin(uid: string, password: string): Promise<StudentRow | null> {
    if (!this.rdbStore) {
      return null
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_STUDENTS)
    predicates.equalTo('uid', uid)
    predicates.equalTo('password_hash', hashPassword(password))

    const resultSet = await this.rdbStore.query(predicates)

    if (resultSet.goToFirstRow()) {
      const row: StudentRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        uid: resultSet.getString(resultSet.getColumnIndex('uid')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        passwordHash: resultSet.getString(resultSet.getColumnIndex('password_hash')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at'))
      }
      resultSet.close()
      return row
    }

    resultSet.close()
    return null
  }

  async isUidExists(uid: string): Promise<boolean> {
    const row = await this.findByUid(uid)
    return row !== null
  }

  async getAllStudents(): Promise<StudentRow[]> {
    const list: StudentRow[] = []
    if (!this.rdbStore) {
      return list
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_STUDENTS)
    predicates.orderByAsc('id')
    const resultSet = await this.rdbStore.query(predicates)

    while (resultSet.goToNextRow()) {
      const row: StudentRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        uid: resultSet.getString(resultSet.getColumnIndex('uid')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        passwordHash: resultSet.getString(resultSet.getColumnIndex('password_hash')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at'))
      }
      list.push(row)
    }
    resultSet.close()
    return list
  }

  async getStudentCount(): Promise<number> {
    if (!this.rdbStore) {
      return 0
    }
    const sql = `SELECT COUNT(*) AS cnt FROM ${TABLE_STUDENTS}`
    const resultSet = await this.rdbStore.querySql(sql)
    let count = 0
    if (resultSet.goToFirstRow()) {
      count = resultSet.getLong(resultSet.getColumnIndex('cnt'))
    }
    resultSet.close()
    return count
  }

  getStore(): relationalStore.RdbStore | null {
    return this.rdbStore
  }

  // ========== 辅导员 (counselors) ==========

  async registerStaff(tableName: string, uid: string, name: string, password: string): Promise<boolean> {
    if (!this.rdbStore) {
      return false
    }

    const existing = await this.findStaffByUid(tableName, uid)
    if (existing !== null) {
      return false
    }

    const passwordHash = hashPassword(password)
    const valueBucket: relationalStore.ValuesBucket = {
      'uid': uid,
      'name': name,
      'password_hash': passwordHash
    }

    await this.rdbStore.insert(tableName, valueBucket)
    return true
  }

  async findStaffByUid(tableName: string, uid: string): Promise<StaffRow | null> {
    if (!this.rdbStore) {
      return null
    }

    const predicates = new relationalStore.RdbPredicates(tableName)
    predicates.equalTo('uid', uid)

    const resultSet = await this.rdbStore.query(predicates)
    if (resultSet.goToFirstRow()) {
      const row: StaffRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        uid: resultSet.getString(resultSet.getColumnIndex('uid')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        passwordHash: resultSet.getString(resultSet.getColumnIndex('password_hash')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at'))
      }
      resultSet.close()
      return row
    }
    resultSet.close()
    return null
  }

  async validateStaffLogin(tableName: string, uid: string, password: string): Promise<StaffRow | null> {
    if (!this.rdbStore) {
      return null
    }

    const predicates = new relationalStore.RdbPredicates(tableName)
    predicates.equalTo('uid', uid)
    predicates.equalTo('password_hash', hashPassword(password))

    const resultSet = await this.rdbStore.query(predicates)
    if (resultSet.goToFirstRow()) {
      const row: StaffRow = {
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        uid: resultSet.getString(resultSet.getColumnIndex('uid')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        passwordHash: resultSet.getString(resultSet.getColumnIndex('password_hash')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at'))
      }
      resultSet.close()
      return row
    }
    resultSet.close()
    return null
  }

  /**
   * 真实更新辅导员/员工密码
   * @param tableName 表名（如 counselors 或 school_center）
   * @param uid 唯一工号
   * @param newPassword 新密码（会自动通过 hashPassword 加密）
   */
  async updateStaffPassword(tableName: string, uid: string, newPassword: string): Promise<boolean> {
    if (!this.rdbStore) {
      console.error('Database is not initialized');
      return false;
    }

    try {
      const newHash = hashPassword(newPassword);

      // 🌟 核心：使用原始 SQL 语句执行更新
      // 使用 ? 占位符防止 SQL 注入
      const sql = `UPDATE ${tableName} SET password_hash = ? WHERE uid = ?`;

      // 打印调试信息：看看你到底在往哪个表里更新哪个 UID
      console.info(`[DEBUG] Executing SQL: ${sql} with params: [${newHash}, ${uid}]`);

      await this.rdbStore.executeSql(sql, [newHash, uid]);

      // 验证：更新完后，通过 findStaffByUid 检查密码哈希是否真的变了
      const updatedRow = await this.findStaffByUid(tableName, uid);
      if (updatedRow && updatedRow.passwordHash === newHash) {
        console.info(`[SUCCESS] Password updated in DB for UID: ${uid}`);
        return true;
      } else {
        console.error(`[FAIL] Verification failed after update.`);
        return false;
      }
    } catch (err) {
      console.error('Database update failed:', JSON.stringify(err));
      return false;
    }
  }

  // 新增个案
  async addCase(row: CaseRow): Promise<void> {
    await this.rdbStore!.insert('cases', {
      'id': row.id,
      'student_name': row.studentName,
      'parent_phone': row.parentPhone,
      'deadline': row.deadline,
      'status': row.status,
      'created_at': row.createdAt
    });
  }

  // 获取所有个案
  async getAllCases(): Promise<CaseData[]> {
    if (!this.rdbStore) return [];

    const resultSet = await this.rdbStore.querySql('SELECT * FROM cases ORDER BY created_at DESC');
    const result: CaseData[] = [];
    while (resultSet.goToNextRow()) {
      let caseItem = new CaseData(); // 实例化类
      caseItem.id = resultSet.getString(resultSet.getColumnIndex('id'));
      caseItem.studentName = resultSet.getString(resultSet.getColumnIndex('student_name'));
      caseItem.parentPhone = resultSet.getString(resultSet.getColumnIndex('parent_phone'));
      caseItem.deadline = resultSet.getLong(resultSet.getColumnIndex('deadline'));
      caseItem.status = resultSet.getString(resultSet.getColumnIndex('status'));
      caseItem.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      result.push(caseItem);
    }
    resultSet.close();
    return result;
  }

  // 添加沟通记录
  async addRecord(row: RecordRow): Promise<void> {
    await this.rdbStore!.insert('records', {
      'id': row.id,
      'case_id': row.caseId,
      'content': row.content,
      'type': row.type,
      'timestamp': row.timestamp
    });
  }

  // 根据个案ID获取记录（用于时间线）
  async getRecordsByCaseId(caseId: string): Promise<RecordRow[]> {
    const predicates = new relationalStore.RdbPredicates('records');
    predicates.equalTo('case_id', caseId).orderByAsc('timestamp');
    const resultSet = await this.rdbStore!.query(predicates);
    const result: RecordRow[] = [];
    while (resultSet.goToNextRow()) {
      result.push({
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        caseId: resultSet.getString(resultSet.getColumnIndex('case_id')),
        content: resultSet.getString(resultSet.getColumnIndex('content')),
        type: resultSet.getString(resultSet.getColumnIndex('type')),
        timestamp: resultSet.getLong(resultSet.getColumnIndex('timestamp'))
      });
    }
    resultSet.close();
    return result;
  }

  // 确保在 DatabaseHelper.ts 中有这个方法
  async getCaseById(id: string): Promise<CaseData | null> {
    const predicates = new relationalStore.RdbPredicates('cases');
    predicates.equalTo('id', id);
    const resultSet = await this.rdbStore!.query(predicates);
    if (resultSet.goToFirstRow()) {
      // 此处请按需填充 resultSet 字段映射逻辑
      let item = new CaseData();
      item.id = resultSet.getString(resultSet.getColumnIndex('id'));
      // ... 其他字段赋值
      resultSet.close();
      return item;
    }
    resultSet.close();
    return null;
  }

  // ================= 🌟 半月报 (Reports) 核心方法 =================

  // 1. 学生端调用：新增半月报
  async addReport(report: ReportData): Promise<void> {
    if (!this.rdbStore) return;

    let bucket: relationalStore.ValuesBucket = {
      'id': report.id,
      'student_name': report.studentName,
      'class_name': report.className,
      'submit_time': report.submitTime,
      'ai_score': report.aiScore,
      'ai_counselor_summary': report.aiCounselorSummary, // 🌟 存入辅导员版
      'ai_student_portrait': report.aiStudentPortrait,   // 🌟 存入学生版
      'risk_level': report.riskLevel,
      'status': report.status,
      'qa_history': report.qaHistory
    };

    await this.rdbStore.insert('reports', bucket);
  }

  // 2. 辅导员端调用：拉取所有半月报
  async getAllReports(): Promise<ReportData[]> {
    if (!this.rdbStore) return [];

    // 默认按提交时间倒序（最新的在最上面）
    const resultSet = await this.rdbStore.querySql('SELECT * FROM reports ORDER BY submit_time DESC');
    const result: ReportData[] = [];

    while (resultSet.goToNextRow()) {
      let r = new ReportData(); // 严防 structural typing 报错
      r.id = resultSet.getString(resultSet.getColumnIndex('id'));
      r.studentName = resultSet.getString(resultSet.getColumnIndex('student_name'));
      r.className = resultSet.getString(resultSet.getColumnIndex('class_name'));
      r.submitTime = resultSet.getLong(resultSet.getColumnIndex('submit_time'));
      r.aiScore = resultSet.getLong(resultSet.getColumnIndex('ai_score'));
      r.aiCounselorSummary = resultSet.getString(resultSet.getColumnIndex('ai_counselor_summary')); // 🌟 取出
      r.aiStudentPortrait = resultSet.getString(resultSet.getColumnIndex('ai_student_portrait'));   // 🌟 取出
      r.riskLevel = resultSet.getString(resultSet.getColumnIndex('risk_level'));
      r.status = resultSet.getString(resultSet.getColumnIndex('status'));
      r.qaHistory = resultSet.getString(resultSet.getColumnIndex('qa_history'));
      result.push(r);
    }
    resultSet.close();
    return result;
  }

  // 3. 辅导员端调用：更新报告审核状态
  async updateReportStatus(id: string, newStatus: string): Promise<boolean> {
    if (!this.rdbStore) return false;
    try {
      const sql = `UPDATE reports SET status = ? WHERE id = ?`;
      await this.rdbStore.executeSql(sql, [newStatus, id]);
      return true;
    } catch (err) {
      console.error('更新报告状态失败:', JSON.stringify(err));
      return false;
    }
  }

  // ================= 🌟 学校端 (Hotline & WorkOrder) 方法 =================

  async addHotlineCall(callId: string, callerName: string, callerStudentId: string, phoneNumber: string, startTime: string, duration: number, status: number, riskLevel: number, tags: string[], aiSummary: string): Promise<void> {
    if (!this.rdbStore) return;
    let bucket: relationalStore.ValuesBucket = {
      'call_id': callId,
      'caller_name': callerName,
      'caller_student_id': callerStudentId,
      'phone_number': phoneNumber,
      'start_time': startTime,
      'duration': duration,
      'status': status,
      'risk_level': riskLevel,
      'tags': JSON.stringify(tags),
      'ai_summary': aiSummary
    };
    try {
      await this.rdbStore.insert('hotline_calls', bucket);
    } catch (e) {
      console.error('Failed to add hotline call', JSON.stringify(e));
    }
  }

  async updateHotlineCallStatus(callId: string, status: number): Promise<void> {
    if (!this.rdbStore) return;
    const sql = `UPDATE hotline_calls SET status = ? WHERE call_id = ?`;
    await this.rdbStore.executeSql(sql, [status, callId]);
  }

  async getActiveHotlineCalls(): Promise<HotlineCallRow[]> {
    if (!this.rdbStore) return [];
    // 假设 0 是 ONGOING
    const resultSet = await this.rdbStore.querySql('SELECT * FROM hotline_calls WHERE status = 0 ORDER BY start_time DESC');
    const result: HotlineCallRow[] = [];
    while (resultSet.goToNextRow()) {
      const row: HotlineCallRow = {
        callId: resultSet.getString(resultSet.getColumnIndex('call_id')),
        callerName: resultSet.getString(resultSet.getColumnIndex('caller_name')),
        callerStudentId: resultSet.getString(resultSet.getColumnIndex('caller_student_id')),
        phoneNumber: resultSet.getString(resultSet.getColumnIndex('phone_number')),
        startTime: resultSet.getString(resultSet.getColumnIndex('start_time')),
        duration: resultSet.getLong(resultSet.getColumnIndex('duration')),
        status: resultSet.getLong(resultSet.getColumnIndex('status')),
        riskLevel: resultSet.getLong(resultSet.getColumnIndex('risk_level')),
        tags: JSON.parse(resultSet.getString(resultSet.getColumnIndex('tags')) || '[]'),
        aiSummary: resultSet.getString(resultSet.getColumnIndex('ai_summary'))
      };
      result.push(row);
    }
    resultSet.close();
    return result;
  }

  async addWorkOrder(orderId: string, relatedCallId: string, studentName: string, studentId: string, type: string, description: string, status: number, assignedTo: string, createdAt: string, riskLevel: number): Promise<void> {
    if (!this.rdbStore) return;
    let bucket: relationalStore.ValuesBucket = {
      'order_id': orderId,
      'related_call_id': relatedCallId,
      'student_name': studentName,
      'student_id': studentId,
      'type': type,
      'description': description,
      'status': status,
      'assigned_to': assignedTo,
      'created_at': createdAt,
      'updated_at': createdAt,
      'risk_level': riskLevel
    };
    try {
      await this.rdbStore.insert('work_orders', bucket);
    } catch (e) {
      console.error('Failed to add work order', JSON.stringify(e));
    }
  }

  async updateWorkOrderStatus(orderId: string, newStatus: number, assignedTo: string): Promise<boolean> {
    if (!this.rdbStore) return false;
    try {
      const sql = `UPDATE work_orders SET status = ?, assigned_to = ? WHERE order_id = ?`;
      await this.rdbStore.executeSql(sql, [newStatus, assignedTo, orderId]);
      return true;
    } catch (e) {
      return false;
    }
  }

  async updateWorkOrderRiskLevel(orderId: string, riskLevel: number): Promise<boolean> {
    if (!this.rdbStore) return false;
    try {
      // 简单的时间格式化为 YYYY-MM-DD HH:mm
      const d = new Date()
      const m = (d.getMonth() + 1).toString().padStart(2, '0')
      const dd = d.getDate().toString().padStart(2, '0')
      const hh = d.getHours().toString().padStart(2, '0')
      const mm = d.getMinutes().toString().padStart(2, '0')
      const nowStr = `${d.getFullYear()}-${m}-${dd} ${hh}:${mm}`
      
      const sql = `UPDATE work_orders SET risk_level = ?, updated_at = ? WHERE order_id = ?`;
      await this.rdbStore.executeSql(sql, [riskLevel, nowStr, orderId]);
      return true;
    } catch (e) {
      return false;
    }
  }

  async getAllWorkOrders(): Promise<WorkOrderRow[]> {
    if (!this.rdbStore) return [];
    const resultSet = await this.rdbStore.querySql('SELECT * FROM work_orders ORDER BY created_at DESC');
    const result: WorkOrderRow[] = [];
    while (resultSet.goToNextRow()) {
      const row: WorkOrderRow = {
        orderId: resultSet.getString(resultSet.getColumnIndex('order_id')),
        relatedCallId: resultSet.getString(resultSet.getColumnIndex('related_call_id')),
        studentName: resultSet.getString(resultSet.getColumnIndex('student_name')),
        studentId: resultSet.getString(resultSet.getColumnIndex('student_id')),
        type: resultSet.getString(resultSet.getColumnIndex('type')),
        description: resultSet.getString(resultSet.getColumnIndex('description')),
        status: resultSet.getLong(resultSet.getColumnIndex('status')),
        assignedTo: resultSet.getString(resultSet.getColumnIndex('assigned_to')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at')),
        updatedAt: resultSet.getString(resultSet.getColumnIndex('updated_at')),
        riskLevel: resultSet.getLong(resultSet.getColumnIndex('risk_level'))
      };
      result.push(row);
    }
    resultSet.close();
    return result;
  }

  async getWorkOrderById(orderId: string): Promise<WorkOrderRow | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates('work_orders');
    predicates.equalTo('order_id', orderId);
    const resultSet = await this.rdbStore.query(predicates);
    if (resultSet.goToFirstRow()) {
      const row: WorkOrderRow = {
        orderId: resultSet.getString(resultSet.getColumnIndex('order_id')),
        relatedCallId: resultSet.getString(resultSet.getColumnIndex('related_call_id')),
        studentName: resultSet.getString(resultSet.getColumnIndex('student_name')),
        studentId: resultSet.getString(resultSet.getColumnIndex('student_id')),
        type: resultSet.getString(resultSet.getColumnIndex('type')),
        description: resultSet.getString(resultSet.getColumnIndex('description')),
        status: resultSet.getLong(resultSet.getColumnIndex('status')),
        assignedTo: resultSet.getString(resultSet.getColumnIndex('assigned_to')),
        createdAt: resultSet.getString(resultSet.getColumnIndex('created_at')),
        updatedAt: resultSet.getString(resultSet.getColumnIndex('updated_at')),
        riskLevel: resultSet.getLong(resultSet.getColumnIndex('risk_level'))
      };
      resultSet.close();
      return row;
    }
    resultSet.close();
    return null;
  }
}
