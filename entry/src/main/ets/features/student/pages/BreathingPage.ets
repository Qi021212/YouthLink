import { router, promptAction } from '@kit.ArkUI'
import { vibrator } from '@kit.SensorServiceKit'
import { media } from '@kit.MediaKit'
import { Colors } from '../../../common/constants/Colors'
import { playBackgroundSound, stopAndReleasePlayer, testAudioPlayback } from '../../../common/utils/AudioPlayerUtil'

enum BreathPhase {
  INHALE,
  HOLD,
  EXHALE
}

@Entry
@Component
struct BreathingPage {
  // --- 练习状态 ---
  @State isRunning: boolean = false
  @State isPaused: boolean = false
  @State elapsedSeconds: number = 0
  @State scaleFactor: number = 0.4
  @State breathPhase: BreathPhase = BreathPhase.INHALE
  @State breathPhaseText: string = '准备开始'
  @State phaseTimeLeft: number = 0
  @State phaseProgressPct: number = 0
  @State totalCycles: number = 0
  @State breathColor: string = '#7EC8E3'

  // --- 设置 ---
  @State selectedModeIndex: number = 0
  @State selectedNoiseIndex: number = 0
  @State durationSetting: number = 120
  @State showSettings: boolean = false

  // --- 倒计时 ---
  @State countdownActive: boolean = false
  @State countdownValue: number = 3
  @State countdownScale: number = 0.2
  @State countdownRingScale: number = 0.5

  // --- 私有 ---
  private timerId: number = -1
  private phaseStartTime: number = 0
  private phaseElapsed: number = 0
  private cycleCount: number = 0
  private lastVibratePhase: string = ''
  private bgPlayer: media.AVPlayer | null = null
  private prevPhase: BreathPhase = BreathPhase.INHALE
  private colorTransitionStart: number = 0

  private noiseFileMap: string[] = ['bg_ocean.mp3', 'bg_rain.mp3', 'bg_meditation.mp3', '']
  private modeNames: string[] = ['4-7-8', '1:1', '自定义']
  private modeDisplayNames: string[] = ['4-7-8', '1:1', '自定义', '说明']
  private noiseNames: string[] = ['海浪', '雨声', '冥想', '无声']
  private noiseIcons: string[] = ['🌊', '🌧', '🧘', '🔇']

  private inhaleColor: string = '#6DC5E0'
  private holdColor: string = '#A8C8E8'
  private exhaleColor: string = '#8ECCB8'

  // ======================== 辅助方法 ========================

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

  private getPhaseColor(target: BreathPhase): string {
    switch (target) {
      case BreathPhase.INHALE:
        return this.inhaleColor
      case BreathPhase.HOLD:
        return this.holdColor
      case BreathPhase.EXHALE:
        return this.exhaleColor
    }
  }

  private blendHexColor(from: string, to: string, ratio: number): string {
    const r1: number = parseInt(from.slice(1, 3), 16)
    const g1: number = parseInt(from.slice(3, 5), 16)
    const b1: number = parseInt(from.slice(5, 7), 16)
    const r2: number = parseInt(to.slice(1, 3), 16)
    const g2: number = parseInt(to.slice(3, 5), 16)
    const b2: number = parseInt(to.slice(5, 7), 16)
    const r: number = Math.round(r1 + (r2 - r1) * ratio)
    const g: number = Math.round(g1 + (g2 - g1) * ratio)
    const b: number = Math.round(b1 + (b2 - b1) * ratio)
    return '#' + r.toString(16).padStart(2, '0') + g.toString(16).padStart(2, '0') + b.toString(16).padStart(2, '0')
  }

  private getProgressPercent(): number {
    return Math.min(100, Math.round((this.elapsedSeconds / this.durationSetting) * 100))
  }

  // ======================== 控制流程 ========================

  startExercise(): void {
    this.elapsedSeconds = 0
    this.isPaused = false
    this.lastVibratePhase = ''
    this.prevPhase = BreathPhase.INHALE
    this.colorTransitionStart = 0
    this.showSettings = false

    this.countdownActive = true
    this.countdownValue = 3
    this.countdownScale = 0.2
    this.countdownRingScale = 0.5

    animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
      this.countdownScale = 1.0
      this.countdownRingScale = 1.0
    })

    let countVal: number = 3
    const countTimer: number = setInterval(() => {
      countVal--
      if (countVal <= 0) {
        clearInterval(countTimer)
        this.countdownActive = false
        this.beginExerciseCore()
        return
      }
      this.countdownValue = countVal
      this.countdownScale = 0.2
      this.countdownRingScale = 0.5
      animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
        this.countdownScale = 1.0
        this.countdownRingScale = 1.0
      })
    }, 900)
  }

  private beginExerciseCore(): void {
    this.isRunning = true
    this.cycleCount = 0
    this.totalCycles = 0
    this.breathPhase = BreathPhase.INHALE
    this.breathPhaseText = '吸 气'
    this.breathColor = this.inhaleColor
    this.scaleFactor = 0.4
    this.phaseProgressPct = 0
    this.phaseStartTime = Date.now()
    this.phaseElapsed = 0

    this.timerId = setInterval(() => {
      this.onTimerTick()
    }, 40)

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

  // ======================== 音频 ========================

  startBgSound(): void {
    const fileName: string = this.noiseFileMap[this.selectedNoiseIndex]
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
    const fileName: string = this.noiseFileMap[this.selectedNoiseIndex]
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

  async testAudio(): Promise<void> {
    const result = await testAudioPlayback(this)
    if (result.success) {
      promptAction.showToast({ message: '音频播放正常', duration: 2000 })
    } else {
      promptAction.showToast({ message: result.error, duration: 3000 })
    }
  }

  // ======================== 核心计时逻辑 ========================

  onTimerTick(): void {
    if (this.isPaused) return

    const now: number = Date.now()
    this.phaseElapsed = now - this.phaseStartTime

    const inhaleDur: number = this.getInhaleDuration()
    const holdDur: number = this.getHoldDuration()
    const exhaleDur: number = this.getExhaleDuration()
    const totalCycle: number = inhaleDur + holdDur + exhaleDur
    const cycleElapsed: number = this.phaseElapsed % totalCycle

    let newPhase: BreathPhase
    let newText: string
    let newProgress: number

    if (cycleElapsed < inhaleDur) {
      newPhase = BreathPhase.INHALE
      newText = '吸气'
      newProgress = cycleElapsed / inhaleDur
      this.scaleFactor = 0.4 + newProgress * 0.6
      this.phaseTimeLeft = Math.ceil((inhaleDur - cycleElapsed) / 1000)
      if (this.lastVibratePhase !== 'INHALE_END' && this.phaseTimeLeft <= 1) {
        this.lastVibratePhase = 'INHALE_END'
        this.triggerPhaseVibrate()
      }
    } else if (cycleElapsed < inhaleDur + holdDur) {
      newPhase = BreathPhase.HOLD
      newText = '屏息'
      newProgress = 1.0
      this.scaleFactor = 1.0
      this.phaseTimeLeft = Math.ceil((inhaleDur + holdDur - cycleElapsed) / 1000)
    } else {
      newPhase = BreathPhase.EXHALE
      newText = '呼气'
      const exhaleElapsed: number = cycleElapsed - inhaleDur - holdDur
      newProgress = 1.0 - exhaleElapsed / exhaleDur
      this.scaleFactor = 1.0 - (exhaleElapsed / exhaleDur) * 0.6
      this.phaseTimeLeft = Math.ceil((exhaleDur - exhaleElapsed) / 1000)
      if (this.lastVibratePhase !== 'EXHALE_END' && this.phaseTimeLeft <= 1) {
        this.lastVibratePhase = 'EXHALE_END'
      }
    }

    if (newPhase !== this.prevPhase) {
      this.prevPhase = newPhase
      this.colorTransitionStart = this.phaseElapsed
    }
    const transitionMs: number = 800
    const elapsedInTransition: number = this.phaseElapsed - this.colorTransitionStart
    const blendRatio: number = Math.min(1.0, elapsedInTransition / transitionMs)
    const fromColor: string = this.breathColor
    const toColor: string = this.getPhaseColor(newPhase)
    if (blendRatio < 1.0) {
      this.breathColor = this.blendHexColor(fromColor, toColor, blendRatio)
    } else {
      this.breathColor = toColor
    }

    this.breathPhase = newPhase
    this.breathPhaseText = newText
    this.phaseProgressPct = Math.round(newProgress * 100)

    this.elapsedSeconds = Math.floor(this.phaseElapsed / 1000)

    const newCycle: number = Math.floor(this.phaseElapsed / totalCycle)
    if (newCycle > this.cycleCount) {
      this.cycleCount = newCycle
      this.totalCycles = this.cycleCount
      this.lastVibratePhase = ''
    }

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
    const min: number = Math.floor(seconds / 60)
    const sec: number = seconds % 60
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
    this.stopBgSound()
  }

  // ======================== 构建 ========================

  build() {
    Column() {
      this.buildTopBar()

      if (this.showSettings) {
        this.buildSettingsPanel()
      }

      Stack() {
        Column() {
          if (!this.isRunning && !this.countdownActive) {
            this.buildStartView()
          } else {
            this.buildActiveView()
          }
        }
        .width('100%')
        .height('100%')

        if (this.countdownActive) {
          this.buildCountdownOverlay()
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F5F8')
  }

  // ======================== 顶栏 ========================

  @Builder
  buildTopBar() {
    Row() {
      Text('←')
        .fontSize(20)
        .fontColor(Colors.TEXT_SECONDARY)
        .width(40)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.isRunning) {
            this.stopExercise()
          } else {
            router.back()
          }
        })

      Blank()

      Text('沉浸式呼吸')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Blank()

      Text(this.showSettings ? '确认' : '设置')
        .fontSize(15)
        .fontColor(Colors.PRIMARY)
        .fontWeight(FontWeight.Medium)
        .width(40)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showSettings = !this.showSettings
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.Transparent)
  }

  // ======================== 倒计时覆盖层 ========================

  @Builder
  buildCountdownOverlay() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: '100%', height: '100%' })
          .fill(Color.Transparent)
          .stroke(this.inhaleColor + '30')
          .strokeWidth(3)
          .scale({ x: this.countdownRingScale, y: this.countdownRingScale })
          .opacity(0.6)

        Circle({ width: '60%', height: '60%' })
          .fill(this.inhaleColor + '10')

        Text(this.countdownValue.toString())
          .fontSize(96)
          .fontWeight(FontWeight.Lighter)
          .fontColor(this.inhaleColor)
      }
      .width(180)
      .height(180)

      Text(this.countdownValue === 3 ? '深呼吸，放松身体' :
        this.countdownValue === 2 ? '让肩膀自然下沉' : '跟随节奏呼吸')
        .fontSize(14)
        .fontColor('#8899AA')
        .margin({ top: 32 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F2F5F8')
  }

  // ======================== 设置面板 ========================

  @Builder
  buildSettingsPanel() {
    Column() {
      Text('背景音')
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ bottom: 10 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.noiseNames, (name: string, index: number) => {
          Column() {
            Text(this.noiseIcons[index])
              .fontSize(22)
            Text(name)
              .fontSize(11)
              .fontColor(this.selectedNoiseIndex === index ? Colors.PRIMARY : Colors.TEXT_HINT)
              .margin({ top: 4 })
          }
          .width(58)
          .padding({ top: 10, bottom: 10 })
          .borderRadius(12)
          .backgroundColor(this.selectedNoiseIndex === index ? Colors.PRIMARY + '12' : '#F5F7FA')
          .margin({ right: 8 })
          .onClick(() => {
            this.selectedNoiseIndex = index
            this.switchBgNoise()
          })
        })
      }

      Divider().margin({ top: 16, bottom: 16 }).color(Colors.DIVIDER)

      Text('呼吸模式')
        .fontSize(13)
        .fontColor(Colors.TEXT_SECONDARY)
        .margin({ bottom: 10 })
        .alignSelf(ItemAlign.Start)

      Row() {
        ForEach(this.modeDisplayNames, (name: string, index: number) => {
          Text(name)
            .fontSize(13)
            .fontColor(index < 3 ?
              (this.selectedModeIndex === index ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_SECONDARY) :
              Colors.TEXT_HINT)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(16)
            .backgroundColor(index < 3 ?
              (this.selectedModeIndex === index ? Colors.PRIMARY : '#F5F7FA') :
              Color.Transparent)
            .margin({ right: 8 })
            .onClick(() => {
              if (index < 3) {
                this.selectedModeIndex = index
              }
            })
        })
      }

      Divider().margin({ top: 16, bottom: 16 }).color(Colors.DIVIDER)

      Row() {
        Text('练习时长')
          .fontSize(13)
          .fontColor(Colors.TEXT_SECONDARY)

        Blank()

        Text(`${this.durationSetting / 60} 分钟`)
          .fontSize(13)
          .fontColor(Colors.PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 6 })

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

      Divider().margin({ top: 16, bottom: 16 }).color(Colors.DIVIDER)

      Row() {
        Text('音频测试')
          .fontSize(13)
          .fontColor(Colors.TEXT_SECONDARY)

        Blank()

        Text('点击测试')
          .fontSize(13)
          .fontColor(Colors.PRIMARY)
          .onClick(() => {
            this.testAudio()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 20 })
    .backgroundColor(Colors.CARD_BG)
    .borderRadius({ bottomLeft: 20, bottomRight: 20 })
    .shadow({ radius: 8, color: '#00000010', offsetY: 4 })
  }

  // ======================== 启动页 ========================

  @Builder
  buildStartView() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        // 外层光晕
        Circle({ width: '100%', height: '100%' })
          .fill(this.inhaleColor + '08')
          .stroke(this.inhaleColor + '15')
          .strokeWidth(2)
          .animation({ duration: 4000, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })

        // 中层
        Circle({ width: '72%', height: '72%' })
          .fill(this.inhaleColor + '14')
          .animation({ duration: 3200, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })

        // 内层
        Circle({ width: '50%', height: '50%' })
          .fill(this.inhaleColor + '25')
          .stroke(this.inhaleColor + '60')
          .strokeWidth(2.5)
          .animation({ duration: 2600, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.AlternateReverse })

        Text('🧘')
          .fontSize(44)
      }
      .width(240)
      .height(240)

      Text('沉浸式呼吸')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ top: 40 })

      Text('跟随圆圈的起伏 · 调节你的呼吸节奏')
        .fontSize(14)
        .fontColor('#8899AA')
        .margin({ top: 12 })

      Row({ space: 10 }) {
        Text(this.modeNames[this.selectedModeIndex])
          .fontSize(12)
          .fontColor('#8899AA')
          .padding({ left: 14, right: 14, top: 5, bottom: 5 })
          .borderRadius(12)
          .backgroundColor('#F0F3F6')
          .border({ width: 1, color: '#E0E4E8' })

        Text(`${this.durationSetting / 60} 分钟`)
          .fontSize(12)
          .fontColor('#8899AA')
          .padding({ left: 14, right: 14, top: 5, bottom: 5 })
          .borderRadius(12)
          .backgroundColor('#F0F3F6')
          .border({ width: 1, color: '#E0E4E8' })
      }
      .margin({ top: 20 })

      Button('开始练习')
        .width(200)
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor(this.inhaleColor)
        .borderRadius(25)
        .margin({ top: 56 })
        .shadow({ radius: 12, color: this.inhaleColor + '40', offsetY: 6 })
        .onClick(() => { this.startExercise() })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ======================== 练习活跃页 ========================

  @Builder
  buildActiveView() {
    Column() {
      // 时间条
      Row() {
        Text(this.formatTime(this.elapsedSeconds))
          .fontSize(12)
          .fontColor('#8899AA')
        Blank()
        Text(this.formatTime(this.durationSetting))
          .fontSize(12)
          .fontColor('#BCC4CC')
      }
      .width('100%')
      .padding({ left: 36, right: 36 })

      Progress({ value: this.getProgressPercent(), total: 100, type: ProgressType.Linear })
        .width('86%')
        .height(2)
        .color(this.breathColor)
        .backgroundColor('#E8ECF0')
        .margin({ top: 8, bottom: 48 })

      // 呼吸圆
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: '100%', height: '100%' })
          .fill(this.breathColor + '0A')
          .scale({ x: this.scaleFactor + 0.22, y: this.scaleFactor + 0.22 })

        Circle({ width: '88%', height: '88%' })
          .fill(Color.Transparent)
          .stroke(this.breathColor + '18')
          .strokeWidth(1.5)
          .scale({ x: this.scaleFactor + 0.12, y: this.scaleFactor + 0.12 })

        Circle({ width: '78%', height: '78%' })
          .fill(this.breathColor + '10')
          .stroke(this.breathColor + '30')
          .strokeWidth(2)
          .scale({ x: this.scaleFactor + 0.05, y: this.scaleFactor + 0.05 })

        Circle({ width: '72%', height: '72%' })
          .fill(this.breathColor + '15')
          .stroke(this.breathColor)
          .strokeWidth(3)
          .scale({ x: this.scaleFactor, y: this.scaleFactor })

        // 中心内容
        Column() {
          Text(this.phaseTimeLeft.toString())
            .fontSize(64)
            .fontWeight(FontWeight.Lighter)
            .fontColor('#2C3E50')

          Text(this.breathPhaseText)
            .fontSize(26)
            .fontColor(this.breathColor)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 8 })

          Text(`${this.phaseProgressPct}%`)
            .fontSize(13)
            .fontColor('#A0AEBC')
            .margin({ top: 8 })
        }
      }
      .width(280)
      .height(280)

      // 底栏统计
      Row({ space: 40 }) {
        Column() {
          Text(this.totalCycles.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.breathColor)
          Text('周期')
            .fontSize(11)
            .fontColor('#BCC4CC')
            .margin({ top: 4 })
        }

        Column() {
          Text(this.modeNames[this.selectedModeIndex])
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.breathColor)
          Text('模式')
            .fontSize(11)
            .fontColor('#BCC4CC')
            .margin({ top: 4 })
        }

        Column() {
          Text(this.elapsedSeconds.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.breathColor)
          Text('秒')
            .fontSize(11)
            .fontColor('#BCC4CC')
            .margin({ top: 4 })
        }
      }
      .margin({ top: 48 })

      // 控制按钮
      Row({ space: 28 }) {
        Button(this.isPaused ? '继续' : '暂停')
          .width(120)
          .height(44)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2C3E50')
          .backgroundColor(Color.White)
          .border({ width: 1, color: '#E0E4E8' })
          .borderRadius(22)
          .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
          .onClick(() => { this.pauseExercise() })

        Button('结束')
          .width(120)
          .height(44)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#F87171')
          .borderRadius(22)
          .shadow({ radius: 6, color: '#F8717140', offsetY: 3 })
          .onClick(() => { this.stopExercise() })
      }
      .margin({ top: 48 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
