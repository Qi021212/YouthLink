import { putString, getString, putBoolean, getBoolean, remove } from '../../common/utils/StorageUtil'

const KEY_ACCESS_TOKEN = 'access_token'
const KEY_REFRESH_TOKEN = 'refresh_token'
const KEY_USER_INFO = 'user_info'
const KEY_REMEMBER_ME = 'remember_me'
const KEY_LOGIN_ACCOUNT = 'login_account'

export class AuthManager {
  private static instance: AuthManager
  private accessToken: string = ''
  private refreshToken: string = ''
  private isLoggedIn: boolean = false
  private userName: string = ''

  static getInstance(): AuthManager {
    if (!AuthManager.instance) {
      AuthManager.instance = new AuthManager()
    }
    return AuthManager.instance
  }

  async restoreSession(): Promise<boolean> {
    const token = await getString(KEY_ACCESS_TOKEN, '')
    const rememberMe = await getBoolean(KEY_REMEMBER_ME, false)
    if (token.length > 0 || rememberMe) {
      this.accessToken = token
      this.refreshToken = await getString(KEY_REFRESH_TOKEN, '')
      this.isLoggedIn = true
      return true
    }
    return false
  }

  async setTokens(accessToken: string, refreshToken: string): Promise<void> {
    this.accessToken = accessToken
    this.refreshToken = refreshToken
    this.isLoggedIn = true
    await putString(KEY_ACCESS_TOKEN, accessToken)
    await putString(KEY_REFRESH_TOKEN, refreshToken)
  }

  async setRememberMe(account: string, remember: boolean): Promise<void> {
    await putBoolean(KEY_REMEMBER_ME, remember)
    if (remember) {
      await putString(KEY_LOGIN_ACCOUNT, account)
    } else {
      await remove(KEY_LOGIN_ACCOUNT)
    }
  }

  async getRememberedAccount(): Promise<string> {
    return await getString(KEY_LOGIN_ACCOUNT, '')
  }

  async getRememberMe(): Promise<boolean> {
    return await getBoolean(KEY_REMEMBER_ME, false)
  }

  getAccessToken(): string {
    return this.accessToken
  }

  getRefreshToken(): string {
    return this.refreshToken
  }

  getIsLoggedIn(): boolean {
    return this.isLoggedIn
  }

  async logout(): Promise<void> {
    this.accessToken = ''
    this.refreshToken = ''
    this.isLoggedIn = false
    await remove(KEY_ACCESS_TOKEN)
    await remove(KEY_REFRESH_TOKEN)
    await remove(KEY_REMEMBER_ME)
  }

  async saveUserInfo(userInfoJson: string): Promise<void> {
    await putString(KEY_USER_INFO, userInfoJson)
  }

  async getUserInfoJson(): Promise<string> {
    return await getString(KEY_USER_INFO, '')
  }

  setUserName(name: string): void {
    this.userName = name
  }

  getUserName(): string {
    return this.userName
  }
}
