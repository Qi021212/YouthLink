import { router, promptAction } from '@kit.ArkUI'
import { vibrator } from '@kit.SensorServiceKit'
import { media } from '@kit.MediaKit'
import { Colors } from '../../../common/constants/Colors'
import { playBackgroundSound, stopAndReleasePlayer } from '../../../common/utils/AudioPlayerUtil'

enum BreathPhase {
  INHALE,
  HOLD,
  EXHALE
}

@Entry
@Component
struct BreathingPage {
  @State isRunning: boolean = false
  @State isPaused: boolean = false
  @State elapsedSeconds: number = 0
  @State scaleFactor: number = 0.35
  @State breathPhase: BreathPhase = BreathPhase.INHALE
  @State breathPhaseText: string = '准备开始'
  @State phaseTimeLeft: number = 0
  @State selectedModeIndex: number = 0
  @State selectedNoiseIndex: number = 0
  @State durationSetting: number = 120
  @State showSettings: boolean = false
  @State totalCycles: number = 0
  @State ringAngle: number = 0
  @State outerRingAlpha: number = 0.12
  @State midRingAlpha: number = 0.22
  @State phaseProgress: number = 0

  private timerId: number = -1
  private phaseStartTime: number = 0
  private phaseElapsed: number = 0
  private cycleCount: number = 0
  private lastVibratePhase: string = ''
  private bgPlayer: media.AVPlayer | null = null

  private noiseFileMap: string[] = ['bg_ocean.wav', 'bg_rain.wav', 'bg_meditation.wav', '']

  private modeNames: string[] = ['4-7-8', '1:1', '自定义']
  private noiseNames: string[] = ['海浪', '雨声', '冥想', '无声']
  private noiseIcons: string[] = ['🌊', '🌧', '🧘', '🔇']

  private get cycleDuration(): number {
    const mode = this.modeNames[this.selectedModeIndex]
    if (mode === '4-7-8') return 19000
    if (mode === '1:1') return 8000
    return 12000
  }

  private getInhaleDuration(): number {
    const mode = this.modeNames[this.selectedModeIndex]
    if (mode === '4-7-8') return 4000
    if (mode === '1:1') return 4000
    return 5000
  }

  private getHoldDuration(): number {
    const mode = this.modeNames[this.selectedModeIndex]
    if (mode === '4-7-8') return 7000
    if (mode === '1:1') return 0
    return 2000
  }

  private getExhaleDuration(): number {
    const mode = this.modeNames[this.selectedModeIndex]
    if (mode === '4-7-8') return 8000
    if (mode === '1:1') return 4000
    return 5000
  }

  startExercise(): void {
    this.isRunning = true
    this.isPaused = false
    this.elapsedSeconds = 0
    this.cycleCount = 0
    this.totalCycles = 0
    this.breathPhase = BreathPhase.INHALE
    this.breathPhaseText = '吸 气'
    this.scaleFactor = 0.35
    this.phaseProgress = 0
    this.ringAngle = 0
    this.lastVibratePhase = ''
    this.phaseStartTime = Date.now()
    this.phaseElapsed = 0

    this.timerId = setInterval(() => {
      this.onTimerTick()
    }, 50)

    this.startBgSound()
  }

  pauseExercise(): void {
    if (this.isPaused) {
      this.isPaused = false
      this.phaseStartTime = Date.now() - this.phaseElapsed
    } else {
      this.isPaused = true
      this.phaseElapsed = Date.now() - this.phaseStartTime
    }
  }

  stopExercise(): void {
    clearInterval(this.timerId)
    this.timerId = -1
    this.isRunning = false
    this.isPaused = false
    this.stopBgSound()
    this.showResult()
  }

  startBgSound(): void {
    let fileName = this.noiseFileMap[this.selectedNoiseIndex]
    if (fileName === '') {
      return
    }
    playBackgroundSound(this, fileName, true, this.bgPlayer).then((player: media.AVPlayer | null) => {
      if (player !== null) {
        this.bgPlayer = player
      }
    })
  }

  switchBgNoise(): void {
    if (!this.isRunning) {
      return
    }
    let fileName = this.noiseFileMap[this.selectedNoiseIndex]
    if (fileName === '') {
      stopAndReleasePlayer(this.bgPlayer).then((result: media.AVPlayer | null) => {
        this.bgPlayer = result
      })
      return
    }
    playBackgroundSound(this, fileName, true, this.bgPlayer).then((player: media.AVPlayer | null) => {
      if (player !== null) {
        this.bgPlayer = player
      }
    })
  }

  stopBgSound(): void {
    stopAndReleasePlayer(this.bgPlayer).then((result: media.AVPlayer | null) => {
      this.bgPlayer = result
    })
  }

  onTimerTick(): void {
    if (this.isPaused) return

    const now = Date.now()
    this.phaseElapsed = now - this.phaseStartTime

    const inhaleDur = this.getInhaleDuration()
    const holdDur = this.getHoldDuration()
    const exhaleDur = this.getExhaleDuration()
    const totalCycle = inhaleDur + holdDur + exhaleDur
    let cycleElapsed = this.phaseElapsed % totalCycle

    if (cycleElapsed < inhaleDur) {
      this.breathPhase = BreathPhase.INHALE
      this.breathPhaseText = '吸 气'
      const progress = cycleElapsed / inhaleDur
      this.scaleFactor = 0.35 + progress * 0.65
      this.phaseProgress = progress
      this.phaseTimeLeft = Math.ceil((inhaleDur - cycleElapsed) / 1000)
      if (this.lastVibratePhase !== 'INHALE_END' && this.phaseTimeLeft <= 1) {
        this.lastVibratePhase = 'INHALE_END'
        this.triggerPhaseVibrate()
      }
    } else if (cycleElapsed < inhaleDur + holdDur) {
      this.breathPhase = BreathPhase.HOLD
      this.breathPhaseText = '屏 息'
      this.scaleFactor = 1.0
      this.phaseProgress = 1.0
      this.phaseTimeLeft = Math.ceil((inhaleDur + holdDur - cycleElapsed) / 1000)
    } else {
      this.breathPhase = BreathPhase.EXHALE
      this.breathPhaseText = '呼 气'
      const exhaleElapsed = cycleElapsed - inhaleDur - holdDur
      const progress = exhaleElapsed / exhaleDur
      this.scaleFactor = 1.0 - progress * 0.65
      this.phaseProgress = 1.0 - progress
      this.phaseTimeLeft = Math.ceil((exhaleDur - exhaleElapsed) / 1000)
      if (this.lastVibratePhase !== 'EXHALE_END' && this.phaseTimeLeft <= 1) {
        this.lastVibratePhase = 'EXHALE_END'
      }
    }

    if (cycleElapsed < inhaleDur * 0.05 || (cycleElapsed >= inhaleDur + holdDur && cycleElapsed < inhaleDur + holdDur + exhaleDur * 0.05)) {
      if (this.lastVibratePhase !== 'PHASE_START') {
        this.lastVibratePhase = 'PHASE_START'
      }
    }

    const newCycle = Math.floor(this.phaseElapsed / totalCycle)
    if (newCycle > this.cycleCount) {
      this.cycleCount = newCycle
      this.totalCycles = this.cycleCount
      this.lastVibratePhase = ''
    }

    this.ringAngle = (cycleElapsed / totalCycle) * 360
    this.outerRingAlpha = 0.12 + Math.sin(this.phaseElapsed * 0.001) * 0.05
    this.midRingAlpha = 0.22 + Math.cos(this.phaseElapsed * 0.0007) * 0.06

    this.elapsedSeconds = Math.floor(this.phaseElapsed / 1000)

    if (this.elapsedSeconds >= this.durationSetting) {
      this.stopExercise()
    }
  }

  triggerPhaseVibrate(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 15 }, { usage: 'notification' })
    } catch (err) {
    }
  }

  getCircleColor(): string {
    switch (this.breathPhase) {
      case BreathPhase.INHALE:
        return Colors.BREATHING_INHALE
      case BreathPhase.HOLD:
        return Colors.BREATHING_HOLD
      case BreathPhase.EXHALE:
        return Colors.BREATHING_EXHALE
    }
  }

  getProgressPercent(): number {
    return Math.min(100, Math.round((this.elapsedSeconds / this.durationSetting) * 100))
  }

  showResult(): void {
    if (this.elapsedSeconds < 30) {
      promptAction.showToast({ message: '练习时长不足30秒，不计入记录', duration: 2500 })
      return
    }
    AlertDialog.show({
      title: '呼吸练习完成',
      message: `练习时长: ${this.formatTime(this.elapsedSeconds)}\n完成周期: ${this.totalCycles}次\n节奏稳定，身心放松`,
      confirm: {
        value: '返回',
        action: () => { router.back() }
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
    this.stopBgSound()
  }

  build() {
    Column() {
      this.buildTopBar()

      if (this.showSettings) {
        this.buildSettingsPanel()
      }

      Stack() {
        Column() {
          if (!this.isRunning) {
            this.buildStartView()
          } else {
            this.buildActiveView()
          }
        }
        .width('100%')
        .height('100%')
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
            this.stopExercise()
          } else {
            router.back()
          }
        })

      Blank()

      Text('沉浸式呼吸')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Blank()

      Text('设置')
        .fontSize(15)
        .fontColor(Colors.PRIMARY)
        .onClick(() => {
          this.showSettings = !this.showSettings
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Colors.CARD_BG)
  }

  @Builder
  buildSettingsPanel() {
    Column() {
      Text('背景音')
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.noiseNames, (name: string, index: number) => {
          Column() {
            Text(this.noiseIcons[index])
              .fontSize(24)
            Text(name)
              .fontSize(11)
              .fontColor(this.selectedNoiseIndex === index ? Colors.PRIMARY : Colors.TEXT_HINT)
              .margin({ top: 4 })
          }
          .width(60)
          .padding({ top: 8, bottom: 8 })
          .borderRadius(10)
          .backgroundColor(this.selectedNoiseIndex === index ? Colors.PRIMARY + '15' : Colors.SURFACE)
          .border({ width: 1.5, color: this.selectedNoiseIndex === index ? Colors.PRIMARY : Color.Transparent })
          .margin({ right: 10 })
          .onClick(() => {
            this.selectedNoiseIndex = index
            this.switchBgNoise()
          })
        })
      }

      Divider().margin({ top: 14, bottom: 14 }).color(Colors.DIVIDER)

      Text('呼吸模式')
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.modeNames, (name: string, index: number) => {
          Text(name)
            .fontSize(13)
            .fontColor(this.selectedModeIndex === index ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_SECONDARY)
            .padding({ left: 16, right: 16, top: 7, bottom: 7 })
            .borderRadius(14)
            .backgroundColor(this.selectedModeIndex === index ? Colors.PRIMARY : Colors.SURFACE)
            .margin({ right: 10 })
            .onClick(() => { this.selectedModeIndex = index })
        })
      }

      Divider().margin({ top: 14, bottom: 14 }).color(Colors.DIVIDER)

      Text(`练习时长: ${this.durationSetting / 60} 分钟`)
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ bottom: 8 })
        .alignSelf(ItemAlign.Start)

      Slider({
        value: this.durationSetting,
        min: 60,
        max: 600,
        step: 30,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor(Colors.MORANDI_GRAY)
        .selectedColor(Colors.PRIMARY)
        .onChange((value: number) => { this.durationSetting = value })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Colors.CARD_BG)
    .borderRadius({ bottomLeft: 16, bottomRight: 16 })
    .shadow({ radius: 6, color: Colors.SHADOW, offsetY: 3 })
  }

  @Builder
  buildStartView() {
    Column() {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: '100%', height: '100%' })
            .fill(Colors.BREATHING_INHALE + '10')
            .stroke(Colors.BREATHING_INHALE)
            .strokeWidth(1.5)

          Circle({ width: '55%', height: '55%' })
            .fill(Colors.BREATHING_INHALE + '18')
            .animation({ duration: 4000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })

          Circle({ width: '28%', height: '28%' })
            .fill(Colors.BREATHING_INHALE + '35')
            .animation({ duration: 3000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })
        }
        .width(200)
        .height(200)
      }
      .padding(20)

      Text('沉浸式呼吸')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ top: 30 })

      Text('跟随圆圈节奏，调整呼吸')
        .fontSize(14)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ top: 8 })

      Text(`模式: ${this.modeNames[this.selectedModeIndex]}  |  时长: ${this.durationSetting / 60}分钟`)
        .fontSize(12)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: 6 })

      Button('开始练习')
        .width(200)
        .height(48)
        .fontSize(16)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .backgroundColor(Colors.PRIMARY)
        .borderRadius(24)
        .margin({ top: 48 })
        .shadow({ radius: 8, color: Colors.PRIMARY + '40', offsetY: 4 })
        .onClick(() => { this.startExercise() })
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
        Text(this.formatTime(this.elapsedSeconds))
          .fontSize(14)
          .fontColor(Colors.TEXT_SECONDARY)
        Blank()
        Text(this.formatTime(this.durationSetting))
          .fontSize(14)
          .fontColor(Colors.TEXT_HINT)
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
        .width('90%')
        .height(3)
        .color(Colors.PRIMARY)
        .backgroundColor(Colors.DIVIDER)
        .margin({ top: 8, bottom: 32 })

      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: '100%', height: '100%' })
          .fill(this.getCircleColor() + '08')
          .stroke(this.getCircleColor() + '25')
          .strokeWidth(1.5)
          .scale({ x: this.scaleFactor + 0.15, y: this.scaleFactor + 0.15 })
          .opacity(this.outerRingAlpha * 8)

        Circle({ width: '80%', height: '80%' })
          .fill(this.getCircleColor() + '12')
          .stroke(this.getCircleColor() + '40')
          .strokeWidth(2)
          .scale({ x: this.scaleFactor + 0.07, y: this.scaleFactor + 0.07 })
          .opacity(this.midRingAlpha * 4.5)

        Circle({ width: '60%', height: '60%' })
          .fill(this.getCircleColor() + '15')
          .stroke(this.getCircleColor())
          .strokeWidth(3)
          .scale({ x: this.scaleFactor, y: this.scaleFactor })

        Column() {
          Text(this.phaseTimeLeft.toString())
            .fontSize(56)
            .fontWeight(FontWeight.Lighter)
            .fontColor(Colors.TEXT_PRIMARY)

          Text(this.breathPhaseText)
            .fontSize(22)
            .fontColor(this.getCircleColor())
            .fontWeight(FontWeight.Medium)
            .margin({ top: 6 })
        }
      }
      .width(260)
      .height(260)

      Text(`已完成 ${this.totalCycles} 个周期`)
        .fontSize(13)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: 36 })

      Row({ space: 24 }) {
        Button(this.isPaused ? '▶ 继续' : '⏸ 暂停')
          .width(130)
          .height(46)
          .fontSize(14)
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Colors.CARD_BG)
          .border({ width: 1.5, color: Colors.PRIMARY + '40' })
          .borderRadius(23)
          .onClick(() => { this.pauseExercise() })

        Button('⏹ 结束')
          .width(130)
          .height(46)
          .fontSize(14)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .backgroundColor(Colors.ERROR)
          .borderRadius(23)
          .shadow({ radius: 6, color: Colors.ERROR + '35', offsetY: 3 })
          .onClick(() => { this.stopExercise() })
      }
      .margin({ top: 44 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
