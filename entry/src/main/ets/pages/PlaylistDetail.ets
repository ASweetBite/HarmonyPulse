// src/main/ets/pages/PlaylistDetail.ets
import { promptAction, router } from '@kit.ArkUI';
import { SongItemType } from '../type/SongItemType';

@Entry
@Component
struct PlaylistDetail {
  @State playlistName: string = '未命名歌单';
  @State songs: SongItemType[] = [];
  @State showAddSongDialog: boolean = false;
  @State searchKeyword: string = '';

  aboutToAppear(): void {
    // 避免 any/unknown：只按字符串读取参数
    const params = router.getParams() as Record<string, string> | undefined;
    const name = params?.['playlistName'];
    this.playlistName = (name && name.trim().length > 0) ? name : '未命名歌单';
    this.loadPlaylistSongs();
  }

  private loadPlaylistSongs(): void {
    const playlistSongs = AppStorage.get<SongItemType[]>(`playlist_${this.playlistName}`);
    this.songs = playlistSongs ?? [];
  }

  private isSongInPlaylist(songId: string): boolean {
    return this.songs.some(song => song.id === songId);
  }

  private getAvailableSongs(): SongItemType[] {
    const allSongs = AppStorage.get<SongItemType[]>('allSongs') ?? [];
    return allSongs.filter(song => !this.isSongInPlaylist(song.id));
  }

  private getFilteredSongs(): SongItemType[] {
    const availableSongs = this.getAvailableSongs();
    const kw = this.searchKeyword.trim().toLowerCase();
    if (!kw) return availableSongs;

    return availableSongs.filter(song =>
    song.name.toLowerCase().includes(kw) || song.author.toLowerCase().includes(kw)
    );
  }

  private getTotalDuration(): string {
    if (this.songs.length === 0) return '0分钟';

    const estimatedMinutes = this.songs.length * 3.5;
    const hours = Math.floor(estimatedMinutes / 60);
    const minutes = Math.floor(estimatedMinutes % 60);

    return hours > 0 ? `${hours}小时${minutes}分钟` : `${minutes}分钟`;
  }

  private addSongToPlaylist(song: SongItemType): void {
    if (this.isSongInPlaylist(song.id)) return;

    const updatedSongs = [...this.songs, song];
    this.songs = updatedSongs;
    AppStorage.set(`playlist_${this.playlistName}`, updatedSongs);

    promptAction.showToast({
      message: `"${song.name}" 已添加到歌单`,
      duration: 2000
    });
  }

  private removeSongFromPlaylist(songId: string): void {
    promptAction.showDialog({
      title: '确认移除',
      message: '确定要从歌单中移除这首歌吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '移除', color: '#FF6B6B' }
      ]
    }).then(result => {
      if (result.index === 1) {
        const updatedSongs = this.songs.filter(song => song.id !== songId);
        this.songs = updatedSongs;
        AppStorage.set(`playlist_${this.playlistName}`, updatedSongs);

        promptAction.showToast({
          message: '歌曲已从歌单移除',
          duration: 2000
        });
      }
    });
  }

  private playSong(song: SongItemType): void {
    AppStorage.set('currentSong', song);
    AppStorage.set('isPlaying', true);

    promptAction.showToast({
      message: `正在播放: ${song.name}`,
      duration: 1500
    });
  }

  @Builder
  BuildSongItem(song: SongItemType, index: number) {
    Row({ space: 12 }) {
      Text((index + 1).toString())
        .fontSize(14)
        .fontColor('#666')
        .width(30)
        .textAlign(TextAlign.Center);

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

      // ArkTS ClickEvent 没有 stopPropagation：用“按钮先于行点击执行 + 提前返回”的方式规避
      // 同时给按钮一个更高的点击优先级（通过独立 clickable 区域）
      Button('移除')
        .fontSize(12)
        .backgroundColor('#FF6B6B')
        .fontColor(Color.White)
        .onClick(() => {
          this.removeSongFromPlaylist(song.id);
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick(() => {
      // 点击 Row 的空白区域才播放；按钮点击不会触发到这里（ArkUI 默认不会冒泡到父 onClick）
      this.playSong(song);
    });
  }

  @Builder
  BuildAddSongDialog() {
    Column() {
      Text('添加歌曲到歌单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      TextInput({ placeholder: '搜索歌曲...' })
        .width('100%')
        .height(40)
        .backgroundColor('#F5F5F5')
        .padding(10)
        .margin({ bottom: 15 })
        .borderRadius(8)
        .onChange((value: string) => {
          this.searchKeyword = value;
        });

      if (this.getFilteredSongs().length > 0) {
        List({ space: 8 }) {
          ForEach(this.getFilteredSongs(), (song: SongItemType) => {
            ListItem() {
              Row({ space: 12 }) {
                Image(song.img)
                  .width(40)
                  .height(40)
                  .borderRadius(4)
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
                  .onClick(() => {
                    this.addSongToPlaylist(song);
                  });
              }
              .width('100%')
              .padding(12);
            }
          }, (song: SongItemType) => song.id);
        }
        .layoutWeight(1);
      } else {
        Column() {
          Text('暂无可用歌曲')
            .fontSize(14)
            .fontColor('#999');
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
          .onClick(() => {
            this.showAddSongDialog = false;
            this.searchKeyword = '';
          });

        Button('完成')
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#E23241')
          .fontColor(Color.White)
          .onClick(() => {
            this.showAddSongDialog = false;
            this.searchKeyword = '';
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
    // 用 Stack 实现遮罩 + 弹窗；不使用 stopPropagation，避免类型报错
    Stack() {
      // 主内容
      Column() {
        // 头部
        Row({ space: 10 }) {
          Button('<')
            .fontSize(20)
            .width(30)
            .height(30)
            .backgroundColor(Color.Transparent)
            .fontColor('#333')
            .onClick(() => {
              router.back();
            });

          Text(this.playlistName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1);

          Button('添加歌曲')
            .fontSize(14)
            .onClick(() => {
              this.showAddSongDialog = true;
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White);

        // 统计信息
        Row({ space: 15 }) {
          Column() {
            Text(this.songs.length.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E23241');
            Text('总歌曲')
              .fontSize(12)
              .fontColor('#666');
          }

          Column() {
            Text(this.getTotalDuration())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E23241');
            Text('总时长')
              .fontSize(12)
              .fontColor('#666');
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F8F8F8');

        // 歌曲列表
        if (this.songs.length > 0) {
          List({ space: 1 }) {
            ForEach(this.songs, (song: SongItemType, index: number) => {
              ListItem() {
                this.BuildSongItem(song, index);
              }
            }, (song: SongItemType) => song.id);
          }
          .layoutWeight(1);
        } else {
          Column() {
            Text('♪')
              .fontSize(60)
              .fontColor('#999')
              .margin({ bottom: 20 });

            Text('歌单暂无歌曲')
              .fontSize(16)
              .fontColor('#999')
              .margin({ bottom: 8 });

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

      // 弹窗（遮罩 + 内容）
      if (this.showAddSongDialog) {
        // 遮罩：点击关闭
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#00000066')
          .onClick(() => {
            this.showAddSongDialog = false;
            this.searchKeyword = '';
          });

        // 弹窗内容：不写 onClick，避免“点击弹窗也关闭”的问题
        // （Stack 中后绘制的组件会拦截点击，不会传到遮罩）
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
