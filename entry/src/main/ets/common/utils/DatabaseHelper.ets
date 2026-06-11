import { relationalStore } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

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
}
