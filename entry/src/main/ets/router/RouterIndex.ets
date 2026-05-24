import { router } from '@kit.ArkUI'
import { AuthManager } from '../core/auth/AuthManager'

export class RouterIndex {
  static push(url: string, params?: Record<string, Object>): void {
    router.pushUrl({
      url: url,
      params: params
    })
  }

  static replace(url: string, params?: Record<string, Object>): void {
    router.replaceUrl({
      url: url,
      params: params
    })
  }

  static back(): void {
    router.back()
  }

  static clearAndPush(url: string, params?: Record<string, Object>): void {
    router.clear()
    router.pushUrl({
      url: url,
      params: params
    })
  }
}
