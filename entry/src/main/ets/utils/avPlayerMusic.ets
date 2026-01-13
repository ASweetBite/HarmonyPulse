import media from '@ohos.multimedia.media'
import { common } from '@kit.AbilityKit'
import { GlobalMusic } from '../type/GlobalMusic'
import { AppStorageV2 } from '@kit.ArkUI'
import { SessionManager } from './AVSessionManager'
import { SongItemType } from '../type/SongItemType'
import { fileIo as fs } from '@kit.CoreFileKit';

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
        this.GlobalMusic.songList[this.GlobalMusic.currentMusic]
      )
    })

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.GlobalMusic.time = time
      SessionManager.setPlaybackStatus()
    })
  }

  /** 设置本地源逻辑保持不变 */
  private async setLocalSource(song: SongItemType) {
    if (!this.context || !this.avPlayer) return;
    await this.avPlayer.reset();
    this.GlobalMusic.isPlay = false

    try {
      if (song.id.startsWith('user_') || song.id.startsWith('local_')) {
        const filePath = `${this.context.filesDir}/${song.filePath}`;
        if (fs.accessSync(filePath)) {
          const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
          this.avPlayer.fdSrc = { fd: file.fd, offset: 0, length: -1 };
        }
      } else {
        const fd = await this.context.resourceManager.getRawFd(song.filePath);
        this.avPlayer.fdSrc = { fd: fd.fd, offset: fd.offset, length: fd.length };
      }
    } catch (err) {
      console.error('设置播放源失败: ' + JSON.stringify(err));
    }
    this.GlobalMusic.isPlay = true
  }

  /** 核心修改：切歌逻辑 */
  async changePlay() {
    if (!this.avPlayer) return

    await this.avPlayer.reset()

    this.GlobalMusic.time = 0
    this.GlobalMusic.duration = 0

    const song = this.GlobalMusic.songList[this.GlobalMusic.currentMusic]

    // 1. 更新全局元数据
    this.GlobalMusic.currentID = song.id // 确保 ID 被同步，用于子组件判断
    this.GlobalMusic.name = song.name
    this.GlobalMusic.author = song.author
    this.GlobalMusic.img = song.img
    this.GlobalMusic.lyricPath = song.lyricPath || ""
    this.GlobalMusic.hasLyric = song.hasLyric

    this.GlobalMusic.notifySongChange();

    // 3. 开始加载音频资源
    await this.setLocalSource(song)
    await this.avPlayer.prepare()
    // 注意：prepared 状态回调会自动调用 play()
  }

  /** 上一首 */
  preSong() {
    if (this.GlobalMusic.songList.length === 0) return
    if (this.GlobalMusic.playbackStatus !== "单曲循环") {
      this.GlobalMusic.currentMusic =
        (this.GlobalMusic.currentMusic - 1 + this.GlobalMusic.songList.length)
          % this.GlobalMusic.songList.length
      this.changePlay()
    } else {
      this.avPlayer?.play()
    }
    SessionManager.setPlaybackStatus()
  }

  /** 下一首 */
  nextSong() {
    if (this.GlobalMusic.songList.length === 0) return
    if (this.GlobalMusic.playbackStatus === "顺序播放") {
      this.GlobalMusic.currentMusic =
        (this.GlobalMusic.currentMusic + 1) % this.GlobalMusic.songList.length
      this.changePlay()
    } else if (this.GlobalMusic.playbackStatus === "单曲循环") {
      this.avPlayer?.seek(0)
      this.avPlayer?.play()
    } else {
      let next = Math.floor(Math.random() * this.GlobalMusic.songList.length)
      if (next === this.GlobalMusic.currentMusic && this.GlobalMusic.songList.length > 1) {
        next = (next + 1) % this.GlobalMusic.songList.length
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

  /** 点击歌曲播放 */
  playResources(song: SongItemType) {
    SessionManager.startContinuousTask()
    const index = this.GlobalMusic.songList.findIndex(item => item.id === song.id)

    if (index !== -1) {
      this.GlobalMusic.currentMusic = index
    } else {
      // 如果不在播放列表中，则插入到首位
      this.GlobalMusic.songList.unshift(song)
      this.GlobalMusic.currentMusic = 0
    }
    this.changePlay()
  }

  jumpToPlay(time: number) {
    this.avPlayer?.seek(time)
    this.avPlayer?.play()
  }

  deleteSong(index: number) {
    this.GlobalMusic.songList.splice(index, 1)
    // 如果删除的是当前播放的歌曲，建议调用 nextSong()
  }

  async release() {
    await this.avPlayer?.release()
    this.avPlayer = null
  }
}

export const avPlayerManage = new avPlayerMusic()
