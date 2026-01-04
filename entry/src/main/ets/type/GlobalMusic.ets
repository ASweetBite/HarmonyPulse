// src/main/ets/type/GlobalMusic.ets
import { SongItemType } from './SongItemType';

@ObservedV2
export class GlobalMusic {
  @Trace img: string = ""
  @Trace name: string = ""
  @Trace author: string = ""
  @Trace currentID: string = ""
  @Trace lyricPath: string = ""
  @Trace time: number = 0
  @Trace duration: number = 0
  @Trace isPlay: boolean = false // 默认为 false 更合理
  @Trace playbackStatus: "单曲循环" | "随机播放" | "顺序播放" = "顺序播放"
  @Trace currentMusic: number = 0
  @Trace isShowPlayBar: boolean = false
  private onSongChangeListeners: Array<() => void> = [];

  // 核心：播放列表
  //@Trace playList: SongItemType[] = []
  @Trace songList: SongItemType[] = []; // 必须加 @Trace
  songs: SongItemType[] = []

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
   * 【新增】删除歌曲：从内存列表中移除，触发 UI 刷新
   */
  removeSongById(id: string) {
    this.songList = this.songList.filter(item => item.id !== id);
    // 如果删除了当前正在播放的歌，需要处理索引重置逻辑（可选）
    if (this.currentID === id) {
      this.isPlay = false;
      if (this.songList.length > 0) {
        this.resetToMusic(0);
      } else {
        this.isShowPlayBar = false;
      }
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
      this.time = 0;
      this.isPlay = false;
      this.isShowPlayBar = true;
    }
  }

}
