import { media } from '@kit.MediaKit'
import { common } from '@kit.AbilityKit'
import { resourceManager } from '@kit.LocalizationKit'
import { BusinessError } from '@kit.BasicServicesKit'

export interface AudioResult {
  success: boolean
  error: string
}

const TAG = 'AudioPlayerUtil'

export function getAppContext(component: object): common.UIAbilityContext {
  return getContext(component) as common.UIAbilityContext
}

export async function getRawFd(
  context: common.UIAbilityContext,
  rawFileName: string
): Promise<resourceManager.RawFileDescriptor> {
  return context.resourceManager.getRawFd(rawFileName)
}

export async function stopAndReleasePlayer(
  player: media.AVPlayer | null
): Promise<media.AVPlayer | null> {
  if (!player) {
    return null
  }
  try {
    await player.stop()
  } catch (err) {
  }
  try {
    await player.release()
  } catch (err) {
  }
  return null
}

export async function playBackgroundSound(
  component: object,
  rawFileName: string,
  loop: boolean,
  existingPlayer: media.AVPlayer | null
): Promise<media.AVPlayer | null> {
  let player = await stopAndReleasePlayer(existingPlayer)

  try {
    player = await media.createAVPlayer()
    const avPlayer = player
    const context = getAppContext(component)
    const rawFd = await getRawFd(context, rawFileName)

    avPlayer.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
    avPlayer.loop = loop

    await new Promise<void>((resolve: () => void) => {
      avPlayer.on('stateChange', (state: media.AVPlayerState) => {
        if (state === 'prepared') {
          resolve()
        }
      })
    })

    avPlayer.on('error', (err: BusinessError) => {
      console.error(`${TAG} [bg] error: [${err.code}] ${err.message}`)
    })

    await avPlayer.play()
    return avPlayer
  } catch (err) {
    const e = err as BusinessError
    console.error(`${TAG} [bg] failed: ${rawFileName}, code=${e.code}, msg=${e.message}`)
    return stopAndReleasePlayer(player)
  }
}

export async function playOnceSound(
  component: object,
  rawFileName: string
): Promise<void> {
  try {
    const avPlayer = await media.createAVPlayer()
    const context = getAppContext(component)
    const rawFd = await getRawFd(context, rawFileName)

    avPlayer.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
    avPlayer.loop = false

    avPlayer.on('error', (err: BusinessError) => {
      console.error(`${TAG} [once] error: [${err.code}] ${err.message}`)
      avPlayer.release().catch(() => {})
    })

    await new Promise<void>((resolve: () => void) => {
      avPlayer.on('stateChange', (state: media.AVPlayerState) => {
        if (state === 'prepared') {
          resolve()
        }
      })
    })

    avPlayer.on('stateChange', (state: media.AVPlayerState) => {
      if (state === 'completed' || state === 'stopped' || state === 'error') {
        avPlayer.release().catch(() => {})
      }
    })

    await avPlayer.play()
  } catch (err) {
    const e = err as BusinessError
    console.error(`${TAG} [once] failed: ${rawFileName}, code=${e.code}, msg=${e.message}`)
  }
}

export async function testAudioPlayback(component: object): Promise<AudioResult> {
  try {
    const player = await media.createAVPlayer()
    const context = getAppContext(component)
    const rawFd = await getRawFd(context, 'beat_tick.mp3')

    player.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
    player.loop = false

    await new Promise<void>((resolve: () => void) => {
      player.on('stateChange', (state: media.AVPlayerState) => {
        if (state === 'prepared') {
          resolve()
        }
      })
    })

    await player.play()

    await new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        player.stop().catch(() => {})
        player.release().catch(() => {})
        resolve()
      }, 2000)
    })

    return { success: true, error: '' }
  } catch (err) {
    const e = err as BusinessError
    let msg = e.message
    if (e.code !== undefined) {
      msg = `[${e.code}] ${e.message}`
    }
    if (msg.indexOf('file') >= 0) {
      msg = '音频文件未找到，请检查 rawfile 目录'
    } else if (msg.indexOf('create') >= 0 || msg.indexOf('5400101') >= 0) {
      msg = '模拟器不支持音频播放，请使用真机测试'
    } else if (msg.indexOf('codec') >= 0 || msg.indexOf('format') >= 0) {
      msg = '音频格式不支持，请确认文件为有效 MP3'
    }
    console.error(`${TAG} [test] failed: ${msg}`)
    return { success: false, error: msg }
  }
}
