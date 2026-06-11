import { promptAction, router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { Colors } from '../../../common/constants/Colors'
import { RoleType, UserInfo } from '../../../common/model/UserInfo'
import { AuthService } from '../AuthService'
import { AuthManager } from '../../../core/auth/AuthManager'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { RouterPath } from '../../../common/constants/RouterPath'

interface RoleOption {
  label: string
  value: RoleType
}

@Entry
@Component
struct LoginPage {
  @State account: string = ''
  @State password: string = ''
  @State selectedRole: RoleType = RoleType.STUDENT
  @State rememberMe: boolean = false
  @State isPasswordVisible: boolean = false
  @State isLoading: boolean = false
  @State captchaRequired: boolean = false
  @State captchaCode: string = ''
  private authService: AuthService = new AuthService()
  private roleOptions: RoleOption[] = [
    { label: '学生', value: RoleType.STUDENT },
    { label: '辅导员', value: RoleType.COUNSELOR },
    { label: '校级心理中心', value: RoleType.SCHOOL_PSY_CENTER }
  ]

  aboutToAppear(): void {
    this.loadRememberedAccount()
  }

  async loadRememberedAccount(): Promise<void> {
    const authManager = AuthManager.getInstance()
    this.rememberMe = await authManager.getRememberMe()
    if (this.rememberMe) {
      this.account = await authManager.getRememberedAccount()
    }
  }

  async onLogin(): Promise<void> {
    if (!this.account.trim()) {
      promptAction.showToast({ message: '请输入账号', duration: 2000 })
      return
    }
    if (!this.password.trim()) {
      promptAction.showToast({ message: '请输入密码', duration: 2000 })
      return
    }
    if (this.captchaRequired && !this.captchaCode.trim()) {
      promptAction.showToast({ message: '请输入验证码', duration: 2000 })
      return
    }

    this.isLoading = true

    try {
      const dbHelper = DatabaseHelper.getInstance()
      if (!dbHelper.isReady()) {
        await dbHelper.ensureInit(getContext(this) as common.UIAbilityContext)
      }

      const result = await this.authService.login(
        this.account.trim(),
        this.password,
        this.selectedRole,
        this.rememberMe
      )

      if (result.authStatus) {
        const authManager = AuthManager.getInstance()
        await authManager.setTokens(result.accessToken, result.refreshToken)
        await authManager.setRememberMe(this.account, this.rememberMe)

        const userInfo = new UserInfo()
        userInfo.uid = this.account
        userInfo.roleType = this.selectedRole
        userInfo.name = result.studentName.length > 0 ? result.studentName : this.account
        await authManager.saveUserInfo(JSON.stringify(userInfo.toJson()))
        authManager.setUserName(userInfo.name)

        const welcomeMsg = result.studentName.length > 0 ?
          `${result.studentName}，欢迎回来` : '登录成功'
        promptAction.showToast({ message: welcomeMsg, duration: 1500 })
        setTimeout(() => {
          router.replaceUrl({ url: result.jumpPath })
        }, 500)
      } else {
        promptAction.showToast({ message: result.errorMsg, duration: 2500 })
        if (result.errorCode === 1002) {
          this.captchaRequired = true
        }
      }
    } catch (err) {
      promptAction.showToast({ message: '网络异常，请稍后重试', duration: 2500 })
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      Column() {
        Text('欢迎登录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)

        Text('青春同行，从心出发')
          .fontSize(14)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 32, top: 80, bottom: 32 })

      Column() {
        Row() {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .margin({ right: 12 })

          TextInput({ placeholder: '请输入学号/工号', text: this.account })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .type(InputType.Normal)
            .onChange((value: string) => {
              this.account = value
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Colors.SURFACE)
        .borderRadius(12)
        .margin({ bottom: 16 })

        Row() {
          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .margin({ right: 12 })

          TextInput({ placeholder: '请输入密码', text: this.password })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
            .onChange((value: string) => {
              this.password = value
            })

          Text(this.isPasswordVisible ? '隐藏' : '显示')
            .fontSize(12)
            .fontColor(Colors.PRIMARY)
            .onClick(() => {
              this.isPasswordVisible = !this.isPasswordVisible
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Colors.SURFACE)
        .borderRadius(12)
        .margin({ bottom: 20 })

        Text('选择角色')
          .fontSize(14)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ bottom: 12 })
          .alignSelf(ItemAlign.Start)

        Row() {
          ForEach(this.roleOptions, (item: RoleOption) => {
            Text(item.label)
              .fontSize(14)
              .fontColor(this.selectedRole === item.value ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_SECONDARY)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .borderRadius(20)
              .backgroundColor(this.selectedRole === item.value ? Colors.PRIMARY : Colors.SURFACE)
              .margin({ right: 10, bottom: 10 })
              .onClick(() => {
                this.selectedRole = item.value
              })
          })
        }
        .width('100%')

        Row() {
          Row() {
            Checkbox({ name: 'rememberMe', group: 'loginGroup' })
              .select(this.rememberMe)
              .selectedColor(Colors.PRIMARY)
              .size({ width: 18, height: 18 })
              .onChange((value: boolean) => {
                this.rememberMe = value
              })

            Text('记住我')
              .fontSize(13)
              .fontColor(Colors.TEXT_HINT)
              .margin({ left: 6 })
          }

          Blank()

          Text('忘记密码？')
            .fontSize(13)
            .fontColor(Colors.PRIMARY)
        }
        .width('100%')
        .margin({ top: 24, bottom: 28 })

        if (this.captchaRequired) {
          Row() {
            TextInput({ placeholder: '请输入验证码', text: this.captchaCode })
              .placeholderColor(Colors.TEXT_HINT)
              .fontSize(16)
              .layoutWeight(1)
              .backgroundColor(Colors.SURFACE)
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.captchaCode = value
              })

            Text('获取验证码')
              .fontSize(13)
              .fontColor(Colors.TEXT_ON_PRIMARY)
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(Colors.PRIMARY)
              .borderRadius(8)
              .margin({ left: 12 })
          }
          .width('100%')
          .height(44)
          .margin({ bottom: 16 })
        }

        Button(this.isLoading ? '登录中...' : '登 录')
          .width('100%')
          .height(50)
          .fontSize(16)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .backgroundColor(Colors.PRIMARY)
          .borderRadius(25)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.onLogin()
          })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Blank()

      Row() {
        Text('没有账号？')
          .fontSize(14)
          .fontColor(Colors.TEXT_HINT)

        Text('立即注册')
          .fontSize(14)
          .fontColor(Colors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 4 })
          .onClick(() => {
            router.pushUrl({ url: RouterPath.REGISTER })
          })
      }
      .padding({ bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
