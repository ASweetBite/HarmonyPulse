import media from '@ohos.multimedia.media'
import { common } from '@kit.AbilityKit'
import { GlobalMusic } from '../type/GlobalMusic'
import { AppStorageV2 } from '@kit.ArkUI'
import { SessionManager } from './AVSessionManager'
import { SongItemType } from '../type/SongItemType'

class avPlayerMusic {

  GlobalMusic: GlobalMusic =
    AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!

  avPlayer: media.AVPlayer | null = null
  private context: common.UIAbilityContext | null = null

  setContext(ctx: common.UIAbilityContext) {
    this.context = ctx
  }

  async init() {
    if (this.avPlayer) return

    this.avPlayer = await media.createAVPlayer()

    this.avPlayer.on('stateChange', (state: string) => {
      switch (state) {
        case 'initialized':
          this.avPlayer?.prepare()
          break

        case 'prepared':
          this.avPlayer?.play()
          break

        case 'completed':
          this.nextSong()
          break

        case 'error':
          this.avPlayer?.reset()
          break
      }
    })

    this.avPlayer.on('durationUpdate', (duration: number) => {
      this.GlobalMusic.duration = duration
      SessionManager.SetMetaData(
        this.GlobalMusic.playList[this.GlobalMusic.currentMusic]
      )
    })

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.GlobalMusic.time = time
      SessionManager.setPlaybackStatus()
    })
  }

  /** 核心：设置本地音乐源 */
  private async setLocalSource(fileName: string) {
    if (!this.context || !this.avPlayer) return

    const fd = await this.context.resourceManager.getRawFd(fileName)

    this.avPlayer.fdSrc = {
      fd: fd.fd,
      offset: fd.offset,
      length: fd.length
    }
  }

  /** 切歌（本地版） */
  async changePlay() {
    if (!this.avPlayer) return

    await this.avPlayer.reset()

    this.GlobalMusic.time = 0
    this.GlobalMusic.duration = 0

    const song = this.GlobalMusic.playList[this.GlobalMusic.currentMusic]

    this.GlobalMusic.name = song.name
    this.GlobalMusic.author = song.author
    this.GlobalMusic.img = song.img

    await this.setLocalSource(song.fileName)
  }

  /** 上一首 */
  preSong() {
    if (this.GlobalMusic.playList.length === 0) return

    if (this.GlobalMusic.playbackStatus !== "单曲循环") {
      this.GlobalMusic.currentMusic =
        (this.GlobalMusic.currentMusic - 1 + this.GlobalMusic.playList.length)
          % this.GlobalMusic.playList.length

      this.changePlay()
    } else {
      this.avPlayer?.play()
    }

    SessionManager.setPlaybackStatus()
  }

  /** 下一首 */
  nextSong() {
    if (this.GlobalMusic.playList.length === 0) return

    if (this.GlobalMusic.playbackStatus === "顺序播放") {
      this.GlobalMusic.currentMusic =
        (this.GlobalMusic.currentMusic + 1) % this.GlobalMusic.playList.length

      this.changePlay()
    } else if (this.GlobalMusic.playbackStatus === "单曲循环") {
      this.avPlayer?.play()
    } else {
      // 随机播放
      let next = Math.floor(Math.random() * this.GlobalMusic.playList.length)
      if (next === this.GlobalMusic.currentMusic && this.GlobalMusic.playList.length > 1) {
        next = (next + 1) % this.GlobalMusic.playList.length
      }
      this.GlobalMusic.currentMusic = next
      this.changePlay()
    }

    SessionManager.setPlaybackStatus()
  }

  /** 暂停 / 播放 */
  stopOrContinueSong() {
    if (!this.avPlayer) return

    this.GlobalMusic.isPlay = !this.GlobalMusic.isPlay

    if (this.GlobalMusic.isPlay) {
      this.avPlayer.play()
    } else {
      this.avPlayer.pause()
    }

    SessionManager.setPlaybackStatus()
  }

  /** 点击歌曲播放（本地） */
  playResources(song: SongItemType) {
    SessionManager.startContinuousTask()

    const index = this.GlobalMusic.playList.findIndex(item => item.id === song.id)

    if (index !== -1) {
      this.GlobalMusic.currentMusic = index
    } else {
      this.GlobalMusic.playList.unshift(song)
      this.GlobalMusic.currentMusic = 0
    }

    this.changePlay()
  }

  jumpToPlay(time: number) {
    this.avPlayer?.seek(time)
  }

  deleteSong(index: number) {
    this.GlobalMusic.playList.splice(index, 1)
  }

  async release() {
    await this.avPlayer?.release()
    this.avPlayer = null
  }
}

export const avPlayerManage = new avPlayerMusic()
