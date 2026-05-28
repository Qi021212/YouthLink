// pages/CalmWaveGame.ets
import { promptAction, router } from '@kit.ArkUI';
import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 类型定义
interface Ripple {
  id: number;
  x: number;
  y: number;
  createdAt: number;
}

interface CueItem {
  at: number;
  text: string;
}

// 常量
const TOTAL_DURATION: number = 180000; // 3分钟
const FADE_TAIL: number = 20000;

@Entry
@Component
struct CalmWaveGamePage {
  @State progress: number = 0;
  @State breatheScale: number = 1;
  @State waveOpacity1: number = 0;
  @State waveOpacity2: number = 0;
  @State waveOpacity3: number = 0;
  @State waveOpacity4: number = 0;
  @State fadeOpacity: number = 0;
  @State rippleItems: Ripple[] = [];
  @State currentText: string = '';
  @State showText: boolean = false;
  @State ttsEnabled: boolean = true;
  @State audioEnabled: boolean = true;
  @State isSpeaking: boolean = false;

  private mainTimer: number = -1;
  private waveTimer: number = -1;
  private elapsed: number = 0;
  private cueIndex: number = 0;
  private rippleIdCounter: number = 0;
  private startTime: number = 0;

  private ttsEngine: textToSpeech.TextToSpeechEngine | undefined = undefined;
  private speakListener: textToSpeech.SpeakListener | undefined = undefined;

  private cues: CueItem[] = [
    { at: 2000, text: "把注意力放到身体" },
    { at: 20000, text: "不需要努力，呼吸自然就好" },
    { at: 50000, text: "如果思绪飘走，轻轻带回这里" },
    { at: 90000, text: "放松肩膀和下颌" },
    { at: 140000, text: "继续，只是观察" },
    { at: 170000, text: "准备结束，做一次更长的呼气" }
  ];

  async aboutToAppear() {
    console.info('=== CalmWaveGame 页面加载 ===');
    this.startTime = Date.now();

    await this.initTTS();

    this.startMainTimer();
    this.startWaveAnimation();
    this.checkNextCue();
  }

  aboutToDisappear() {
    this.stopAll();
    this.stopTTS();
  }

  async initTTS() {
    try {
      this.initSpeakListener();

      const initParams: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: {
          "style": 'interaction-broadcast',
          "locate": 'CN',
          "name": 'EngineName'
        }
      };

      textToSpeech.createEngine(initParams, (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
        if (!err && engine) {
          this.ttsEngine = engine;
          if (this.speakListener) {
            this.ttsEngine.setListener(this.speakListener);
          }
          console.info('TTS引擎初始化成功');
        } else {
          console.error(`TTS引擎初始化失败: ${err?.message}`);
          this.ttsEnabled = false;
        }
      });
    } catch (error) {
      console.error('TTS初始化异常: ' + JSON.stringify(error));
      this.ttsEnabled = false;
    }
  }

  initSpeakListener() {
    this.speakListener = {
      onStart: (requestId: string, response: textToSpeech.StartResponse) => {
        this.isSpeaking = true;
        console.info('语音播报开始');
      },
      onComplete: (requestId: string, response: textToSpeech.CompleteResponse) => {
        this.isSpeaking = false;
        console.info('语音播报完成');
      },
      onStop: (requestId: string, response: textToSpeech.StopResponse) => {
        this.isSpeaking = false;
        console.info('语音播报停止');
      },
      onError: (requestId: string, errorCode: number, errorMessage: string) => {
        this.isSpeaking = false;
        console.error(`TTS错误: ${errorCode} - ${errorMessage}`);
      },
      onData: (requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) => {
        // 音频数据回调，一般不需要处理
      }
    };
  }

  async speak(text: string) {
    if (!this.ttsEnabled || !this.ttsEngine) {
      this.showTextPrompt(text);
      return;
    }

    try {
      const speakParams: textToSpeech.SpeakParams = {
        requestId: Date.now().toString(),
        extraParams: {
          "queueMode": 0,
          "speed": 1,
          "volume": 2,
          "pitch": 1,
          "languageContext": 'zh-CN'
        }
      };

      this.ttsEngine.speak(text, speakParams);
      console.info('开始播报: ' + text);
    } catch (err) {
      console.error('语音播报失败: ' + JSON.stringify(err));
      this.showTextPrompt(text);
    }
  }

  async stopTTS() {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.stop();
        this.ttsEngine.shutdown();
      } catch (err) {
        console.error('停止TTS失败: ' + JSON.stringify(err));
      }
    }
  }

  showTextPrompt(text: string) {
    this.currentText = text;
    this.showText = true;

    try {
      promptAction.showToast({
        message: text,
        duration: 2000
      });
    } catch (err) {
      console.error('Toast失败: ' + JSON.stringify(err));
    }

    setTimeout(() => {
      this.showText = false;
    }, 3000);
  }

  async showPrompt(text: string) {
    this.currentText = text;
    this.showText = true;

    await this.speak(text);

    setTimeout(() => {
      this.showText = false;
    }, 3000);
  }

  stopAll() {
    if (this.mainTimer !== -1) {
      clearInterval(this.mainTimer);
      this.mainTimer = -1;
    }
    if (this.waveTimer !== -1) {
      clearInterval(this.waveTimer);
      this.waveTimer = -1;
    }
  }

  startMainTimer() {
    this.mainTimer = setInterval(() => {
      const now = Date.now();
      this.elapsed = now - this.startTime;

      if (this.elapsed >= TOTAL_DURATION) {
        this.stopAll();
        this.progress = 1;
        console.info('冥想完成');
        this.onGameFinish();
        return;
      }

      this.progress = this.elapsed / TOTAL_DURATION;

      if (this.elapsed >= TOTAL_DURATION - FADE_TAIL) {
        this.fadeOpacity = (this.elapsed - (TOTAL_DURATION - FADE_TAIL)) / FADE_TAIL;
      }
    }, 100);
  }

  async onGameFinish() {
    await this.stopTTS();
    setTimeout(() => {
      router.back();
    }, 1000);
  }

  startWaveAnimation() {
    this.waveTimer = setInterval(() => {
      // 呼吸效果
      const breathTime = Date.now() / 1000;
      this.breatheScale = 1 + Math.sin(breathTime * Math.PI / 3) * 0.02;

      // 波浪相位 - 从0到1循环
      const wavePhase = (Date.now() % 4000) / 4000;

      // 外层波纹透明度较低，内层较高，实现扩散效果
      this.waveOpacity1 = (1 - wavePhase) * (1 - this.fadeOpacity) * 0.25;
      this.waveOpacity2 = (1 - ((wavePhase + 0.25) % 1)) * (1 - this.fadeOpacity) * 0.25;
      this.waveOpacity3 = (1 - ((wavePhase + 0.5) % 1)) * (1 - this.fadeOpacity) * 0.25;
      this.waveOpacity4 = (1 - ((wavePhase + 0.75) % 1)) * (1 - this.fadeOpacity) * 0.25;
    }, 50);
  }

  checkNextCue() {
    if (this.cueIndex >= this.cues.length) return;

    const cue = this.cues[this.cueIndex];
    const cueTime = cue.at;

    const checkAndShow = () => {
      const elapsed = Date.now() - this.startTime;

      if (elapsed >= cueTime) {
        this.cueIndex++;
        this.showPrompt(cue.text);
        this.checkNextCue();
      } else {
        setTimeout(checkAndShow, 100);
      }
    };

    setTimeout(checkAndShow, 100);
  }

  addRipple(x: number, y: number) {
    if (this.fadeOpacity > 0.85) return;

    const newRipple: Ripple = {
      id: this.rippleIdCounter++,
      x: x,
      y: y,
      createdAt: Date.now()
    };

    this.rippleItems = [...this.rippleItems, newRipple];

    if (this.rippleItems.length > 15) {
      this.rippleItems = this.rippleItems.slice(1);
    }
  }

  getRippleOpacity(ripple: Ripple): number {
    const age = (Date.now() - ripple.createdAt) / 1000;
    if (age > 3) return 0;
    const opacity = 0.25 * (1 - age / 3);
    return Math.max(0, Math.min(0.25, opacity));
  }

  getRippleSize(ripple: Ripple): number {
    const age = (Date.now() - ripple.createdAt) / 1000;
    return age * 80;
  }

  build() {
    Stack() {
      // ========== 浅绿色渐变背景 ==========
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            ['#E8F1EE', 0.0],
            ['#DCEAE5', 0.5],
            ['#D0E3DC', 1.0]
          ]
        })

      // ========== 波纹动画层 ==========
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          // 最外层
          Circle()
            .width('90%')
            .height('90%')
            .fill(null)
            .stroke('#5BAB8A')
            .strokeWidth(2)
            .opacity(this.waveOpacity1)

          // 第二层
          Circle()
            .width('70%')
            .height('70%')
            .fill(null)
            .stroke('#5BAB8A')
            .strokeWidth(2)
            .opacity(this.waveOpacity2)

          // 第三层
          Circle()
            .width('50%')
            .height('50%')
            .fill(null)
            .stroke('#5BAB8A')
            .strokeWidth(2)
            .opacity(this.waveOpacity3)

          // 最内层
          Circle()
            .width('30%')
            .height('30%')
            .fill(null)
            .stroke('#5BAB8A')
            .strokeWidth(2)
            .opacity(this.waveOpacity4)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .position({ x: 0, y: '15%' })

      // ========== 涟漪层 ==========
      Stack() {
        ForEach(this.rippleItems, (ripple: Ripple) => {
          Circle()
            .width(this.getRippleSize(ripple))
            .height(this.getRippleSize(ripple))
            .position({
              x: ripple.x - this.getRippleSize(ripple) / 2,
              y: ripple.y - this.getRippleSize(ripple) / 2
            })
            .fill(null)
            .stroke('#5BAB8A')
            .strokeWidth(1.5)
            .opacity(this.getRippleOpacity(ripple))
        }, (ripple: Ripple): string => ripple.id.toString())
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)

      // ========== 触摸交互层 ==========
      Column()
        .width('100%')
        .height('100%')
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down && event.touches.length > 0) {
            this.addRipple(event.touches[0].x, event.touches[0].y);
          }
        })

      // ========== 顶部进度条 ==========
      Column() {
        Progress({
          value: this.progress * 100,
          total: 100,
          type: ProgressType.Linear
        })
          .width('90%')
          .height(3)
          .color('#5BAB8A')
          .backgroundColor('rgba(91, 171, 138, 0.2)')
      }
      .width('100%')
      .position({ x: 0, y: 50 })

      // ========== 文字提示 ==========
      if (this.showText) {
        Text(this.currentText)
          .fontSize(18)
          .fontColor('#5BAB8A')
          .textAlign(TextAlign.Center)
          .width('80%')
          .position({ x: '10%', y: '70%' })
          .opacity(0.9)
          .transition(TransitionEffect.OPACITY.animation({ duration: 500 }))
      }

      // ========== TTS状态指示器 ==========
      Row() {
        Text('🔊').fontSize(16).fontColor('#5BAB8A')
        Text('语音引导中...').fontSize(12).fontColor('#5BAB8A')
      }
      .position({ x: 20, y: 100 })


      // ========== 淡出遮罩 ==========
      if (this.fadeOpacity > 0.01) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(`rgba(208, 227, 220, ${this.fadeOpacity})`)
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height('100%')
  }
}