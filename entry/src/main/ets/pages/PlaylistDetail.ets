import { AppStorageV2, promptAction, router } from '@kit.ArkUI';
import { GlobalMusic } from '../type/GlobalMusic';
import { SongItemType } from '../type/SongItemType';
import { avPlayerManage } from '../utils/avPlayerMusic';
import RdbManager from '../utils/RdbManager';
import { MiniPlayBar } from './components/MiniPlayBar';

interface PlaylistRouteParams {
  playlistId?: number
  playlistName?: string
}


@Entry
@Component
struct PlaylistDetail {
  globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!;
  @State playlistName: string = '未命名歌单';
  @State playlistId: number = 0;
  @State songs: SongItemType[] = [];
  @State showAddSongDialog: boolean = false;
  @State searchKeyword: string = '';
  @State searchResults: SongItemType[] = [];
  @State isLoading: boolean = false;
  // 默认封面图
  @State coverImg: string | Resource= "";

  aboutToAppear(): void {
    const params = router.getParams() as PlaylistRouteParams | undefined;
    if (params) {
      this.playlistId = params.playlistId ?? 0;
      this.playlistName = params.playlistName ?? '加载中...';
    }
    this.refreshData();
  }

  onPageHide(): void {
    console.log('aboutToDisappear 已触发，开始执行相关逻辑');

    // 调用独立的异步方法（处理数据库查询等异步操作）
    this.handleAsyncQuitLogic();

    // 同步逻辑直接在这里编写（优先执行，确保完整）
    this.showAddSongDialog = false;
    this.searchKeyword = '';
  }

  /**
   * 独立的异步退出逻辑方法（专门处理需要 await 的操作）
   */
  private async handleAsyncQuitLogic(): Promise<void> {
    try {
      // 你的异步逻辑：查询所有歌曲
      const tempSongs = await RdbManager.getAllSongs();
      this.globalMusic.songList = tempSongs;
      console.log('异步退出逻辑执行完成，歌曲列表已更新');
    } catch (e) {
      console.error('异步退出逻辑执行失败', e);
    }
  }

  // 刷新歌单数据
  async refreshData() {
    if (this.playlistId <= 0) return;

    try {
      // 1. 从数据库获取歌单详情（名称、封面图、描述等）
      const playlistInfo = await RdbManager.getPlaylistById(this.playlistId);
      if (playlistInfo) {
        this.playlistName = playlistInfo.name;
        // 如果数据库有封面则用数据库的，否则用默认
        if (playlistInfo.img) {
          this.coverImg = playlistInfo.img;
        }
      }

      // 2. 获取歌单关联的歌曲列表
      const results = await RdbManager.getSongsByPlaylistId(this.playlistId);
      this.songs = results;
      this.globalMusic.songList = results;

      // 兜底策略：如果歌单本身没封面，但有歌曲，则取第一首歌的封面
      if (!this.coverImg) {
        this.coverImg = $r('app.media.ic_default_list')
      }
    } catch (e) {
      console.error('RefreshData Error:', e);
      promptAction.showToast({ message: '获取歌单信息失败' });
    }
  }


  /** 搜索数据库歌曲 */
  private async searchSongsFromDB(): Promise<void> {
    if (!this.searchKeyword.trim()) {
      this.searchResults = [];
      return;
    }
    this.isLoading = true;
    try {
      const results = await RdbManager.searchSongs(this.searchKeyword);
      // 过滤已存在的
      this.searchResults = results.filter(song => !this.songs.some(s => s.id === song.id));
    } catch (e) {
      console.error('Search Error', e);
    } finally {
      this.isLoading = false;
    }
  }

  /** 数据库操作：添加歌曲 */
  private async handleAddSong(song: SongItemType) {
    const success = await RdbManager.addSongToPlaylist(this.playlistId, song.id);
    if (success) {
      promptAction.showToast({ message: `已添加 ${song.name}` });
      this.refreshData(); // 重新加载列表
    }
  }

  /** 数据库操作：移除歌曲 */
  private async handleRemoveSong(songId: string) {
    const success = await RdbManager.removeSongFromPlaylist(this.playlistId, songId);
    if (success) {
      promptAction.showToast({ message: '已从歌单移除' });
      this.refreshData();
    }
  }

  private getTotalDuration(): string {
    const totalMinutes = this.songs.length * 3.8; // 模拟时长
    const h = Math.floor(totalMinutes / 60);
    const m = Math.floor(totalMinutes % 60);
    return h > 0 ? `${h}小时${m}分钟` : `${m}分钟`;
  }

  // 歌曲列表单行组件
  @Builder
  BuildSongItem(song: SongItemType, index: number) {
    Row({ space: 16 }) {
      Text(`${index + 1}`)
        .fontSize(14)
        .fontColor('#999')
        .width(25)
        .textAlign(TextAlign.Center)

      Image(song.img || $r("app.media.ic_default"))
        .width(52)
        .height(52)
        .borderRadius(8)
        .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })

      Column({ space: 4 }) {
        Text(song.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(song.author)
          .fontSize(12)
          .fontColor('#666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 更多操作按钮
      Image($r('app.media.ic_more'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .bindMenu([
          { value: '立即播放', action: () => avPlayerManage.playResources(song) },
          { value: '移除歌曲', action: () => this.handleRemoveSong(song.id) }
        ])
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .onClick(() => avPlayerManage.playResources(song))
  }

  // 搜索对话框组件
  @Builder
  BuildAddSongDialog() {
    Column() {
      // 顶部条
      Rect()
        .width(40)
        .height(5)
        .fill('#DDD')
        .borderRadius(3)
        .margin({ top: 10, bottom: 20 })

      Text('添加歌曲到歌单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })

      Search({ placeholder: '搜索音乐、歌手', value: this.searchKeyword })
        .width('100%')
        .height(40)
        .onChange((val) => {
          this.searchKeyword = val;
          this.searchSongsFromDB();
        })
        .margin({ bottom: 15 })

      List() {
        if (this.isLoading) {
          ListItem() { LoadingProgress().width(40).alignSelf(ItemAlign.Center) }
        } else {
          ForEach(this.searchResults, (song: SongItemType) => {
            ListItem() {
              Row() {
                Image(song.img || $r('app.media.ic_default')).width(40).height(40).borderRadius(4).margin({ right: 12 })
                Column() {
                  Text(song.name).fontSize(14).fontWeight(FontWeight.Medium)
                  Text(song.author).fontSize(11).fontColor('#999')
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Button('添加').fontSize(12).height(26).backgroundColor('#F0F0F0').fontColor('#E23241')
                  .onClick(() => this.handleAddSong(song))
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }
          })
        }
      }
      .layoutWeight(1)

      Button('完成')
        .width('100%')
        .margin({ top: 10 })
        .backgroundColor('#E23241')
        .onClick(() => this.showAddSongDialog = false)
    }
    .width('100%')
    .height('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Stack({ alignContent: Alignment.Top }) {
        Image(this.coverImg)
          .width('100%')
          .height('50%')
          .blur(80)
          .opacity(0.4)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        Column() {
          // 2. 自定义导航栏
          Row() {
            Image($r('sys.media.ohos_ic_back'))
              .width(26)
              .height(26)
              .onClick(() => router.back())

            Blank()

            Image($r('app.media.ic_more')) // 歌单全局更多操作
              .width(22)
              .height(22)
              .bindMenu([
                {
                  value: '修改歌单信息', action: () => { /* 调用 updatePlaylist */
                }
                },
              ])
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 12
          })

          // 3. 歌单封面与信息区
          Row({ space: 20 }) {
            Image(this.coverImg)
              .width(145)
              .height(145)
              .borderRadius(12)
              .shadow({ radius: 30, color: '#44000000', offsetY: 15 })

            Column({ space: 8 }) {
              Text(this.playlistName)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111')
                .maxLines(2)

              Text('歌单')
                .fontSize(14)
                .fontColor('#E23241')
                .fontWeight(FontWeight.Medium)

              Text(`${this.songs.length} 首歌曲 · ${this.getTotalDuration()}`)
                .fontSize(12)
                .fontColor('#666')
                .margin({ top: 4 })

              Button('添加歌曲')
                .height(30)
                .fontSize(12)
                .backgroundColor('#1A000000')
                .fontColor('#111')
                .margin({ top: 10 })
                .onClick(() => this.showAddSongDialog = true)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 30 })

          // 4. 列表容器
          List() {
            // 播放控制快捷键
            ListItem() {
              Row({ space: 15 }) {
                Button() {
                  Row({ space: 8 }) {
                    Image($r('app.media.ic_play')).width(18).fillColor(Color.White)
                    Text('播放').fontColor(Color.White).fontWeight(FontWeight.Bold)
                  }
                }
                .layoutWeight(1)
                .height(45)
                .backgroundColor('#E23241')
                .borderRadius(10)
                .onClick(() => {
                  if (this.songs.length > 0) avPlayerManage.playResources(this.songs[0])
                })

                Button() {
                  Row({ space: 8 }) {
                    Image($r('app.media.ic_random')).width(18).fillColor('#E23241')
                    Text('随机播放').fontColor('#E23241').fontWeight(FontWeight.Bold)
                  }
                }
                .layoutWeight(1)
                .height(45)
                .backgroundColor('#12E23241')
                .borderRadius(10)
                .onClick(() => {
                  if (this.songs.length > 0) this.globalMusic.playbackStatus = '随机播放';
                  avPlayerManage.nextSong()
                })
              }
              .padding({
                left: 16,
                right: 16,
                bottom: 15,
                top: 15
              })
            }

            ForEach(this.songs, (song: SongItemType, index: number) => {
              ListItem() {
                this.BuildSongItem(song, index)
              }
            }, (item: SongItemType) => item.id)

            ListItem() {
              Row().height(100)
            } // 占位
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 30, topRight: 30 })
          .shadow({ radius: 20, color: '#0D000000', offsetY: -5 })
        }
        .width('100%')
        .height('100%')


        // 5. 底部搜索半屏弹窗
        if (this.showAddSongDialog) {
          Column() {
            Blank().onClick(() => this.showAddSongDialog = false)
            this.BuildAddSongDialog()
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.move(TransitionEdge.BOTTOM),
            TransitionEffect.move(TransitionEdge.BOTTOM)
          ))
        }
      }
      .width('100%')
      .height('100%')
      MiniPlayBar({ musicState: this.globalMusic })
    }
    .width('100%')
    .height('100%')
  }
}
