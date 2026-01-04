// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { promptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { lyricManager } from '../../utils/LyricManager'; // 确保导入路径正确

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();
  @Local isEditSheetOpen: boolean = false; // 控制编辑页打开
  @Local editingSong: SongItemType | null = null; // 正在编辑的歌曲
  @Local editingLyricText: string = ""; // 正在编辑的歌词文本

  /**
   * 保存修改后的歌曲信息及歌词
   */
  saveSongInfo() {
    if (this.editingSong && this.editingSong.id) {
      const songId = this.editingSong.id;
      const lyricText = this.editingLyricText.trim();

      if (lyricText.length > 0) {
        // 1. 使用单例获取路径（内部已包含 Context 逻辑）
        const path = lyricManager.getOrCreateLyricPath(songId);

        // 2. 使用单例保存内容
        lyricManager.saveLyricFile(path, lyricText);
        this.editingSong.hasLyric = true;
      } else {
        // 如果歌词被清空了
        this.editingSong.hasLyric = false;
      }

      // 4. 同步更新全局列表（触发 UI 刷新）
      const index = this.musicState.songList.findIndex(s => s.id === songId);
      if (index !== -1) {
        const updatedSong: SongItemType = copySong(this.editingSong)
        // 使用 splice 确保数组响应式更新
        this.musicState.songList.splice(index, 1, updatedSong);
      }

      promptAction.showToast({ message: "保存成功" });
      this.isEditSheetOpen = false;
    }
  }

  @Builder
  EditSongSheet() {
    Column() {
      Text("编辑歌曲信息")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      List() {
        ListItem() {
          Column({ space: 10 }) {
            Text("歌名").fontSize(14).fontColor(Color.Gray)
            TextInput({ text: this.editingSong?.name, placeholder: "请输入歌名" })
              .onChange((val) => {
                if (this.editingSong) this.editingSong.name = val;
              })

            Text("歌手").fontSize(14).fontColor(Color.Gray)
            TextInput({ text: this.editingSong?.author, placeholder: "请输入歌手" })
              .onChange((val) => {
                if (this.editingSong) this.editingSong.author = val;
              })

            Text("歌词 (LRC格式)").fontSize(14).fontColor(Color.Gray).margin({ top: 10 })
            TextArea({ text: this.editingLyricText, placeholder: "[00:00.00]在此粘贴LRC歌词..." })
              .height(250)
              .onChange((val) => {
                this.editingLyricText = val;
              })
          }.alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding(20)

      Button("保存修改")
        .width('90%')
        .margin({ bottom: 30 })
        .onClick(() => this.saveSongInfo())
    }
    .height('85%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  // 触发振动的封装函数
  triggerVibration() {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId: 'haptic.style.medium',
        count: 1
      }, { usage: 'touch' });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to start vibration, code: ${err.code}, message: ${err.message}`);
    }
  }

  @Builder
  SongItemPreview(item: SongItemType) {
    Row() {
      Image(item.img || $r('app.media.ic_music'))
        .width(50)
        .height(50)
        .borderRadius(6)
        .margin({ right: 15 })

      Column() {
        Text(item.name)
          .fontSize(16)
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.author)
          .fontSize(13)
          .fontColor(Color.Gray)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: 8 })
  }

  @Builder
  MusicActionMenu(item: SongItemType, index: number) {
    Menu() {
      MenuItem({ content: "播放", startIcon: $r('app.media.ic_music') })
        .onClick(() => {
          this.musicState.isPlay = true;
          avPlayerManage.playResources(item);
        })

      MenuItem({ content: "编辑信息/歌词" })
        .onClick(() => {
          // 初始化编辑数据（深拷贝防止直接修改列表）
          this.editingSong = copySong(item)

          // 使用单例读取真实的歌词文件内容
          if (item.lyricPath) {
            this.editingLyricText = lyricManager.readLyricFile(item.lyricPath);
          } else {
            this.editingLyricText = "";
          }
          this.isEditSheetOpen = true;
        })

      MenuItem({ content: '删除' })
        .contentFontColor(Color.Red)
        .onClick(() => {
          let uiContext = this.getUIContext();
          if (uiContext) {
            uiContext.getPromptAction().showDialog({
              title: '确认删除',
              message: '确定要删除这首歌曲吗？',
              buttons: [
                { text: '取消', color: '#999999' },
                { text: '删除', color: '#FF3B30' }
              ]
            }).then((result) => {
              if (result.index === 1) {
                avPlayerManage.deleteSong(index);
              }
            })
          }
        })
    }
    .onAppear(() => { this.triggerVibration(); })
  }

  build() {
    Column() {
      Text("资料库")
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .padding({ left: 20, top: 60, bottom: 10 })
        .backgroundColor(Color.White)

      Divider()

      List() {
        ForEach(this.musicState.songList, (item: SongItemType, index: number) => {
          ListItem() {
            Row() {
              Image(item.img || $r('app.media.ic_music'))
                .width(50)
                .height(50)
                .borderRadius(6)
                .margin({ right: 15 })

              Column() {
                Text(item.name)
                  .fontSize(16)
                  .fontColor(this.musicState.currentID === item.id ? '#E23241' : Color.Black)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(item.author)
                  .fontSize(13)
                  .fontColor(Color.Gray)
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 歌词标识图标
              if (item.hasLyric) {
                Text("LRC")
                  .fontSize(10)
                  .fontColor(Color.White)
                  .backgroundColor('#CCC')
                  .padding({ left: 4, right: 4 })
                  .borderRadius(4)
                  .margin({ right: 10 })
              }

              Image($r('app.media.ic_more'))
                .width(20)
                .height(20)
                .fillColor(Color.Gray)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .backgroundColor(Color.White)
            .onClick(() => {
              this.musicState.isPlay = true;
              avPlayerManage.playResources(item)
            })
            .bindContextMenu(
              this.MusicActionMenu(item, index),
              ResponseType.LongPress,
              {
                enableArrow: false,
                preview: this.SongItemPreview(item),
                backgroundColor: Color.Transparent
              }
            )
          }
        }, (item: SongItemType) => item.id) // 使用 id 作为 key 性能更好

        ListItem().height(100) // 底部留白，防止被播放条遮挡
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .bindSheet(this.isEditSheetOpen, this.EditSongSheet(), {
      height: SheetSize.LARGE,
      dragBar: true,
      onDisappear: () => { this.isEditSheetOpen = false }
    })
  }
}
function copySong(item: SongItemType): SongItemType {
  return {
    id: item.id,
    name: item.name,
    author: item.author,
    img: item.img,
    filePath: item.filePath,
    lyricPath: item.lyricPath,
    hasLyric: item.hasLyric
  }
}