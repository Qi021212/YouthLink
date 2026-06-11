// entry/src/main/ets/features/auth/pages/ChangePasswordPage.ets
import { router, promptAction } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { AuthManager } from '../../../core/auth/AuthManager'
import { RouterPath } from '../../../common/constants/RouterPath'

// 明确定义 JSON 的结构
export interface UserSessionInfo {
  uid: string;
  name: string;
  roleType?: number; // 如果有其他字段也在这里补上
}

@Entry
@Component
struct ChangePasswordPage {
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State isProcessing: boolean = false
  @State isOldVisible: boolean = false
  @State isNewVisible: boolean = false
  @State isConfirmVisible: boolean = false
  @State currentUid: string = ''

  async aboutToAppear(): Promise<void> {
    const authManager = AuthManager.getInstance();
    const isRestored = await authManager.restoreSession();

    if (isRestored) {
      this.currentUid = authManager.getUid();
      console.info(`[Auth] UID restored successfully: ${this.currentUid}`);
    } else {
      // 如果恢复失败，说明根本没登录过
      promptAction.showToast({ message: '请先登录' });
      router.replaceUrl({ url: RouterPath.LOGIN });
    }
  }

  build() {
    Column() {
      // 头部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(Colors.TEXT_PRIMARY)
          .onClick(() => router.back())
        Blank()
        Text('修改密码').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text('    ').width(24) // 占位保持居中
      }.width('100%').padding({ left: 16, top: 48, bottom: 16 })

      Column({ space: 16 }) {
        // 原密码
        this.InputItem('当前密码', '请输入原始密码', this.isOldVisible, (v) => this.oldPassword = v, () => this.isOldVisible = !this.isOldVisible)

        // 新密码
        this.InputItem('新密码', '请输入新密码（6~20位）', this.isNewVisible, (v) => this.newPassword = v, () => this.isNewVisible = !this.isNewVisible)

        // 确认新密码
        this.InputItem('确认新密码', '请再次输入新密码', this.isConfirmVisible, (v) => this.confirmPassword = v, () => this.isConfirmVisible = !this.isConfirmVisible)

        Button(this.isProcessing ? '正在重置...' : '确认修改')
          .width('100%')
          .height(50)
          .borderRadius(25)
          .backgroundColor(Colors.PRIMARY)
          .margin({ top: 32 })
          .enabled(!this.isProcessing)
          .onClick(async () => {
            // 校验逻辑
            if (this.newPassword.length < 6 || this.newPassword.length > 20) {
              promptAction.showToast({ message: '新密码长度应为6~20位' });
              return;
            }
            if (this.newPassword !== this.confirmPassword) {
              promptAction.showToast({ message: '两次输入的新密码不一致' });
              return;
            }
            if (!this.currentUid || this.currentUid.trim() === '') {
              promptAction.showToast({ message: '登录状态已失效，请重新登录' });
              return;
            }

            // 🌟 在此处调用你的权限校验与 API 修改逻辑
            this.isProcessing = true;
            // 2. 调用真实的 DatabaseHelper 更新方法
            const dbHelper = DatabaseHelper.getInstance();
            // 这里我们传入 'counselors' 表，或者根据逻辑动态判断是哪个员工表
            console.info(`Debug: Attempting to update password for UID: ${this.currentUid}`);
            const success = await dbHelper.updateStaffPassword('counselors', this.currentUid, this.newPassword);

            if (success) {
              promptAction.showToast({ message: '密码已成功同步至数据库' });
              // 销毁旧会话，跳转登录
              await AuthManager.getInstance().logout();
              router.replaceUrl({ url: RouterPath.LOGIN });
            } else {
              promptAction.showToast({ message: '密码更新失败，请检查数据库权限' });
            }
            this.isProcessing = false;
          })
      }
      .width('100%')
      .padding({ left: 32, right: 32, top: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  InputItem(label: string, placeholder: string, isVisible: boolean, onChange: (v: string) => void, onToggle: () => void) {
    Column() {
      Text(label).fontSize(14).fontColor(Colors.TEXT_SECONDARY).margin({ bottom: 8 })
      Row() {
        TextInput({ placeholder: placeholder })
          .type(isVisible ? InputType.Normal : InputType.Password)
          .backgroundColor(Color.Transparent)
          .fontSize(16)
          .layoutWeight(1)
          .onChange(onChange)

        Text(isVisible ? '隐藏' : '显示')
          .fontSize(12)
          .fontColor(Colors.PRIMARY)
          .onClick(onToggle)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Colors.SURFACE)
      .borderRadius(12)
    }.alignItems(HorizontalAlign.Start)
  }
}