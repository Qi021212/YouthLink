import { router, promptAction } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { Colors } from '../../../common/constants/Colors'
import { FollowUpTask, FollowUpPriority } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { RiskBadge } from '../../../common/components/RiskBadge'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'

@Entry
@Component
struct FollowUpPage {
  @State tasks: FollowUpTask[] = []
  @State isLoading: boolean = true
  private service: SchoolService = new SchoolService()

  async aboutToAppear(): Promise<void> {
    await this.loadTasks()
  }

  async loadTasks(): Promise<void> {
    this.isLoading = true
    try {
      await DatabaseHelper.getInstance().ensureInit(getContext(this) as common.UIAbilityContext)
      this.tasks = await this.service.fetchFollowUpTasks()
    } catch (e) {
      this.tasks = []
    } finally {
      this.isLoading = false
    }
  }

  async handleMarkDone(task: FollowUpTask): Promise<void> {
    await this.service.markFollowUpDone(task.taskId)
    await this.loadTasks()
  }

  async handleUndo(task: FollowUpTask): Promise<void> {
    await this.service.markFollowUpUndone(task.taskId)
    await this.loadTasks()
  }

  // 模拟拨号：仅提示，不真正调起系统电话
  handleContact(task: FollowUpTask): void {
    promptAction.showToast({ message: '正在为「' + task.studentName + '」接通心理援助专线…', duration: 2000 })
  }

  private getUrgentTasks(): FollowUpTask[] {
    return this.tasks.filter((t: FollowUpTask) => t.priority === FollowUpPriority.URGENT && !t.completed)
  }

  private getNormalTasks(): FollowUpTask[] {
    return this.tasks.filter((t: FollowUpTask) => t.priority === FollowUpPriority.NORMAL && !t.completed)
  }

  private getDoneTasks(): FollowUpTask[] {
    return this.tasks.filter((t: FollowUpTask) => t.completed)
  }

  private getPriorityColor(priority: FollowUpPriority): string {
    if (priority === FollowUpPriority.URGENT) return Colors.ERROR
    return Colors.WARNING
  }

  private getPriorityBg(priority: FollowUpPriority): string {
    if (priority === FollowUpPriority.URGENT) return '#FEE2E2'
    return '#FEF3C7'
  }

  @Builder
  TaskCard(task: FollowUpTask) {
    Column() {
      Row() {
        Column() {
          Text(task.studentName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
          Text(task.studentId)
            .fontSize(12)
            .fontColor(Colors.TEXT_HINT)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          if (task.completed) {
            Text('✓ 已完成')
              .fontSize(12)
              .fontColor(Colors.SUCCESS)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(4)
              .backgroundColor('#DCFCE7')
          } else {
            RiskBadge({ riskLevel: task.riskLevel })
          }
        }
      }
      .width('100%')

      Text(task.reason)
        .fontSize(14)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ top: 10 })
        .width('100%')

      Row() {
        Row() {
          Column().width(6).height(6).borderRadius(3).backgroundColor(this.getPriorityColor(task.priority))
          Text(task.priority === FollowUpPriority.URGENT ? '紧急' : '常规')
            .fontSize(12)
            .fontColor(this.getPriorityColor(task.priority))
            .margin({ left: 4 })
        }
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius(4)
        .backgroundColor(this.getPriorityBg(task.priority))

        Blank()

        Text('截止: ' + task.deadline)
          .fontSize(12)
          .fontColor(Colors.TEXT_HINT)
      }
      .width('100%')
      .margin({ top: 10 })

      if (task.completed) {
        Row() {
          Button('撤销完成')
            .fontSize(13)
            .fontColor(Colors.TEXT_SECONDARY)
            .backgroundColor('#F3F4F6')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => { this.handleUndo(task) })
        }
        .width('100%')
        .margin({ top: 12 })
      } else {
        Row() {
          Button('标记完成')
            .fontSize(13)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.SUCCESS)
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => { this.handleMarkDone(task) })

          Button('联系学生')
            .fontSize(13)
            .fontColor(Colors.PRIMARY)
            .backgroundColor(Colors.PRIMARY + '15')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 10 })
            .onClick(() => { this.handleContact(task) })
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius(12)
    .opacity(task.completed ? 0.75 : 1)
    .shadow({ radius: 4, color: Colors.SHADOW, offsetY: 2 })
    .margin({ bottom: 10 })
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('高危跟进')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .backgroundColor(Colors.PRIMARY)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          if (this.getUrgentTasks().length > 0) {
            ListItem() {
              Text('紧急跟进 (' + this.getUrgentTasks().length + ')')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.ERROR)
                .padding({ left: 16, top: 16, bottom: 8 })
                .width('100%')
            }

            ForEach(this.getUrgentTasks(), (task: FollowUpTask) => {
              ListItem() { this.TaskCard(task) }
            })
          }

          if (this.getNormalTasks().length > 0) {
            ListItem() {
              Text('常规跟进 (' + this.getNormalTasks().length + ')')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.WARNING)
                .padding({ left: 16, top: 12, bottom: 8 })
                .width('100%')
            }

            ForEach(this.getNormalTasks(), (task: FollowUpTask) => {
              ListItem() { this.TaskCard(task) }
            })
          }

          if (this.getDoneTasks().length > 0) {
            ListItem() {
              Text('已完成 (' + this.getDoneTasks().length + ')')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.SUCCESS)
                .padding({ left: 16, top: 12, bottom: 8 })
                .width('100%')
            }

            ForEach(this.getDoneTasks(), (task: FollowUpTask) => {
              ListItem() { this.TaskCard(task) }
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 4 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
