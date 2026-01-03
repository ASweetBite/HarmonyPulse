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
        this.GlobalMusic.playList[this.GlobalMusic.currentMusic]
      )
    })

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.GlobalMusic.time = time
      SessionManager.setPlaybackStatus()
    })
  }

   /** 核心：设置本地音乐源 */
  /**
   * 设置音频源 (支持 rawfile 和 沙箱文件)
   * @param song 传入完整的歌曲对象，方便判断来源
   */
  private async setLocalSource(song: SongItemType) {
    if (!this.context || !this.avPlayer) return;

    // 重置播放器状态，准备切换歌曲
    await this.avPlayer.reset();
    this.GlobalMusic.isPlay = false

    try {
      // 判断是否为用户导入的歌曲 (根据 ID 前缀判断，或者你可以在 SongItemType 加个布尔值)
      if (song.id.startsWith('user_') || song.id.startsWith('local_')) {

        // --- 情况 A: 处理沙箱中的导入歌曲 ---
        const filePath = `${this.context.filesDir}/${song.fileName}`;

        // 检查文件是否存在
        if (fs.accessSync(filePath)) {
          const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);

          // 对于沙箱文件，直接传 fd 即可，offset 默认为 0，length 传 -1 表示读到结尾
          this.avPlayer.fdSrc = {
            fd: file.fd,
            offset: 0,
            length: -1
          };
          console.info(`播放沙箱音乐: ${song.name}`);
        } else {
          console.error('沙箱文件不存在');
        }

      } else {

        // --- 情况 B: 处理 rawfile 中的预置歌曲 ---
        try {
          const fd = await this.context.resourceManager.getRawFd(song.fileName);
          this.avPlayer.fdSrc = {
            fd: fd.fd,
            offset: fd.offset,
            length: fd.length
          };
          console.info(`播放 Rawfile 音乐: ${song.name}`);
        } catch (rawError) {
          console.error('读取 Rawfile 失败: ' + JSON.stringify(rawError));
        }
      }
    } catch (err) {
      console.error('设置播放源失败: ' + JSON.stringify(err));
    }
    this.GlobalMusic.isPlay = true

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

    await this.setLocalSource(song)
    await this.avPlayer.prepare()
    await this.avPlayer.play()

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
