import { media } from '@kit.MediaKit'
import { common } from '@kit.AbilityKit'
import { resourceManager } from '@kit.LocalizationKit'

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

/**
 * 播放一段循环背景音（如海浪、雨声）。
 * 返回创建并开始播放的 AVPlayer 实例，调用方负责生命周期管理。
 * @param component 当前组件 this，用于 getContext()
 * @param rawFileName rawfile 目录下的音频文件名，如 'bg_ocean.mp3'
 * @param loop 是否循环播放
 */
export async function playBackgroundSound(
  component: object,
  rawFileName: string,
  loop: boolean,
  existingPlayer: media.AVPlayer | null
): Promise<media.AVPlayer | null> {
  let player = await stopAndReleasePlayer(existingPlayer)

  try {
    player = await media.createAVPlayer()
    let context = getAppContext(component)
    let rawFd = await getRawFd(context, rawFileName)

    player.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
    player.loop = loop
    await player.play()

    return player
  } catch (err) {
    return stopAndReleasePlayer(player)
  }
}

/**
 * 播放一段一次性短音效（如节拍点击音）。
 * 播放完毕后自动释放资源。
 * @param component 当前组件 this，用于 getContext()
 * @param rawFileName rawfile 目录下的音效文件名
 */
export async function playOnceSound(
  component: object,
  rawFileName: string
): Promise<void> {
  try {
    let player = await media.createAVPlayer()
    let context = getAppContext(component)
    let rawFd = await getRawFd(context, rawFileName)

    player.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
    player.loop = false
    player.on('stateChange', (state: media.AVPlayerState) => {
      if (state === 'completed' || state === 'stopped') {
        player.release().catch(() => {})
      }
    })
    player.on('error', () => {
      player.release().catch(() => {})
    })
    await player.play()
  } catch (err) {
  }
}
