import { AuthResult } from '../../common/model/ApiResponse'
import { RoleType } from '../../common/model/UserInfo'
import { DatabaseHelper } from '../../common/utils/DatabaseHelper'

const SIMULATED_DELAY = 800
const TABLE_COUNSELORS = 'counselors'
const TABLE_SCHOOL_CENTER = 'school_center'

interface TokenHeader {
  alg: string
  typ: string
}

interface TokenPayload {
  uid: string
  roleType: RoleType
  iat: number
  exp: number
}

function base64Encode(str: string): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  let result = ''
  let i = 0
  while (i < str.length) {
    const a = str.charCodeAt(i++)
    const b = str.charCodeAt(i++)
    const c = str.charCodeAt(i++)
    const aIdx = a >> 2
    const bIdx = ((a & 3) << 4) | (b >> 4)
    const cIdx = ((b & 15) << 2) | (c >> 6)
    const dIdx = c & 63
    result += chars.charAt(aIdx) + chars.charAt(bIdx)
    if (isNaN(b)) {
      result += '=='
      break
    }
    result += chars.charAt(cIdx)
    if (isNaN(c)) {
      result += '='
      break
    }
    result += chars.charAt(dIdx)
  }
  return result
}

export class AuthService {
  private loginFailCount: Map<string, number> = new Map()
  private lockedAccounts: Map<string, number> = new Map()
  private readonly MAX_FAIL_COUNT = 5
  private readonly LOCK_DURATION = 15 * 60 * 1000

  async login(account: string, password: string, roleType: RoleType, rememberMe: boolean): Promise<AuthResult> {
    await this.delay(SIMULATED_DELAY)

    const result = new AuthResult()

    if (!account || !password) {
      result.authStatus = false
      result.errorCode = 1000
      result.errorMsg = '请输入账号和密码'
      return result
    }

    if (this.isAccountLocked(account)) {
      result.authStatus = false
      result.errorCode = 1002
      result.errorMsg = '账号已被锁定，请15分钟后再试'
      return result
    }

    // 尝试数据库登录（按选定角色查对应表）
    const dbResult = await this.tryDatabaseLogin(account, password, roleType)
    if (dbResult !== null) {
      return dbResult
    }

    // Mock 兜底
    const success = this.validateCredentials(account, password, roleType)
    if (success) {
      this.loginFailCount.set(account, 0)
      result.authStatus = true
      result.accessToken = this.generateMockToken(account, roleType)
      result.refreshToken = this.generateMockRefreshToken(account)
      result.jumpPath = this.getJumpPath(roleType)
      result.studentName = this.getMockName(account)
      return result
    }

    const failCount = (this.loginFailCount.get(account) || 0) + 1
    this.loginFailCount.set(account, failCount)

    if (failCount >= this.MAX_FAIL_COUNT) {
      this.lockedAccounts.set(account, Date.now())
      result.authStatus = false
      result.errorCode = 1002
      result.errorMsg = '账号已被锁定，请15分钟后再试'
      return result
    }

    result.authStatus = false
    result.errorCode = 1001
    result.errorMsg = '用户名或密码错误'
    return result
  }

  private async tryDatabaseLogin(uid: string, password: string, roleType: RoleType): Promise<AuthResult | null> {
    try {
      const dbHelper = DatabaseHelper.getInstance()

      if (roleType === RoleType.STUDENT) {
        const student = await dbHelper.validateLogin(uid, password)
        if (student !== null) {
          return this.buildDbSuccess(uid, student.name, RoleType.STUDENT)
        }
      }

      if (roleType === RoleType.COUNSELOR) {
        const staff = await dbHelper.validateStaffLogin(TABLE_COUNSELORS, uid, password)
        if (staff !== null) {
          return this.buildDbSuccess(uid, staff.name, RoleType.COUNSELOR)
        }
      }

      if (roleType === RoleType.SCHOOL_PSY_CENTER) {
        const staff = await dbHelper.validateStaffLogin(TABLE_SCHOOL_CENTER, uid, password)
        if (staff !== null) {
          return this.buildDbSuccess(uid, staff.name, RoleType.SCHOOL_PSY_CENTER)
        }
      }
    } catch (err) {
    }
    return null
  }

  private buildDbSuccess(uid: string, name: string, roleType: RoleType): AuthResult {
    const result = new AuthResult()
    result.authStatus = true
    result.accessToken = this.generateMockToken(uid, roleType)
    result.refreshToken = this.generateMockRefreshToken(uid)
    result.jumpPath = this.getJumpPath(roleType)
    result.studentName = name
    this.loginFailCount.set(uid, 0)
    return result
  }

  private validateCredentials(account: string, password: string, roleType: RoleType): boolean {
    const mockAccounts: Record<string, [string, RoleType]> = {
      '2024001': ['123456', RoleType.STUDENT],
      'T10001': ['123456', RoleType.COUNSELOR],
      'A10001': ['123456', RoleType.SCHOOL_PSY_CENTER]
    }
    const record = mockAccounts[account]
    if (record && record[0] === password && record[1] === roleType) {
      return true
    }
    return false
  }

  private getMockName(account: string): string {
    const names: Record<string, string> = {
      '2024001': '马超',
      'T10001': '王老师',
      'A10001': '李主任'
    }
    return names[account] || ''
  }

  private isAccountLocked(account: string): boolean {
    const lockTime = this.lockedAccounts.get(account)
    if (lockTime) {
      if (Date.now() - lockTime < this.LOCK_DURATION) {
        return true
      }
      this.lockedAccounts.delete(account)
    }
    return false
  }

  private getJumpPath(roleType: RoleType): string {
    switch (roleType) {
      case RoleType.STUDENT:
        return 'features/student/pages/StudentHomePage'
      case RoleType.COUNSELOR:
        return 'features/counselor/pages/CounselorHomePage'
      case RoleType.SCHOOL_PSY_CENTER:
        return 'features/school/pages/SchoolHomePage'
      default:
        return 'features/student/pages/StudentHomePage'
    }
  }

  private generateMockToken(account: string, roleType: RoleType): string {
    const header: TokenHeader = { alg: 'HS256', typ: 'JWT' }
    const payload: TokenPayload = {
      uid: account,
      roleType: roleType,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 7200
    }
    const headerStr = base64Encode(JSON.stringify(header))
    const payloadStr = base64Encode(JSON.stringify(payload))
    const signature = base64Encode('mock_signature_' + account)
    return `${headerStr}.${payloadStr}.${signature}`
  }

  private generateMockRefreshToken(account: string): string {
    return `rt_${account}_${Date.now()}`
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}
