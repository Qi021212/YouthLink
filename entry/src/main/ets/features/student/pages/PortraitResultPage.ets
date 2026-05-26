import { router } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'
import { getString } from '../../../common/utils/StorageUtil'
import { HistoryRecord } from '../../../common/utils/RiskAlgorithm'
import { AIPortraitService } from '../service/AIPortraitService'
import { RouterIndex } from '../../../router/RouterIndex'

@Entry
@Component
struct PortraitResultPage {
  @State aiPortraitText: string = ''
  @State isLoading: boolean = true
  @State scores: HistoryRecord[] = []

  private treeHoleText: string = ''
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)

  // 变更内部成员变量名
  private fullQaHistory: string = ''

  async aboutToAppear() {
    // 1. 获取路由参数中的全量问答文本历史
    const params = router.getParams() as Record<string, string>
    if (params && params['fullQaHistory']) {
      this.fullQaHistory = params['fullQaHistory']
    }

    // 2. 从本地读取分数
    const historyJson = await getString('LAST_SEMI_MONTHLY_SCORES', '[]')
    try {
      this.scores = JSON.parse(historyJson) as HistoryRecord[]
    } catch (e) {
      console.error(e)
    }

    // 3. 传给升级后的服务端方法
    this.aiPortraitText = await AIPortraitService.generatePortrait(this.scores, this.fullQaHistory)
    this.isLoading = false
  }

  // 绘制雷达图核心算法
  drawRadarChart() {
    if (this.scores.length === 0) return
    const ctx = this.canvasContext
    // 🌟 优化1：稍微扩大逻辑画布的尺寸，给外围文字留出呼吸感
    const width = 380
    const height = 380
    const centerX = width / 2
    const centerY = height / 2

    // 🌟 优化2：缩小雷达图的骨架半径 (从 100 改为 80)，防止文字被边缘裁切
    const radius = 80
    const sides = this.scores.length
    const angle = (Math.PI * 2) / sides

    ctx.clearRect(0, 0, width, height)

    // 绘制背景网格（5个层级）
    for (let level = 1; level <= 5; level++) {
      const r = radius * (level / 5)
      ctx.beginPath()
      for (let i = 0; i < sides; i++) {
        const x = centerX + r * Math.sin(i * angle)
        const y = centerY - r * Math.cos(i * angle)
        if (i === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      ctx.closePath()
      ctx.strokeStyle = '#E5E7EB'
      ctx.stroke()
    }

    // 🌟 优化3：放大字体、加粗，并设置系统自动居中对齐
    ctx.font = 'bold 35px sans-serif' // 字体调大并加粗
    ctx.fillStyle = Colors.TEXT_SECONDARY
    ctx.textAlign = 'center'          // 水平居中
    ctx.textBaseline = 'middle'       // 垂直居中

    // 绘制轴线和文字标签
    for (let i = 0; i < sides; i++) {
      const x = centerX + radius * Math.sin(i * angle)
      const y = centerY - radius * Math.cos(i * angle)
      ctx.beginPath()
      ctx.moveTo(centerX, centerY)
      ctx.lineTo(x, y)
      ctx.strokeStyle = '#E5E7EB'
      ctx.stroke()

      // 标签文字偏移 (距离外圈 25 像素)
      const textRadius = radius + 15
      const textX = centerX + textRadius * Math.sin(i * angle)
      const textY = centerY - textRadius * Math.cos(i * angle)

      // 直接渲染，不再使用粗暴的 -15 偏移，textAlign 会帮我们完美居中
      if (Math.abs(Math.sin(i * angle)) < 0.1) {
        ctx.textAlign = 'center' // 上下顶点居中
      } else if (Math.sin(i * angle) > 0) {
        ctx.textAlign = 'left'   // 右半边的字，向右延伸
      } else {
        ctx.textAlign = 'right'  // 左半边的字，向左延伸
      }

      if (Math.abs(Math.cos(i * angle)) < 0.1) {
        ctx.textBaseline = 'middle' // 左右极点垂直居中
      } else if (Math.cos(i * angle) > 0) {
        ctx.textBaseline = 'bottom' // 上半边的字，向上延伸
      } else {
        ctx.textBaseline = 'top'    // 下半边的字，向下延伸
      }

      ctx.fillText(this.scores[i].tag, textX, textY)
    }

    // 绘制用户数据多边形
    ctx.beginPath()
    for (let i = 0; i < sides; i++) {
      const val = this.scores[i].score
      const r = radius * (val / 5)
      const x = centerX + r * Math.sin(i * angle)
      const y = centerY - r * Math.cos(i * angle)
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()
    ctx.fillStyle = Colors.PRIMARY + '40'
    ctx.fill()
    ctx.strokeStyle = Colors.PRIMARY
    ctx.lineWidth = 2
    ctx.stroke()
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.startIcon')).width(24).height(24).onClick(() => router.back())
        Text('我的心理画像').fontSize(18).fontWeight(FontWeight.Medium).margin({ left: 16 })
      }.width('100%').padding(24)

      Scroll() {
        Column() {
          // 雷达图卡片
          Column() {
            Text('多维状态评估')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
              .margin({ top: 16, left: 16 })
              .alignSelf(ItemAlign.Start)

            // 🌟 核心修复：等数据加载完毕再渲染 Canvas
            if (this.isLoading) {
              Column() {
                LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
              }
              .width(300)
              .height(300)
              .justifyContent(FlexAlign.Center)
            } else if (this.scores && this.scores.length > 0) {
              Canvas(this.canvasContext)
                .width(340) // 🌟 从 300 改为 340
                .height(340) // 🌟 从 300 改为 340
                .onReady(() => {
                  this.drawRadarChart()
                })
            } else {
              Column() {
                Text('暂无评估数据').fontColor(Colors.TEXT_SECONDARY)
              }
              .width(300)
              .height(300)
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('90%')
          .backgroundColor(Colors.CARD_BG)
          .borderRadius(16)
          .shadow({ radius: 4, color: '#0A000000', offsetY: 2 })
          .margin({ bottom: 20 })

          Column() {
            Row() {
              Text('✨').fontSize(20)
              Text('小饼干 AI 分析').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Colors.TEXT_PRIMARY).margin({ left: 8 })
            }.width('100%').margin({ bottom: 12 })

            if (this.isLoading) {
              Column() {
                LoadingProgress().width(40).height(40).color(Colors.PRIMARY)
                Text('AI 正在深度思考中...').fontSize(13).fontColor(Colors.TEXT_SECONDARY).margin({ top: 8 })
              }.width('100%').padding(40)
            } else {
              Text(this.aiPortraitText).fontSize(15).lineHeight(24).fontColor(Colors.TEXT_PRIMARY).width('100%')
            }
          }
          .width('90%').padding(20).backgroundColor(Colors.CARD_BG).borderRadius(16).shadow({ radius: 4, color: '#0A000000', offsetY: 2 }).margin({ bottom: 40 })

          Button('完成并返回主页')
            .width('80%').height(50).backgroundColor(Colors.PRIMARY)
            .onClick(() => {
              // 适配你提供的 RouterIndex 工具类
              RouterIndex.clearAndPush('features/student/pages/StudentHomePage')
            })
            .margin({ bottom: 40 })
        }.width('100%')
      }
      .scrollBar(BarState.Off).width('100%').layoutWeight(1)
    }.width('100%').height('100%').backgroundColor(Colors.BACKGROUND)
  }
}