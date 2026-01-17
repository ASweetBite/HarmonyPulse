// src/main/ets/type/GlobalMusic.ets
import { SongItemType } from './SongItemType';

export type PlaybackMode = "顺序播放" | "单曲循环" | "随机播放";

@ObservedV2
export class GlobalMusic {
  @Trace img: string = ""
  @Trace name: string = ""
  @Trace author: string = ""
  @Trace currentID: string = ""
  @Trace lyricPath: string = ""
  @Trace hasLyric: boolean = false
  @Trace time: number = 0
  @Trace duration: number = 0
  @Trace isPlay: boolean = false // 默认为 false 更合理
  @Trace playbackStatus: PlaybackMode = "顺序播放"
  @Trace currentMusic: number = 0
  @Trace isShowPlayBar: boolean = false
  private onSongChangeListeners: Array<() => void> = [];

  // 核心：播放列表
  //@Trace playList: SongItemType[] = []
  @Trace songList: SongItemType[] = []; // 必须加 @Trace

  // 注册监听
  onSongChange(callback: () => void) {
    this.onSongChangeListeners.push(callback);
  }

  // 触发所有监听
  notifySongChange() {
    this.onSongChangeListeners.forEach(cb => cb());
  }

  /**
   * 初始化数据 (改为由外部传入数据库查询结果)
   */
  initData(list: SongItemType[]) {
    this.songList = [...list];
    if (this.songList.length > 0 && this.currentID === "") {
      this.resetToMusic(0);
    }
  }

  /**
   * 用户添加歌曲逻辑
   * @param song 新增的歌曲对象
   */
  addSong(song: SongItemType) {
    this.songList = [...this.songList, song];
    // 如果是第一首歌，自动显示播放栏
    if (this.songList.length === 1) {
      this.resetToMusic(0);
    }
  }

  /**
   * 切换当前选中的音乐信息（不包含播放逻辑，只更新状态）
   */
  private resetToMusic(index: number) {
    const item = this.songList[index];
    if (item) {
      this.currentMusic = index;
      this.currentID = item.id;
      this.name = item.name;
      this.author = item.author;
      this.img = item.img;
      this.lyricPath = item.lyricPath
      this.hasLyric = item.hasLyric
      this.time = 0;
      this.isPlay = false;
      this.isShowPlayBar = true;
    }
  }

}
