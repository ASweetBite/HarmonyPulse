// src/main/ets/pages/PlaylistDetail.ets
import { promptAction, router } from '@kit.ArkUI';
import { SongItemType } from '../type/SongItemType';
import { avPlayerManage } from '../utils/avPlayerMusic';
import RdbManager from '../utils/RdbManager';

interface DialogResult {
  index: number;
}

@Entry
@Component
struct PlaylistDetail {
  @State playlistName: string = '未命名歌单';
  @State songs: SongItemType[] = [];  // 歌单中的歌曲
  @State showAddSongDialog: boolean = false;
  @State searchKeyword: string = '';
  @State searchResults: SongItemType[] = [];  // 用于对话框的搜索结果
  @State isLoading: boolean = false;  // 加载状态

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const name = params?.playlistName;
    this.playlistName = (name && name.trim().length > 0) ? name : '未命名歌单';
    this.loadPlaylistSongs();
  }

  private loadPlaylistSongs(): void {
    const playlistSongs = AppStorage.get<SongItemType[]>(`playlist_${this.playlistName}`);
    this.songs = playlistSongs ?? [];
  }

  private isSongInPlaylist(songId: string): boolean {
    return this.songs.some((item: SongItemType) => item.id === songId);
  }

  // 从数据库搜索歌曲
  private async searchSongsFromDB(): Promise<void> {
    if (!this.searchKeyword.trim()) {
      this.searchResults = [];  // 清空搜索结果
      return;
    }

    this.isLoading = true;
    try {
      const results = await RdbManager.searchSongs(this.searchKeyword);
      // 过滤掉已经在歌单中的歌曲
      this.searchResults = results.filter(song => !this.isSongInPlaylist(song.id));
    } catch (error) {
      console.error('搜索歌曲失败:', error);
      this.searchResults = [];
      promptAction.showToast({
        message: '搜索失败，请重试',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private getTotalDuration(): string {
    if (this.songs.length === 0) return '0分钟';
    const totalMinutes: number = this.songs.length * 3.5;
    const h: number = Math.floor(totalMinutes / 60);
    const m: number = Math.floor(totalMinutes % 60);
    return h > 0 ? `${h}小时${m}分钟` : `${m}分钟`;
  }

  /** 添加歌曲到歌单 */
  private addSongToPlaylist(song: SongItemType): void {
    if (this.isSongInPlaylist(song.id)) {
      promptAction.showToast({
        message: '歌曲已在歌单中',
        duration: 1000
      });
      return;
    }

    const updated: SongItemType[] = [...this.songs, song];
    this.songs = updated;
    AppStorage.set(`playlist_${this.playlistName}`, updated);

    // 从搜索结果中移除已添加的歌曲
    this.searchResults = this.searchResults.filter(s => s.id !== song.id);

    promptAction.showToast({
      message: `已添加「${song.name}」`,
      duration: 1500
    });
  }

  private removeSongFromPlaylist(songId: string): void {
    promptAction.showDialog({
      title: '确认移除',
      message: '确定要从歌单中移除这首歌吗？',
      buttons: [
        { text: '取消', color: '#666' },
        { text: '移除', color: '#FF6B6B' }
      ]
    }).then((res: DialogResult) => {
      if (res.index === 1) {
        const songToRemove = this.songs.find(song => song.id === songId);
        const updated: SongItemType[] = this.songs.filter((item: SongItemType) => item.id !== songId);
        this.songs = updated;
        AppStorage.set(`playlist_${this.playlistName}`, updated);

        promptAction.showToast({
          message: `已移除「${songToRemove?.name}」`,
          duration: 1500
        });
      }
    });
  }

  @Builder
  BuildSongItem(song: SongItemType, index: number) {
    Row({ space: 12 }) {
      Text(`${index + 1}`)
        .width(30)
        .textAlign(TextAlign.Center)
        .fontSize(14)
        .fontColor('#666');

      Image(song.img)
        .width(50)
        .height(50)
        .borderRadius(8)
        .objectFit(ImageFit.Contain);

      Column({ space: 4 }) {
        Text(song.name)
          .fontSize(16)
          .fontColor(Color.Black)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        Text(song.author)
          .fontSize(12)
          .fontColor('#666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Button('移除')
        .fontSize(12)
        .backgroundColor('#FF6B6B')
        .fontColor(Color.White)
        .onClick((): void => {
          this.removeSongFromPlaylist(song.id);
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick((): void => {
      avPlayerManage.playResources(song);
    });
  }

  @Builder
  BuildAddSongDialog() {
    Column() {
      Text('添加歌曲')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 });

      TextInput({ placeholder: '搜索歌曲' })
        .width('100%')
        .onChange((value: string): void => {
          this.searchKeyword = value;
          // 防抖搜索，避免频繁搜索
          setTimeout(() => {
            this.searchSongsFromDB();
          }, 300);
        })
        .margin({ bottom: 12 });

      if (this.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#E23241');
          Text('搜索中...')
            .fontSize(14)
            .fontColor('#999')
            .margin({ top: 10 });
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.searchResults.length > 0) {
        // 显示搜索结果
        List({ space: 8 }) {
          ForEach(
            this.searchResults,
            (song: SongItemType): void => {
              ListItem() {
                Row({ space: 12 }) {
                  Image(song.img)
                    .width(40)
                    .height(40)
                    .borderRadius(6)
                    .objectFit(ImageFit.Contain);

                  Column({ space: 2 }) {
                    Text(song.name)
                      .fontSize(14)
                      .fontColor(Color.Black)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis });

                    Text(song.author)
                      .fontSize(12)
                      .fontColor('#666')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis });
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start);

                  Button('添加')
                    .fontSize(12)
                    .backgroundColor('#E23241')
                    .fontColor(Color.White)
                    .onClick((): void => {
                      this.addSongToPlaylist(song);
                    });
                }
                .width('100%')
                .padding(12);
              }
            },
            (song: SongItemType): string => song.id
          );
        }
        .layoutWeight(1);
      } else {
        // 无结果状态
        Column() {
          if (this.searchKeyword.trim()) {
            Text('未找到相关歌曲')
              .fontSize(14)
              .fontColor('#999');
            Text('请尝试其他关键词')
              .fontSize(12)
              .fontColor('#CCC')
              .margin({ top: 8 });
          } else {
            Text('输入关键词搜索歌曲')
              .fontSize(14)
              .fontColor('#999');
            Text('支持歌曲名和歌手搜索')
              .fontSize(12)
              .fontColor('#CCC')
              .margin({ top: 8 });
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      }

      Row({ space: 15 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#F0F0F0')
          .fontColor('#666')
          .onClick((): void => {
            this.showAddSongDialog = false;
            this.searchKeyword = '';
            this.searchResults = [];
          });

        Button('完成')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#E23241')
          .fontColor(Color.White)
          .onClick((): void => {
            this.showAddSongDialog = false;
            this.searchKeyword = '';
            this.searchResults = [];
          });
      }
      .width('100%')
      .margin({ top: 20 });
    }
    .width('80%')
    .height('70%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16);
  }

  build() {
    Stack() {
      Column() {
        // 头部
        Row({ space: 10 }) {
          Button('<')
            .fontSize(20)
            .width(30)
            .height(30)
            .backgroundColor(Color.Transparent)
            .fontColor('#333')
            .onClick((): void => {
              router.back();
            });

          Text(this.playlistName)
            .layoutWeight(1)
            .fontSize(20)
            .fontWeight(FontWeight.Bold);

          Button('添加歌曲')
            .fontSize(14)
            .onClick((): void => {
              this.showAddSongDialog = true;
              this.searchResults = [];
            });
        }
        .padding(12)
        .backgroundColor(Color.White);

        // 统计信息
        Row({ space: 20 }) {
          Column({ space: 4 }) {
            Text(this.songs.length.toString())
              .fontSize(20)
              .fontColor('#E23241')
              .fontWeight(FontWeight.Bold);
            Text('歌曲数')
              .fontSize(12)
              .fontColor('#666');
          }

          Column({ space: 4 }) {
            Text(this.getTotalDuration())
              .fontSize(20)
              .fontColor('#E23241')
              .fontWeight(FontWeight.Bold);
            Text('总时长')
              .fontSize(12)
              .fontColor('#666');
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F8F8F8')
        .justifyContent(FlexAlign.SpaceAround);

        // 歌曲列表
        if (this.songs.length > 0) {
          List({ space: 1 }) {
            ForEach(
              this.songs,
              (song: SongItemType, index: number): void => {
                ListItem() {
                  this.BuildSongItem(song, index);
                }
              },
              (song: SongItemType): string => song.id
            );
          }
          .layoutWeight(1);
        } else {
          // 空状态
          Column() {
            Text('♪')
              .fontSize(60)
              .fontColor('#999')
              .margin({ bottom: 16 });
            Text('歌单暂无歌曲')
              .fontSize(16)
              .fontColor('#999')
              .margin({ bottom: 6 });
            Text('点击"添加歌曲"开始构建您的歌单')
              .fontSize(14)
              .fontColor('#CCC');
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5');

      // 对话框遮罩
      if (this.showAddSongDialog) {
        Column()
          .backgroundColor('#00000066')
          .width('100%')
          .height('100%')
          .onClick((): void => {
            this.showAddSongDialog = false;
            this.searchKeyword = '';
            this.searchResults = [];
          });

        Column() {
          this.BuildAddSongDialog();
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Center);
      }
    }
    .width('100%')
    .height('100%');
  }
}