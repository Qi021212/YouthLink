import { promptAction, router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { Colors } from '../../../common/constants/Colors'
import { RoleType } from '../../../common/model/UserInfo'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'

class RoleTab {
  label: string
  roleType: RoleType

  constructor(label: string, roleType: RoleType) {
    this.label = label
    this.roleType = roleType
  }
}

const TABLE_COUNSELORS = 'counselors'
const TABLE_SCHOOL_CENTER = 'school_center'

@Entry
@Component
struct RegisterPage {
  @State uid: string = ''
  @State name: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State captchaInput: string = ''
  @State captchaCode: string = ''
  @State isPasswordVisible: boolean = false
  @State isConfirmVisible: boolean = false
  @State isLoading: boolean = false
  @State isAgreementChecked: boolean = false
  @State selectedRoleType: RoleType = RoleType.STUDENT
  @State uidPlaceholder: string = '请输入学号（6~20位）'

  private roleTabs: RoleTab[] = [
    new RoleTab('学生', RoleType.STUDENT),
    new RoleTab('辅导员', RoleType.COUNSELOR),
    new RoleTab('校级心理中心', RoleType.SCHOOL_PSY_CENTER)
  ]

  aboutToAppear(): void {
    this.generateCaptcha()
  }

  updatePlaceholder(): void {
    if (this.selectedRoleType === RoleType.STUDENT) {
      this.uidPlaceholder = '请输入学号（6~20位）'
    } else {
      this.uidPlaceholder = '请输入工号（6~20位）'
    }
  }

  generateCaptcha(): void {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    let code = ''
    for (let i = 0; i < 4; i++) {
      const idx = Math.floor(Math.random() * chars.length)
      code += chars.charAt(idx)
    }
    this.captchaCode = code
  }

  getTableNameForRole(): string {
    if (this.selectedRoleType === RoleType.COUNSELOR) {
      return TABLE_COUNSELORS
    }
    if (this.selectedRoleType === RoleType.SCHOOL_PSY_CENTER) {
      return TABLE_SCHOOL_CENTER
    }
    return ''
  }

  async onRegister(): Promise<void> {
    if (!this.uid.trim()) {
      const label = this.selectedRoleType === RoleType.STUDENT ? '学号' : '工号'
      promptAction.showToast({ message: `请输入${label}`, duration: 2000 })
      return
    }
    if (this.uid.trim().length < 6 || this.uid.trim().length > 20) {
      const label = this.selectedRoleType === RoleType.STUDENT ? '学号' : '工号'
      promptAction.showToast({ message: `${label}长度6~20位`, duration: 2000 })
      return
    }
    if (!this.name.trim()) {
      promptAction.showToast({ message: '请输入姓名', duration: 2000 })
      return
    }
    if (!this.password) {
      promptAction.showToast({ message: '请输入密码', duration: 2000 })
      return
    }
    if (this.password.length < 6 || this.password.length > 20) {
      promptAction.showToast({ message: '密码长度6~20位', duration: 2000 })
      return
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致', duration: 2000 })
      return
    }
    if (!this.captchaInput.trim()) {
      promptAction.showToast({ message: '请输入验证码', duration: 2000 })
      return
    }
    if (this.captchaInput.toUpperCase() !== this.captchaCode.toUpperCase()) {
      promptAction.showToast({ message: '验证码错误，请重新输入', duration: 2000 })
      this.captchaInput = ''
      this.generateCaptcha()
      return
    }
    if (!this.isAgreementChecked) {
      promptAction.showToast({ message: '请阅读并同意用户协议', duration: 2000 })
      return
    }

    this.isLoading = true

    try {
      const dbHelper = DatabaseHelper.getInstance()

      if (!dbHelper.isReady()) {
        const ok = await dbHelper.ensureInit(getContext(this) as common.UIAbilityContext)
        if (!ok) {
          promptAction.showToast({ message: '系统初始化中，请稍后重试', duration: 2500 })
          this.isLoading = false
          return
        }
      }

      let success = false

      if (this.selectedRoleType === RoleType.STUDENT) {
        success = await dbHelper.registerStudent(
          this.uid.trim(),
          this.name.trim(),
          this.password
        )
      } else {
        const tableName = this.getTableNameForRole()
        success = await dbHelper.registerStaff(
          tableName,
          this.uid.trim(),
          this.name.trim(),
          this.password
        )
      }

      if (success) {
        promptAction.showToast({ message: '注册成功，请登录', duration: 2000 })
        setTimeout(() => {
          router.back()
        }, 1500)
      } else {
        const label = this.selectedRoleType === RoleType.STUDENT ? '该学号' : '该工号'
        promptAction.showToast({ message: `${label}已被注册`, duration: 2500 })
      }
    } catch (err) {
      promptAction.showToast({ message: '注册失败，请稍后重试', duration: 2500 })
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(Colors.TEXT_PRIMARY)
          .onClick(() => {
            router.back()
          })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, top: 48, bottom: 16 })

      Column() {
        Text('创建账号')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)

        Text('注册后即可使用青心链全部功能')
          .fontSize(14)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 32, bottom: 12 })

      // 角色选择 Tab
      Row() {
        ForEach(this.roleTabs, (item: RoleTab) => {
          Text(item.label)
            .fontSize(14)
            .fontColor(this.selectedRoleType === item.roleType ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_SECONDARY)
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .borderRadius(22)
            .backgroundColor(this.selectedRoleType === item.roleType ? Colors.PRIMARY : Colors.SURFACE)
            .margin({ right: 10 })
            .onClick(() => {
              this.selectedRoleType = item.roleType
              this.updatePlaceholder()
            })
        })
      }
      .width('100%')
      .padding({ left: 32, bottom: 24 })

      Column() {
        Row() {
          TextInput({ placeholder: this.uidPlaceholder, text: this.uid })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .type(InputType.Normal)
            .maxLength(20)
            .onChange((value: string) => {
              this.uid = value
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Colors.SURFACE)
        .borderRadius(12)
        .margin({ bottom: 16 })

        Row() {
          TextInput({ placeholder: '请输入真实姓名', text: this.name })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .type(InputType.Normal)
            .maxLength(20)
            .onChange((value: string) => {
              this.name = value
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Colors.SURFACE)
        .borderRadius(12)
        .margin({ bottom: 16 })

        Row() {
          TextInput({ placeholder: '请设置密码（6~20位）', text: this.password })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .type(this.isPasswordVisible ? InputType.Normal : InputType.Password)
            .maxLength(20)
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
        .margin({ bottom: 16 })

        Row() {
          TextInput({ placeholder: '请再次输入密码', text: this.confirmPassword })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .type(this.isConfirmVisible ? InputType.Normal : InputType.Password)
            .maxLength(20)
            .onChange((value: string) => {
              this.confirmPassword = value
            })

          Text(this.isConfirmVisible ? '隐藏' : '显示')
            .fontSize(12)
            .fontColor(Colors.PRIMARY)
            .onClick(() => {
              this.isConfirmVisible = !this.isConfirmVisible
            })
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Colors.SURFACE)
        .borderRadius(12)
        .margin({ bottom: 24 })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Column() {
        Text('安全验证')
          .fontSize(14)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ bottom: 12 })
          .alignSelf(ItemAlign.Start)

        Row() {
          TextInput({ placeholder: '请输入右侧验证码', text: this.captchaInput })
            .placeholderColor(Colors.TEXT_HINT)
            .fontSize(16)
            .layoutWeight(1)
            .backgroundColor(Colors.SURFACE)
            .borderRadius(10)
            .padding({ left: 14 })
            .type(InputType.Normal)
            .maxLength(4)
            .onChange((value: string) => {
              this.captchaInput = value
            })

          Column() {
            Text(this.captchaCode)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.PRIMARY)
              .fontStyle(FontStyle.Italic)

            Row() {
              Text('换一张')
                .fontSize(10)
                .fontColor(Colors.PRIMARY)
            }
            .margin({ top: 4 })
            .onClick(() => {
              this.generateCaptcha()
              this.captchaInput = ''
            })
          }
          .width(120)
          .height(48)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(Colors.PRIMARY + '12')
          .borderRadius(10)
          .margin({ left: 12 })
          .onClick(() => {
            this.generateCaptcha()
            this.captchaInput = ''
          })
        }
        .width('100%')
        .height(52)
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Row() {
        Checkbox({ name: 'agreement', group: 'registerGroup' })
          .select(this.isAgreementChecked)
          .selectedColor(Colors.PRIMARY)
          .size({ width: 18, height: 18 })
          .onChange((value: boolean) => {
            this.isAgreementChecked = value
          })

        Text('我已阅读并同意')
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)
          .margin({ left: 6 })

        Text('《用户协议》')
          .fontSize(13)
          .fontColor(Colors.PRIMARY)
          .onClick(() => {
            promptAction.showToast({ message: '用户协议详情', duration: 1500 })
          })

        Text('和')
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)
          .margin({ left: 2 })

        Text('《隐私政策》')
          .fontSize(13)
          .fontColor(Colors.PRIMARY)
          .onClick(() => {
            promptAction.showToast({ message: '隐私政策详情', duration: 1500 })
          })
      }
      .width('100%')
      .padding({ left: 38, right: 32 })

      Button(this.isLoading ? '注册中...' : '注 册')
        .width('86%')
        .height(50)
        .fontSize(16)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .backgroundColor(Colors.PRIMARY)
        .borderRadius(25)
        .margin({ top: 28 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.onRegister()
        })

      Blank()

      Row() {
        Text('已有账号？')
          .fontSize(14)
          .fontColor(Colors.TEXT_HINT)

        Text('立即登录')
          .fontSize(14)
          .fontColor(Colors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 4 })
          .onClick(() => {
            router.back()
          })
      }
      .padding({ bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
