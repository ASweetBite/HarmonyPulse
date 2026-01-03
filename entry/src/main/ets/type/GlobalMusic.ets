// src/main/ets/type/GlobalMusic.ets
import { SongItemType } from './SongItemType';

@ObservedV2
export class Playlist {
  @Trace name: string = "";
  @Trace songIds: string[] = []; // 存储歌曲ID，而不是完整对象
  @Trace cover: string = ""; // 歌单封面
  @Trace createTime: number = new Date().getTime();

  // 添加构造函数以确保正确初始化
  constructor(name: string, songIds: string[] = [], cover: string = "") {
    this.name = name;
    this.songIds = songIds;
    this.cover = cover;
    this.createTime = new Date().getTime();
  }
}

@ObservedV2
export class GlobalMusic {
  // 现有属性保持不变
  @Trace img: string = ""
  @Trace name: string = ""
  @Trace author: string = ""
  @Trace currentID: string = ""
  @Trace time: number = 0
  @Trace duration: number = 0
  @Trace isPlay: boolean = false
  @Trace playbackStatus: "单曲循环" | "随机播放" | "顺序播放" = "顺序播放"
  @Trace currentMusic: number = 0
  @Trace isShowPlayBar: boolean = false
  @Trace songList: SongItemType[] = [];

  // 修正后的歌单管理属性 - 使用构造函数创建实例
  @Trace playlists: Playlist[] = [
    new Playlist("我喜欢的音乐", [], ""),
    new Playlist("最近播放", [], ""),
    new Playlist("车载经典", [], ""),
    new Playlist("周杰伦合集", [], ""),
    new Playlist("轻音乐", [], ""),
    new Playlist("助眠歌单", [], "")
  ];

  /**
   * 添加歌曲到指定歌单
   */
  addSongToPlaylist(playlistName: string, songId: string): boolean {
    const playlist = this.playlists.find(p => p.name === playlistName);
    if (playlist && !playlist.songIds.includes(songId)) {
      // 使用扩展运算符确保数组更新能被Trace检测到
      playlist.songIds = [...playlist.songIds, songId];
      console.info(`歌曲 ${songId} 已添加到歌单 ${playlistName}`);
      return true;
    }
    return false;
  }

  /**
   * 从歌单移除歌曲
   */
  removeSongFromPlaylist(playlistName: string, songId: string): boolean {
    const playlist = this.playlists.find(p => p.name === playlistName);
    if (playlist) {
      const index = playlist.songIds.indexOf(songId);
      if (index > -1) {
        playlist.songIds = playlist.songIds.filter(id => id !== songId);
        return true;
      }
    }
    return false;
  }

  /**
   * 获取歌单中的歌曲详情列表
   */
  getPlaylistSongs(playlistName: string): SongItemType[] {
    const playlist = this.playlists.find(p => p.name === playlistName);
    if (!playlist) return [];

    return playlist.songIds.map(songId =>
    this.songList.find(song => song.id === songId)
    ).filter(Boolean) as SongItemType[];
  }

  /**
   * 获取歌单歌曲数量
   */
  getPlaylistSongCount(playlistName: string): number {
    const playlist = this.playlists.find(p => p.name === playlistName);
    return playlist ? playlist.songIds.length : 0;
  }

  /**
   * 创建新歌单
   */
  createPlaylist(name: string, cover?: string): boolean {
    if (this.playlists.find(p => p.name === name)) {
      return false; // 歌单已存在
    }
    this.playlists = [...this.playlists, new Playlist(name, [], cover || "")];
    return true;
  }

  /**
   * 初始化数据 (加载静态资源)
   */
  initData(list: SongItemType[]) {
    if (this.songList.length > 0) return;

    this.songList = [...list];

    // 如果列表不为空，默认选中第一首（但不播放）
    if (this.songList.length > 0) {
      this.resetToMusic(0);
    }
  }

  /**
   * 用户添加歌曲逻辑
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