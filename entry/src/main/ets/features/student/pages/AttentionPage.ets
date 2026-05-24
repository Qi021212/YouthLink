import { router, promptAction } from '@kit.ArkUI'
import { Colors } from '../../../common/constants/Colors'

@Entry
@Component
struct AttentionPage {
  @State isRunning: boolean = false
  @State isPaused: boolean = false
  @State elapsedSeconds: number = 0
  @State targetX: number = 180
  @State targetY: number = 360
  @State touchX: number = -100
  @State touchY: number = -100
  @State isTouching: boolean = false
  @State instantScore: number = 0
  @State currentSpeed: number = 1.5
  @State totalScore: number = 0
  @State hitFrames: number = 0
  @State totalFrames: number = 0
  @State comboCount: number = 0
  @State showTip: boolean = false
  @State tipText: string = ''
  @State difficultyLevel: number = 1
  @State sessionDuration: number = 120
  @State containerWidth: number = 360
  @State containerHeight: number = 640
  @State trailX1: number = 180
  @State trailY1: number = 360
  @State trailX2: number = 180
  @State trailY2: number = 360
  @State comboRingScale: number = 0
  @State comboRingOpacity: number = 0
  @State scoreBump: number = 1.0
  @State resumeCountdown: number = 0
  @State pauseFadeIn: boolean = false

  private timerId: number = -1
  private resumeTimerId: number = -1
  private targetRadius: number = 28
  private effectiveRadius: number = 40
  private timeOffset: number = 0
  private missFrameCount: number = 0
  private readonly TIP_THRESHOLD = 60
  private prevTargetX: number = 180
  private prevTargetY: number = 360
  private frameCounter: number = 0

  startExercise(): void {
    this.isRunning = true
    this.isPaused = false
    this.elapsedSeconds = 0
    this.totalScore = 0
    this.hitFrames = 0
    this.totalFrames = 0
    this.comboCount = 0
    this.instantScore = 0
    this.timeOffset = 0
    this.missFrameCount = 0
    this.frameCounter = 0
    this.currentSpeed = 1.2 + this.difficultyLevel * 0.4
    this.targetX = this.containerWidth / 2
    this.targetY = this.containerHeight / 2
    this.trailX1 = this.targetX
    this.trailY1 = this.targetY
    this.trailX2 = this.targetX
    this.trailY2 = this.targetY
    this.touchX = -100
    this.touchY = -100
    this.isTouching = false
    this.showTip = false
    this.comboRingScale = 0
    this.comboRingOpacity = 0
    this.scoreBump = 1.0

    this.timerId = setInterval(() => {
      this.onGameTick()
    }, 33)
  }

  pauseExercise(): void {
    if (this.isPaused) {
      this.startResumeCountdown()
    } else {
      this.isPaused = true
      this.pauseFadeIn = true
    }
  }

  startResumeCountdown(): void {
    this.resumeCountdown = 3
    if (this.resumeTimerId !== -1) {
      clearInterval(this.resumeTimerId)
    }
    this.resumeTimerId = setInterval(() => {
      this.resumeCountdown--
      if (this.resumeCountdown <= 0) {
        clearInterval(this.resumeTimerId)
        this.resumeTimerId = -1
        this.isPaused = false
        this.pauseFadeIn = false
      }
    }, 700)
  }

  handleStopClick(): void {
    AlertDialog.show({
      title: '结束练习',
      message: '确定要结束本次专注练习吗？当前进度将丢失。',
      confirm: {
        value: '确定结束',
        fontColor: Colors.ERROR,
        action: () => {
          clearInterval(this.timerId)
          this.timerId = -1
          if (this.resumeTimerId !== -1) {
            clearInterval(this.resumeTimerId)
            this.resumeTimerId = -1
          }
          this.isRunning = false
          this.isPaused = false
          this.pauseFadeIn = false
          this.resumeCountdown = 0
          this.isTouching = false
          this.showResult()
        }
      },
      cancel: () => {}
    })
  }

  onGameTick(): void {
    if (this.isPaused) return

    this.timeOffset += 0.033
    this.totalFrames++
    this.frameCounter++

    this.prevTargetX = this.targetX
    this.prevTargetY = this.targetY

    const margin = this.targetRadius + 20
    const w = this.containerWidth > 0 ? this.containerWidth : 360
    const h = this.containerHeight > 0 ? this.containerHeight : 640
    const centerX = w / 2
    const centerY = h / 2
    const amplitudeX = (w / 2 - margin) * 0.7
    const amplitudeY = (h / 2 - margin) * 0.7

    this.targetX = centerX + Math.sin(this.timeOffset * 0.8 * this.currentSpeed) * amplitudeX +
      Math.cos(this.timeOffset * 1.3 * this.currentSpeed) * amplitudeX * 0.3

    this.targetY = centerY + Math.cos(this.timeOffset * 0.7 * this.currentSpeed) * amplitudeY +
      Math.sin(this.timeOffset * 1.1 * this.currentSpeed) * amplitudeY * 0.3

    this.targetX = Math.max(margin, Math.min(w - margin, this.targetX))
    this.targetY = Math.max(margin, Math.min(h - margin, this.targetY))

    if (this.frameCounter % 3 === 0) {
      this.trailX2 = this.trailX1
      this.trailY2 = this.trailY1
      this.trailX1 = this.prevTargetX
      this.trailY1 = this.prevTargetY
    }

    if (this.isTouching && this.touchX > 0 && this.touchY > 0) {
      const dx = this.touchX - this.targetX
      const dy = this.touchY - this.targetY
      const distance = Math.sqrt(dx * dx + dy * dy)

      if (distance < this.effectiveRadius) {
        this.instantScore = Math.round(100 * (1 - distance / this.effectiveRadius))
        this.hitFrames++
        this.missFrameCount = 0
        this.comboCount++

        if (this.comboCount > 0 && this.comboCount % 30 === 0) {
          this.comboRingScale = 1.8
          this.comboRingOpacity = 0.7
        } else {
          this.comboRingScale = this.comboRingScale * 0.85
          this.comboRingOpacity = this.comboRingOpacity * 0.88
        }

        this.scoreBump = 1.15
        this.showTip = false
      } else {
        this.instantScore = 0
        this.missFrameCount++
        this.comboCount = 0
        this.comboRingScale = 0
        this.comboRingOpacity = 0
        if (this.missFrameCount > this.TIP_THRESHOLD) {
          this.showTip = true
          this.tipText = '放轻松，保持节奏，不要急'
        }
      }

      this.totalScore += this.instantScore
    } else {
      this.missFrameCount++
      this.comboRingScale = this.comboRingScale * 0.8
      this.comboRingOpacity = this.comboRingOpacity * 0.85
      if (this.missFrameCount > this.TIP_THRESHOLD * 3) {
        this.showTip = true
        this.tipText = '请在屏幕上按住并跟随圆圈移动'
      }
    }

    this.scoreBump += (1.0 - this.scoreBump) * 0.3

    if (this.hitFrames > 0 && this.hitFrames % 300 === 0) {
      this.currentSpeed = Math.min(4.0, this.currentSpeed * 1.03)
    }

    this.elapsedSeconds = Math.floor(this.timeOffset)

    if (this.elapsedSeconds >= this.sessionDuration) {
      clearInterval(this.timerId)
      this.timerId = -1
      if (this.resumeTimerId !== -1) {
        clearInterval(this.resumeTimerId)
        this.resumeTimerId = -1
      }
      this.isRunning = false
      this.isPaused = false
      this.pauseFadeIn = false
      this.resumeCountdown = 0
      this.isTouching = false
      this.showResult()
    }
  }

  getTargetColor(): string {
    if (this.instantScore >= 80) return Colors.SUCCESS
    if (this.instantScore >= 40) return Colors.WARNING
    return Colors.ERROR
  }

  getAverageScore(): number {
    if (this.totalFrames === 0) return 0
    return Math.round(this.totalScore / this.totalFrames)
  }

  getAccuracy(): number {
    if (this.totalFrames === 0) return 0
    return Math.round((this.hitFrames / this.totalFrames) * 100)
  }

  getFinalScore(): number {
    const avgScore = this.getAverageScore()
    const accuracy = this.getAccuracy()
    const stabilityBonus = Math.min(20, this.comboCount > 50 ? 20 : this.comboCount * 0.4)
    return Math.min(1000, Math.round(avgScore * 6 + accuracy * 3 + stabilityBonus))
  }

  getProgressPercent(): number {
    return Math.min(100, Math.round((this.elapsedSeconds / this.sessionDuration) * 100))
  }

  showResult(): void {
    if (this.elapsedSeconds < 60) {
      promptAction.showToast({ message: '练习不足60秒，不计入记录', duration: 2500 })
      return
    }
    const finalScore = this.getFinalScore()
    const accuracy = this.getAccuracy()
    const avgScore = this.getAverageScore()
    AlertDialog.show({
      title: '专注练习完成',
      message: `专注得分: ${finalScore} 分\n命中率: ${accuracy}%\n平均专注度: ${avgScore}%\n最大连击: ${this.comboCount}`,
      confirm: {
        value: '返回',
        action: () => {
          router.back()
        }
      },
      cancel: () => {}
    })
  }

  formatTime(seconds: number): string {
    const min = Math.floor(seconds / 60)
    const sec = seconds % 60
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
    if (this.resumeTimerId !== -1) {
      clearInterval(this.resumeTimerId)
    }
  }

  build() {
    Column() {
      this.buildTopBar()

      Stack() {
        if (!this.isRunning) {
          this.buildStartView()
        } else {
          this.buildActiveView()
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND)
  }

  @Builder
  buildTopBar() {
    Row() {
      Text('← 返回')
        .fontSize(15)
        .fontColor(Colors.PRIMARY)
        .onClick(() => {
          if (this.isRunning) {
            this.handleStopClick()
          } else {
            router.back()
          }
        })

      Blank()

      Text('专注追踪')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Blank()

      Text(`难度 ${this.difficultyLevel}`)
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .onClick(() => {
          this.difficultyLevel = this.difficultyLevel === 3 ? 1 : this.difficultyLevel + 1
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Colors.CARD_BG)
  }

  @Builder
  buildStartView() {
    Column() {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 56, height: 56 })
            .fill(Colors.MORANDI_BLUE + '30')
            .stroke(Colors.MORANDI_BLUE)
            .strokeWidth(3)
            .animation({ duration: 2000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })

          Text('👆')
            .fontSize(28)
        }

        Text('手指跟随移动的圆圈')
          .fontSize(15)
          .fontColor(Colors.TEXT_SECONDARY)
          .margin({ top: 24 })
      }
      .margin({ top: 80 })

      Text('专注追踪')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ top: 60 })

      Text('将手指保持在移动圆圈上\n保持专注力，提升注意力')
        .fontSize(14)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ top: 12 })

      Column() {
        Text(`难度: ${this.difficultyLevel === 1 ? '初级' : this.difficultyLevel === 2 ? '中级' : '高级'}`)
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)

        Row() {
          ForEach([1, 2, 3], (level: number) => {
            Circle({ width: 16, height: 16 })
              .fill(level <= this.difficultyLevel ? Colors.PRIMARY : Colors.DIVIDER)
              .margin({ left: 6 })
              .onClick(() => {
                this.difficultyLevel = level
              })
          })
        }
        .margin({ top: 10 })

        Text(`时长: ${this.sessionDuration / 60} 分钟`)
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)
          .margin({ top: 20 })

        Slider({
          value: this.sessionDuration,
          min: 60,
          max: 300,
          step: 30,
          style: SliderStyle.InSet
        })
          .width(200)
          .trackColor(Colors.MORANDI_GRAY)
          .selectedColor(Colors.PRIMARY)
          .onChange((value: number) => {
            this.sessionDuration = value
          })
      }
      .margin({ top: 30 })

      Button('开始练习')
        .width(200)
        .height(48)
        .fontSize(16)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .backgroundColor(Colors.PRIMARY)
        .borderRadius(24)
        .shadow({ radius: 8, color: Colors.PRIMARY + '40', offsetY: 4 })
        .margin({ top: 40 })
        .onClick(() => {
          this.startExercise()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildActiveView() {
    Column() {
      Row() {
        Column() {
          Text('专注度')
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
          Text(`${this.instantScore}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTargetColor())
            .scale({ x: this.scoreBump, y: this.scoreBump })
        }
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text('时间')
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
          Text(this.formatTime(this.elapsedSeconds))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column() {
          Text('连击')
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
          Text(`${this.comboCount}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.comboCount > 50 ? Colors.SUCCESS : Colors.PRIMARY)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 12 })

      Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
        .width('90%')
        .height(3)
        .color(Colors.PRIMARY)
        .backgroundColor(Colors.DIVIDER)
        .margin({ top: 8, bottom: 4 })

      Stack() {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor(Colors.CARD_BG + '80')
          .borderRadius(16)
          .border({ width: 1, color: Colors.DIVIDER })
          .margin({ left: 12, right: 12 })
          .onAreaChange((oldArea: Area, newArea: Area) => {
            this.containerWidth = newArea.width as number
            this.containerHeight = newArea.height as number
          })
          .onTouch((event: TouchEvent) => {
            if (!this.isPaused) {
              if (event.type === TouchType.Down || event.type === TouchType.Move) {
                const touch = event.touches[0]
                this.touchX = touch.x
                this.touchY = touch.y
                this.isTouching = true
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.isTouching = false
                this.touchX = -100
                this.touchY = -100
              }
            }
          })

        Circle({ width: 14, height: 14 })
          .fill(this.getTargetColor() + '15')
          .stroke(this.getTargetColor() + '35')
          .strokeWidth(1)
          .position({ x: this.trailX2 - 7, y: this.trailY2 - 7 })

        Circle({ width: 20, height: 20 })
          .fill(this.getTargetColor() + '22')
          .stroke(this.getTargetColor() + '50')
          .strokeWidth(1.5)
          .position({ x: this.trailX1 - 10, y: this.trailY1 - 10 })

        if (this.comboRingScale > 0.05) {
          Circle({ width: this.targetRadius * 2, height: this.targetRadius * 2 })
            .fill(Color.Transparent)
            .stroke(Colors.SUCCESS)
            .strokeWidth(2)
            .position({ x: this.targetX - this.targetRadius, y: this.targetY - this.targetRadius })
            .scale({ x: this.comboRingScale, y: this.comboRingScale })
            .opacity(this.comboRingOpacity * 0.5)
        }

        if (this.isTouching && this.touchX > 0) {
          Circle({ width: 24, height: 24 })
            .fill(this.getTargetColor() + '50')
            .stroke(this.getTargetColor())
            .strokeWidth(2)
            .position({ x: this.touchX - 12, y: this.touchY - 12 })
            .scale({ x: this.scoreBump, y: this.scoreBump })
        }

        Circle({ width: this.targetRadius * 2, height: this.targetRadius * 2 })
          .fill(this.getTargetColor() + '35')
          .stroke(this.getTargetColor())
          .strokeWidth(3)
          .position({ x: this.targetX - this.targetRadius, y: this.targetY - this.targetRadius })

        Circle({ width: 8, height: 8 })
          .fill(Colors.TEXT_ON_PRIMARY)
          .stroke(this.getTargetColor())
          .strokeWidth(1)
          .position({ x: this.targetX - 4, y: this.targetY - 4 })

        if (this.showTip && !this.isPaused) {
          Text(this.tipText)
            .fontSize(14)
            .fontColor(Colors.WARNING)
            .padding(12)
            .backgroundColor(Colors.WARNING + '15')
            .borderRadius(8)
            .position({ x: '50%', y: 20 })
            .translate({ x: '-50%' })
        }

        if (this.isPaused) {
          Column() {
            if (this.resumeCountdown > 0) {
              Text(`${this.resumeCountdown}`)
                .fontSize(72)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.PRIMARY)
                .scale({ x: 1.15, y: 1.15 })
                .animation({ duration: 600, curve: Curve.EaseOut })

              Text('准备继续...')
                .fontSize(16)
                .fontColor(Colors.TEXT_SECONDARY)
                .margin({ top: 6 })
                .opacity(0.7)
            } else {
              Text('已暂停')
                .fontSize(26)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.TEXT_PRIMARY)

              Text('点击下方按钮继续练习')
                .fontSize(14)
                .fontColor(Colors.TEXT_HINT)
                .margin({ top: 8 })
                .opacity(0.8)
            }

            Row() {
              Button('继续练习')
                .width(130)
                .height(46)
                .fontSize(14)
                .fontColor(Colors.TEXT_ON_PRIMARY)
                .backgroundColor(Colors.PRIMARY)
                .borderRadius(23)
                .shadow({ radius: 6, color: Colors.PRIMARY + '50', offsetY: 3 })
                .onClick(() => {
                  this.pauseExercise()
                })

              Button('结束练习')
                .width(130)
                .height(46)
                .fontSize(14)
                .fontColor(Colors.TEXT_ON_PRIMARY)
                .backgroundColor(Colors.ERROR)
                .borderRadius(23)
                .shadow({ radius: 6, color: Colors.ERROR + '40', offsetY: 3 })
                .margin({ left: 16 })
                .onClick(() => {
                  this.handleStopClick()
                })
            }
            .margin({ top: 28 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor(Colors.OVERLAY)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(16)
          .margin({ left: 12, right: 12 })
          .opacity(this.pauseFadeIn ? 1 : 0)
          .animation({ duration: 300, curve: Curve.EaseIn })
        }

        if (!this.isPaused) {
          Row() {
            Button() {
              Row() {
                Text('⏸')
                  .fontSize(16)
                  .fontColor(Colors.TEXT_PRIMARY)
                Text(' 暂停')
                  .fontSize(13)
                  .fontColor(Colors.TEXT_PRIMARY)
              }
            }
            .width(90)
            .height(40)
            .backgroundColor(Colors.CARD_BG)
            .borderRadius(20)
            .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 2 })
            .onClick(() => {
              this.pauseExercise()
            })

            Button() {
              Row() {
                Text('⏹')
                  .fontSize(16)
                  .fontColor(Colors.TEXT_ON_PRIMARY)
                Text(' 结束')
                  .fontSize(13)
                  .fontColor(Colors.TEXT_ON_PRIMARY)
              }
            }
            .width(90)
            .height(40)
            .backgroundColor(Colors.ERROR)
            .borderRadius(20)
            .shadow({ radius: 6, color: Colors.ERROR + '40', offsetY: 2 })
            .margin({ left: 14 })
            .onClick(() => {
              this.handleStopClick()
            })
          }
          .position({ x: '50%', y: '92%' })
          .translate({ x: '-46%' })
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
