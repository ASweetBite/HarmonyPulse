// src/main/ets/type/GlobalMusic.ets
import { SongItemType } from './SongItemType';

@ObservedV2
export class GlobalMusic {
  @Trace img: string = ""
  @Trace name: string = ""
  @Trace author: string = ""
  @Trace currentID: string = ""
  @Trace time: number = 0
  @Trace duration: number = 0
  @Trace isPlay: boolean = false // 默认为 false 更合理
  @Trace playbackStatus: "单曲循环" | "随机播放" | "顺序播放" = "顺序播放"
  @Trace currentMusic: number = 0
  @Trace isShowPlayBar: boolean = false

  // 核心：播放列表
  //@Trace playList: SongItemType[] = []
  @Trace songList: SongItemType[] = []; // 必须加 @Trace



  /**
   * 初始化数据 (加载静态资源)
   * @param list 原始歌曲列表
   */
  initData(list: SongItemType[]) {
    // 如果已经有数据了，可能不需要重新覆盖，看需求
    if (this.songList.length > 0) return;

    this.songList = [...list]; // 使用扩展运算符确保深拷贝引用

    // 如果列表不为空，默认选中第一首（但不播放）
    if (this.songList.length > 0) {
      this.resetToMusic(0);
    }
  }

  /**
   * 用户添加歌曲逻辑
   * @param song 新增的歌曲对象
   */
  addSong(song: SongItemType) {
    this.songList = [...this.songList, song];

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
      this.time = 0;
      this.isPlay = false;
      this.isShowPlayBar = true;
    }
  }

}
