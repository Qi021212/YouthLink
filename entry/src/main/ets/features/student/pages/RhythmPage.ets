import { router, promptAction } from '@kit.ArkUI'
import { vibrator } from '@kit.SensorServiceKit'
import { media } from '@kit.MediaKit'
import { resourceManager } from '@kit.LocalizationKit'
import { common } from '@kit.AbilityKit'
import { Colors } from '../../../common/constants/Colors'
import { stopAndReleasePlayer } from '../../../common/utils/AudioPlayerUtil'

enum HitStatus {
  PERFECT,
  COOL,
  MISS,
  NONE
}

@Entry
@Component
struct RhythmPage {
  @State isRunning: boolean = false
  @State isPaused: boolean = false
  @State elapsedSeconds: number = 0
  @State baseBPM: number = 80
  @State energyLevel: number = 0
  @State comboCount: number = 0
  @State hitStatus: HitStatus = HitStatus.NONE
  @State hitText: string = ''
  @State pulseScale: number = 1.0
  @State pulseOpacity: number = 0.3
  @State sessionTime: number = 120
  @State isClosedEyes: boolean = false
  @State screenBrightness: number = 1.0
  @State showTip: boolean = false
  @State tipText: string = ''
  @State totalPerfect: number = 0
  @State totalCool: number = 0
  @State totalMiss: number = 0
  @State totalTaps: number = 0
  @State rippleScale: number = 0
  @State rippleOpacity: number = 0
  @State burstScale: number = 0
  @State burstOpacity: number = 0
  @State energyRingRotation: number = 0

  private timerId: number = -1
  private beatTimerId: number = -1
  private sessionStartTime: number = 0
  private lastBeatTime: number = 0
  private lastTapTime: number = 0
  private beatInterval: number = 750
  private readonly PERFECT_WINDOW = 75
  private readonly COOL_WINDOW = 150
  private readonly ANTI_SPAM_INTERVAL = 100
  private tipTimerId: number = -1
  private rippleAnimTimerId: number = -1
  private energyUpdateTimerId: number = -1
  private beatTickPlayer: media.AVPlayer | null = null
  private cachedTickFd: resourceManager.RawFileDescriptor | null = null
  private isFiringTick: boolean = false

  aboutToAppear(): void {
    this.updateBeatInterval()
  }

  updateBeatInterval(): void {
    this.beatInterval = Math.round(60000 / this.baseBPM)
  }

  startExercise(): void {
    this.isRunning = true
    this.isPaused = false
    this.elapsedSeconds = 0
    this.energyLevel = 0
    this.comboCount = 0
    this.hitStatus = HitStatus.NONE
    this.totalPerfect = 0
    this.totalCool = 0
    this.totalMiss = 0
    this.totalTaps = 0
    this.showTip = false
    this.rippleScale = 0
    this.rippleOpacity = 0
    this.burstScale = 0
    this.burstOpacity = 0
    this.energyRingRotation = 0
    this.sessionStartTime = Date.now()
    this.lastBeatTime = Date.now()
    this.updateBeatInterval()

    this.beatTimerId = setInterval(() => {
      this.onBeatTick()
    }, this.beatInterval)

    this.timerId = setInterval(() => {
      this.elapsedSeconds = Math.floor((Date.now() - this.sessionStartTime) / 1000)
      if (this.elapsedSeconds >= this.sessionTime) {
        this.stopExercise()
      }
    }, 500)

    this.energyUpdateTimerId = setInterval(() => {
      if (!this.isPaused) {
        this.energyRingRotation = (this.energyRingRotation + 1.5) % 360
        this.rippleScale += (0 - this.rippleScale) * 0.08
        this.rippleOpacity += (0 - this.rippleOpacity) * 0.08
        this.burstScale += (0 - this.burstScale) * 0.06
        this.burstOpacity += (0 - this.burstOpacity) * 0.06
      }
    }, 50)

    this.initBeatPlayer()
  }

  onBeatTick(): void {
    if (this.isPaused) return

    this.lastBeatTime = Date.now()
    this.triggerPulse()
    this.triggerVibration('LIGHT')
    this.rippleScale = 0.6
    this.rippleOpacity = 0.5
    this.fireTick()
  }

  triggerPulse(): void {
    this.pulseScale = 1.15
    this.pulseOpacity = 0.7
    setTimeout(() => {
      this.pulseScale = 1.0
      this.pulseOpacity = 0.3
    }, 100)
  }

  triggerVibration(intensity: string): void {
    try {
      if (intensity === 'STRONG') {
        vibrator.startVibration({ type: 'time', duration: 100 }, { usage: 'alarm' })
      } else {
        vibrator.startVibration({ type: 'time', duration: 30 }, { usage: 'notification' })
      }
    } catch (err) {
    }

    if (this.isClosedEyes && intensity === 'STRONG') {
      try {
        vibrator.startVibration({ type: 'time', duration: 150 }, { usage: 'alarm' })
      } catch (err) {
      }
    }
  }

  onTap(): void {
    if (!this.isRunning || this.isPaused) return

    const now = Date.now()

    if (now - this.lastTapTime < this.ANTI_SPAM_INTERVAL) {
      return
    }
    this.lastTapTime = now

    this.totalTaps++

    const offset = Math.abs(now - this.lastBeatTime)
    const nextBeatOffset = Math.abs(now - (this.lastBeatTime + this.beatInterval))
    const actualOffset = Math.min(offset, nextBeatOffset)

    if (actualOffset <= this.PERFECT_WINDOW) {
      this.hitStatus = HitStatus.PERFECT
      this.hitText = '完美!'
      this.comboCount++
      this.totalPerfect++
      this.energyLevel = Math.min(100, this.energyLevel + 3)
      this.triggerVibration('STRONG')
      this.rippleScale = 0.9
      this.rippleOpacity = 0.7
      this.burstScale = 1.5
      this.burstOpacity = 0.8
      this.showHitFeedback()
    } else if (actualOffset <= this.COOL_WINDOW) {
      this.hitStatus = HitStatus.COOL
      this.hitText = '不错'
      this.comboCount = 0
      this.totalCool++
      this.energyLevel = Math.min(100, this.energyLevel + 1)
      this.triggerVibration('LIGHT')
      this.rippleScale = 0.5
      this.rippleOpacity = 0.4
      this.showHitFeedback()
    } else {
      this.hitStatus = HitStatus.MISS
      this.hitText = ''
      this.comboCount = 0
      this.totalMiss++
      this.energyLevel = Math.max(0, this.energyLevel - 1.5)
      this.rippleScale = 0.2
      this.rippleOpacity = 0.15
      if (this.totalMiss > 10 && this.totalMiss % 10 === 0) {
        this.showTipMessage('重点是"允许"，不是"用力"')
      }
    }
  }

  showHitFeedback(): void {
    if (this.tipTimerId !== -1) {
      clearTimeout(this.tipTimerId)
    }
    this.tipTimerId = setTimeout(() => {
      this.hitStatus = HitStatus.NONE
    }, 600)
  }

  showTipMessage(msg: string): void {
    this.showTip = true
    this.tipText = msg
    setTimeout(() => {
      this.showTip = false
    }, 2500)
  }

  initBeatPlayer(): void {
    try {
      let context = getContext(this) as common.UIAbilityContext
      context.resourceManager.getRawFd('beat_tick.mp3').then((rawFd: resourceManager.RawFileDescriptor) => {
        this.cachedTickFd = rawFd
        media.createAVPlayer().then((player: media.AVPlayer) => {
          this.beatTickPlayer = player
          player.loop = false
          player.on('error', (err: Error) => {
            console.error('Rhythm beat player error: ' + err.message)
          })
        })
      })
    } catch (err) {
    }
  }

  async fireTick(): Promise<void> {
    const player = this.beatTickPlayer
    const fd = this.cachedTickFd
    if (!player || !fd || this.isFiringTick) {
      return
    }
    this.isFiringTick = true
    try {
      await player.stop()
      player.fdSrc = { fd: fd.fd, offset: fd.offset, length: fd.length }

      await new Promise<void>((resolve: () => void) => {
        player.on('stateChange', (state: media.AVPlayerState) => {
          if (state === 'prepared') {
            resolve()
          }
        })
      })

      await player.play()
    } catch (err) {
    } finally {
      this.isFiringTick = false
    }
  }

  releaseBeatPlayer(): void {
    stopAndReleasePlayer(this.beatTickPlayer).then((result: media.AVPlayer | null) => {
      this.beatTickPlayer = result
      this.cachedTickFd = null
    })
  }

  pauseExercise(): void {
    this.isPaused = !this.isPaused
  }

  stopExercise(): void {
    clearInterval(this.beatTimerId)
    clearInterval(this.timerId)
    clearInterval(this.energyUpdateTimerId)
    this.beatTimerId = -1
    this.timerId = -1
    this.energyUpdateTimerId = -1
    this.releaseBeatPlayer()
    this.isRunning = false
    this.isPaused = false
    this.showResult()
  }

  getEnergyColor(): string {
    if (this.energyLevel >= 70) return Colors.ENERGY_HIGH
    if (this.energyLevel >= 35) return Colors.ENERGY_MID
    return Colors.ENERGY_LOW
  }

  getTapAccuracy(): number {
    if (this.totalTaps === 0) return 0
    return Math.round(((this.totalPerfect + this.totalCool) / this.totalTaps) * 100)
  }

  getHitColor(): string {
    switch (this.hitStatus) {
      case HitStatus.PERFECT:
        return Colors.SUCCESS
      case HitStatus.COOL:
        return Colors.WARNING
      default:
        return Colors.TEXT_HINT
    }
  }

  getProgressPercent(): number {
    return Math.min(100, Math.round((this.elapsedSeconds / this.sessionTime) * 100))
  }

  showResult(): void {
    if (this.elapsedSeconds < 30) {
      promptAction.showToast({ message: '练习不足30秒，不计入记录', duration: 2500 })
      return
    }
    const accuracy = this.getTapAccuracy()
    const missRate = this.totalTaps > 0 ? Math.round((this.totalMiss / this.totalTaps) * 100) : 0

    if (missRate > 70) {
      promptAction.showToast({ message: '找个安静的地方，用触感再试一次', duration: 3000 })
      return
    }

    let evalText = '节律稳定，表现良好'
    if (accuracy >= 90) evalText = '节奏大师！节律极其稳定'
    else if (accuracy >= 70) evalText = '节律稳定，表现良好'
    else evalText = '继续练习，节奏会越来越好'

    AlertDialog.show({
      title: '节奏释放完成',
      message: `命中率: ${accuracy}%\n完美: ${this.totalPerfect} | 不错: ${this.totalCool} | 未中: ${this.totalMiss}\n最高能量: ${Math.round(this.energyLevel)}%\n\n${evalText}`,
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
    if (this.beatTimerId !== -1) clearInterval(this.beatTimerId)
    if (this.timerId !== -1) clearInterval(this.timerId)
    if (this.tipTimerId !== -1) clearTimeout(this.tipTimerId)
    if (this.rippleAnimTimerId !== -1) clearInterval(this.rippleAnimTimerId)
    if (this.energyUpdateTimerId !== -1) clearInterval(this.energyUpdateTimerId)
    this.releaseBeatPlayer()
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
    .backgroundColor(this.isClosedEyes && this.isRunning ? '#1A1A2E' : Colors.BACKGROUND)
  }

  @Builder
  buildTopBar() {
    Row() {
      Text('← 返回')
        .fontSize(15)
        .fontColor(Colors.PRIMARY)
        .onClick(() => {
          if (this.isRunning) {
            this.stopExercise()
          } else {
            router.back()
          }
        })

      Blank()

      Text('节律敲击')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isClosedEyes && this.isRunning ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)

      Blank()

      Text(this.isClosedEyes ? '睁眼' : '闭眼')
        .fontSize(13)
        .fontColor(Colors.PRIMARY)
        .onClick(() => {
          this.isClosedEyes = !this.isClosedEyes
          if (this.isClosedEyes) {
            this.screenBrightness = 0.3
          } else {
            this.screenBrightness = 1.0
          }
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isClosedEyes && this.isRunning ? '#1A1A2E' : Colors.CARD_BG)
  }

  @Builder
  buildStartView() {
    Column() {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 100, height: 100 })
            .fill(Colors.MORANDI_PURPLE + '25')
            .stroke(Colors.MORANDI_PURPLE)
            .strokeWidth(3)

          Circle({ width: 20, height: 20 })
            .fill(Colors.MORANDI_PURPLE + '60')
            .animation({ duration: this.beatInterval, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })
        }
        .width(120)
        .height(120)
      }

      Text('节律敲击释放')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ top: 40 })

      Text('跟随节奏轻点屏幕\n用触感释放负面能量')
        .fontSize(14)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .margin({ top: 12 })

      Column() {
        Text('节律速度 (BPM)')
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)

        Row() {
          Text('慢')
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
          Slider({
            value: this.baseBPM,
            min: 60,
            max: 120,
            step: 5,
            style: SliderStyle.InSet
          })
            .width(180)
            .trackColor(Colors.MORANDI_GRAY)
            .selectedColor(Colors.PRIMARY)
            .margin({ left: 10, right: 10 })
            .onChange((value: number) => {
              this.baseBPM = value
              this.updateBeatInterval()
            })
          Text('快')
            .fontSize(11)
            .fontColor(Colors.TEXT_HINT)
        }

        Text(`${this.baseBPM} BPM`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.PRIMARY)
          .margin({ top: 8 })
      }
      .margin({ top: 36 })

      Text(`时长: ${this.sessionTime / 60} 分钟`)
        .fontSize(13)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: 20 })

      Slider({
        value: this.sessionTime,
        min: 60,
        max: 300,
        step: 30,
        style: SliderStyle.InSet
      })
        .width(200)
        .trackColor(Colors.MORANDI_GRAY)
        .selectedColor(Colors.PRIMARY)
        .onChange((value: number) => {
          this.sessionTime = value
        })

      Button('开始敲击')
        .width(200)
        .height(48)
        .fontSize(16)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .backgroundColor(Colors.PRIMARY)
        .borderRadius(24)
        .shadow({ radius: 8, color: Colors.PRIMARY + '40', offsetY: 4 })
        .margin({ top: 36 })
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
    Stack() {
      Column() {
        Row() {
          Column() {
            Text('能量')
              .fontSize(11)
              .fontColor(Colors.TEXT_HINT)
            Text(`${Math.round(this.energyLevel)}%`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getEnergyColor())
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
              .fontColor(this.comboCount > 20 ? Colors.SUCCESS : Colors.PRIMARY)
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
          .margin({ top: 8 })

        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: '100%', height: '100%' })
            .fill(this.getEnergyColor() + '08')
            .stroke(this.getEnergyColor() + '25')
            .strokeWidth(1.5)
            .scale({ x: this.rippleScale + 0.5, y: this.rippleScale + 0.5 })
            .opacity(this.rippleOpacity)

          if (this.burstScale > 0.05) {
            Circle({ width: '60%', height: '60%' })
              .fill(Color.Transparent)
              .stroke(Colors.SUCCESS)
              .strokeWidth(3)
              .scale({ x: this.burstScale, y: this.burstScale })
              .opacity(this.burstOpacity)
          }

          Circle({ width: '85%', height: '85%' })
            .fill(this.getEnergyColor() + '12')
            .stroke(this.getEnergyColor() + '50')
            .strokeWidth(8)
            .scale({ x: this.pulseScale, y: this.pulseScale })

          Column() {
            Text(this.hitText)
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getHitColor())
              .opacity(this.hitStatus === HitStatus.NONE ? 0 : 1)
              .scale({
                x: this.hitStatus === HitStatus.PERFECT ? 1.25 : 1.0,
                y: this.hitStatus === HitStatus.PERFECT ? 1.25 : 1.0
              })
          }
        }
        .width(220)
        .height(220)
        .margin({ top: 24 })

        Row() {
          Column() {
            Text('完美')
              .fontSize(11)
              .fontColor(Colors.TEXT_HINT)
            Text(`${this.totalPerfect}`)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.SUCCESS)
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          Column() {
            Text('不错')
              .fontSize(11)
              .fontColor(Colors.TEXT_HINT)
            Text(`${this.totalCool}`)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.WARNING)
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)

          Column() {
            Text('未中')
              .fontSize(11)
              .fontColor(Colors.TEXT_HINT)
            Text(`${this.totalMiss}`)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.ERROR)
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .margin({ top: 28 })

        Text('跟随节律脉冲，轻点屏幕任意位置')
          .fontSize(13)
          .fontColor(Colors.TEXT_HINT)
          .margin({ top: 18 })

        if (this.showTip) {
          Text(this.tipText)
            .fontSize(13)
            .fontColor(Colors.WARNING)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(Colors.WARNING + '15')
            .borderRadius(8)
            .margin({ top: 12 })
        }

        Row({ space: 20 }) {
          Button(this.isPaused ? '▶ 继续' : '⏸ 暂停')
            .width(130)
            .height(44)
            .fontSize(14)
            .fontColor(Colors.PRIMARY)
            .backgroundColor(Colors.CARD_BG)
            .border({ width: 1.5, color: Colors.PRIMARY + '40' })
            .borderRadius(22)
            .onClick(() => {
              this.pauseExercise()
            })

          Button('⏹ 结束')
            .width(130)
            .height(44)
            .fontSize(14)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.ERROR)
            .borderRadius(22)
            .shadow({ radius: 6, color: Colors.ERROR + '35', offsetY: 3 })
            .onClick(() => {
              this.stopExercise()
            })
        }
        .margin({ top: 22 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.onTap()
      })

      if (this.isPaused) {
        Column() {
          Text('已暂停')
            .fontSize(20)
            .fontColor(Colors.TEXT_PRIMARY)
          Button('继续练习')
            .width(160)
            .height(44)
            .fontSize(14)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.PRIMARY)
            .borderRadius(22)
            .margin({ top: 20 })
            .onClick(() => {
              this.pauseExercise()
            })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.OVERLAY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
