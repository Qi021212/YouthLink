import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { HotlineCall, CallStatus, RiskLevel, WorkOrderStatus } from '../model/SchoolModels'
import { SchoolService } from '../service/SchoolService'
import { RiskBadge } from '../../../common/components/RiskBadge'
import promptAction from '@ohos.promptAction'
import { DatabaseHelper } from '../../../common/utils/DatabaseHelper'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct HotlinePage {
  @State activeCalls: HotlineCall[] = []
  @State isLoading: boolean = true
  private service: SchoolService = new SchoolService()

  // 模拟数据状态
  @State expandedCallId: string = ''
  @State simulatedEmotion: number = 80
  @State simulatedDialogues: string[] = []
  private timerId: number = -1

  async aboutToAppear(): Promise<void> {
    await DatabaseHelper.getInstance().ensureInit(getContext(this) as common.UIAbilityContext)
    await this.loadData()
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
  }

  private async loadData() {
    this.isLoading = true
    try {
      this.activeCalls = await this.service.fetchActiveCalls()
    } catch (e) {
      this.activeCalls = []
    } finally {
      this.isLoading = false
    }
  }

  private getCallStatusLabel(status: CallStatus): string {
    if (status === CallStatus.ONGOING) return '实时监控中'
    if (status === CallStatus.COMPLETED) return '已结束'
    return '未接听'
  }

  private formatDuration(seconds: number): string {
    const m: number = Math.floor(seconds / 60)
    const s: number = seconds % 60
    return m + '\'' + s.toString().padStart(2, '0') + '"'
  }

  private toggleCallExpand(call: HotlineCall) {
    if (this.expandedCallId === call.callId) {
      this.expandedCallId = ''
      clearInterval(this.timerId)
      return
    }
    this.expandedCallId = call.callId
    this.simulatedEmotion = 85
    
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }

    if (call.callId === 'CALL-20250115-002') { // 林小婉 - 焦虑/寝室矛盾
      this.simulatedDialogues = [
        '【系统提示】电话已接通，AI前哨正在为您识别语音...',
        '【学生】喂...我快烦死了，我实在没办法在那个寝室待下去了！',
        '【AI接线员】同学你好，我是心晴热线AI助手。听上去你现在非常心烦，能说说寝室里发生了什么吗？'
      ]
      let step = 0
      this.timerId = setInterval(() => {
        step++
        if (step === 1) {
          this.simulatedDialogues.push('【学生】她们每天晚上两三点还不睡觉，外放看视频，我根本睡不着！')
          this.simulatedEmotion = 60
        } else if (step === 2) {
          this.simulatedDialogues.push('【系统提示】⚠️检测到烦躁情绪，风险指数平稳。')
          this.simulatedEmotion = 50
        } else if (step === 3) {
          this.simulatedDialogues.push('【AI接线员】长时间休息不好确实让人崩溃。你尝试过跟她们沟通过这个问题吗？')
        } else if (step === 4) {
          this.simulatedDialogues.push('【系统提示】建议：转介给辅导员进行寝室调解。')
          this.simulatedEmotion = 45
          clearInterval(this.timerId)
        }
      }, 2500)
    } else if (call.callId === 'CALL-20250115-003') { // 王浩宇 - 情感困扰
      this.simulatedDialogues = [
        '【系统提示】电话已接通，AI前哨正在为您识别语音...',
        '【学生】你好...我感觉自己好像什么都做不好，突然觉得特别迷茫。',
        '【AI接线员】同学你好，我是心晴热线AI助手。听得出你现在有些失落，发生什么事了吗？'
      ]
      let step = 0
      this.timerId = setInterval(() => {
        step++
        if (step === 1) {
          this.simulatedDialogues.push('【学生】我女朋友上周跟我分手了，然后最近专业课的小组作业也被老师批评了...')
          this.simulatedEmotion = 55
        } else if (step === 2) {
          this.simulatedDialogues.push('【系统提示】⚠️检测到失落情绪，风险等级低。')
          this.simulatedEmotion = 50
        } else if (step === 3) {
          this.simulatedDialogues.push('【AI接线员】连续遇到两件不顺心的事，确实很容易让人产生自我怀疑。你想先聊聊哪件事呢？')
        } else if (step === 4) {
          this.simulatedDialogues.push('【系统提示】正在进行倾听和情感支持...')
          clearInterval(this.timerId)
        }
      }, 2500)
    } else if (call.callId === 'CALL-20250114-005') { // 匿名来电 - 高危
      this.simulatedDialogues = [
        '【系统提示】电话已接通，AI前哨正在为您识别语音...',
        '【匿名学生】...（沉默了半分钟）...我不想到明天了。',
        '【AI接线员】同学你好，我是心晴热线AI助手。我在这里陪着你，发生了什么事让你觉得这么痛苦？'
      ]
      let step = 0
      this.timerId = setInterval(() => {
        step++
        if (step === 1) {
          this.simulatedDialogues.push('【匿名学生】不想再拖累家人了，我已经去天台看过好几次了。')
          this.simulatedEmotion = 30
        } else if (step === 2) {
          this.simulatedDialogues.push('【系统提示】⚠️检测到极高危情绪！')
          this.simulatedEmotion = 20
        } else if (step === 3) {
          this.simulatedDialogues.push('【AI接线员】听着，你现在的处境确实很艰难，但请不要伤害自己，你现在在哪里？我们可以帮你。')
        } else if (step === 4) {
          this.simulatedDialogues.push('【系统预警】⚠️高危言论识别！立即启动定位并通知校保卫处！')
          this.simulatedEmotion = 5
          promptAction.showToast({ message: '🚨 紧急：匿名来电高风险，已通知校保卫处！', duration: 4000, bottom: 80 })
          clearInterval(this.timerId)
        }
      }, 2500)
    } else {
      // 默认的（CALL-20250115-001 或其他）
      this.simulatedDialogues = [
        '【系统提示】电话已接通，AI前哨正在为您识别语音...',
        '【学生】喂...我不想学了，我觉得活着没什么意思。',
        '【AI接线员】同学你好，我是心晴热线AI助手。听到你这么说我很难过，能跟我具体说说最近发生了什么事吗？'
      ]
      let step = 0
      this.timerId = setInterval(() => {
        step++
        if (step === 1) {
          this.simulatedDialogues.push('【学生】我感觉周围的人都在针对我，天天被导师骂...')
          this.simulatedEmotion = 60
        } else if (step === 2) {
          this.simulatedDialogues.push('【系统提示】⚠️检测到异常情绪波动，风险指数上升')
          this.simulatedEmotion = 40
        } else if (step === 3) {
          this.simulatedDialogues.push('【AI接线员】导师的批评确实会让人感到很有压力。你现在在哪？周围有人陪你吗？')
        } else if (step === 4) {
          this.simulatedDialogues.push('【系统预警】⚠️高危言论识别："没人在乎我，我想一了百了"。建议立即启动转接流程！')
          this.simulatedEmotion = 15
          promptAction.showToast({ message: '⚠️ 监测到高危言论，请立刻处理！', duration: 3000, bottom: 80 })
          clearInterval(this.timerId)
        }
      }, 2500)
    }
  }

  private async transferToHuman(call: HotlineCall) {
    // 真实操作数据库
    const db = DatabaseHelper.getInstance()
    const newOrderId = 'WO-' + new Date().getTime().toString()
    
    // 1. 关闭通话状态
    await db.updateHotlineCallStatus(call.callId, CallStatus.COMPLETED)
    
    // 2. 生成极危工单
    const nowStr = new Date().toLocaleString()
    await db.addWorkOrder(
      newOrderId, 
      call.callId, 
      call.callerName, 
      call.callerStudentId, 
      '紧急危机干预(热线转接)', 
      `AI自动拦截高危来电转接。对话摘要：${call.aiSummary}`, 
      WorkOrderStatus.PENDING, 
      '', 
      nowStr, 
      RiskLevel.CRITICAL
    )

    promptAction.showToast({ message: '✅ 已成功转接人工并生成极危工单！' })
    this.expandedCallId = ''
    clearInterval(this.timerId)
    await this.loadData()
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => { router.back() })
        Text('AI热线监控指挥舱')
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
      } else if (this.activeCalls.length === 0) {
        Column() {
          Text('暂无活跃的热线通话')
            .fontSize(16)
            .fontColor(Colors.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.activeCalls, (call: HotlineCall) => {
            ListItem() {
              Column() {
                // 顶部卡片简报
                Row() {
                  Column() {
                    Row() {
                      Text(call.callerName)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Colors.TEXT_PRIMARY)
                      
                      RiskBadge({ riskLevel: call.riskLevel })
                        .margin({ left: 8 })
                    }
                    Text(call.phoneNumber)
                      .fontSize(12)
                      .fontColor(Colors.TEXT_HINT)
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Column() {
                    Text(this.getCallStatusLabel(call.status))
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(call.status === CallStatus.ONGOING ? Colors.WARNING : Colors.SUCCESS)
                      .animation({ duration: 1000, iterations: -1, playMode: PlayMode.Alternate })
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .borderRadius(12)
                  .backgroundColor(call.status === CallStatus.ONGOING ? Colors.WARNING + '20' : Colors.SUCCESS + '20')
                }
                .width('100%')
                
                Row() {
                  Text('持续时间: ' + this.formatDuration(call.duration))
                    .fontSize(13)
                    .fontColor(Colors.TEXT_SECONDARY)
                  Blank()
                  Row() {
                    ForEach(call.tags, (tag: string) => {
                      Text(tag)
                        .fontSize(11)
                        .fontColor(Colors.PRIMARY)
                        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                        .borderRadius(4)
                        .backgroundColor(Colors.PRIMARY + '15')
                        .margin({ left: 4 })
                    })
                  }
                }
                .width('100%')
                .margin({ top: 12 })

                // 展开实时监控面板
                if (this.expandedCallId === call.callId) {
                  Divider().color('#E5E7EB').margin({ top: 16, bottom: 16 })
                  
                  Row() {
                    Column() {
                      DataPanel({ values: [this.simulatedEmotion], max: 100, type: DataPanelType.Line })
                        .width(100)
                        .height(10)
                        .valueColors([this.simulatedEmotion < 30 ? Colors.ERROR : Colors.SUCCESS])
                      Text(`实时情绪指数: ${Math.floor(this.simulatedEmotion)}`)
                        .fontSize(12)
                        .fontColor(this.simulatedEmotion < 30 ? Colors.ERROR : Colors.TEXT_SECONDARY)
                        .margin({ top: 6 })
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start)

                    Button('紧急转接人工')
                      .backgroundColor(Colors.ERROR)
                      .fontColor('#FFFFFF')
                      .fontSize(13)
                      .height(32)
                      .onClick(() => {
                        this.transferToHuman(call)
                      })
                  }
                  .width('100%')
                  
                  // 实时对话框
                  Column() {
                    ForEach(this.simulatedDialogues, (dlg: string) => {
                      Text(dlg)
                        .fontSize(13)
                        .fontColor(dlg.indexOf('⚠️') >= 0 ? Colors.ERROR : Colors.TEXT_PRIMARY)
                        .margin({ bottom: 8 })
                        .width('100%')
                        .textAlign(TextAlign.Start)
                    })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#11111105')
                  .borderRadius(8)
                  .margin({ top: 16 })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Colors.CARD_BG)
              .borderRadius(12)
              .borderWidth(this.expandedCallId === call.callId ? 2 : 0)
              .borderColor(Colors.PRIMARY)
              .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 3 })
              .margin({ bottom: 12 })
              .onClick(() => {
                if (call.status === CallStatus.ONGOING) {
                  this.toggleCallExpand(call)
                }
              })
              .animation({ duration: 300 })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }
}
