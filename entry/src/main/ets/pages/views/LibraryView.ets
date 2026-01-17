// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerManager';
import { promptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { lyricManager } from '../../utils/LyricManager'; // 确保导入路径正确
import { picker } from '@kit.CoreFileKit'; // 导入选择器模块
import { fileIo as fs } from '@kit.CoreFileKit'; // 确保有 fs 别名用于读取外部文件
import { util } from '@kit.ArkTS';
import RdbManager from '../../utils/RdbManager';

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();
  @Local isEditSheetOpen: boolean = false; // 控制编辑页打开
  @Local editingSong: SongItemType | null = null; // 正在编辑的歌曲
  @Local editingLyricText: string = ""; // 正在编辑的歌词文本
  @Local forceRefreshKey: string = "0";

  private forceUpdateUI() {
    this.forceRefreshKey = new Date().getTime().toString() + Math.random().toString(36).substring(2);
  }

  async importLyricFromFile() {
    if (!this.editingSong) return;
    const songId = this.editingSong.id;

    try {
      // 1. 选择文件
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.fileSuffixFilters = ['.lrc'];
      documentSelectOptions.maxSelectNumber = 1;
      const documentViewPicker = new picker.DocumentViewPicker();
      const uris = await documentViewPicker.select(documentSelectOptions);

      if (!uris || uris.length === 0) return;
      const selectedUri = uris[0];

      // 2. 获取该歌曲在沙箱中预定的歌词物理路径
      // 这个路径类似于: /data/storage/el2/base/files/lyrics/song123.lrc
      const destPath = lyricManager.getOrCreateLyricPath(songId);

      // 3. 【核心技术突破】通过文件句柄 (FD) 进行物理拷贝
      // 这种方法 100% 避开 13900002 错误，因为它不依赖系统对虚拟路径的解析
      let srcFile = fs.openSync(selectedUri, fs.OpenMode.READ_ONLY);
      let destFile = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);

      // 直接在系统底层进行数据流拷贝
      fs.copyFileSync(srcFile.fd, destFile.fd);

      fs.closeSync(srcFile);
      fs.closeSync(destFile);

      // 4. 从刚拷贝成功的【物理路径】读取内容，用于显示在 TextArea
      let content = fs.readTextSync(destPath);

      if (content) {
        // A. 更新 UI 预览变量
        this.editingLyricText = content;

        // C. 更新当前正在编辑的对象属性
        this.editingSong.lyricPath = destPath;
        this.editingSong.hasLyric = true;

        promptAction.showToast({ message: "歌词导入成功" });
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`导入失败: 代码 ${error.code}, 原因: ${error.message}`);
      promptAction.showToast({ message: "导入失败，请检查文件" });
    }
  }
  /**
   * 保存修改后的歌曲信息及歌词
   */
  async saveSongInfo() {
    if (this.editingSong && this.editingSong.id) {
      const songId = this.editingSong.id;
      const lyricText = this.editingLyricText.trim();
      const destPath = lyricManager.getOrCreateLyricPath(songId);

      if (lyricText.length > 0) {
        this.editingSong.hasLyric = true;
        if(this.editingSong.id === this.musicState.currentID){
          this.musicState.hasLyric = true;
          this.musicState.lyricPath = destPath;
        }
      } else {
        // 如果歌词被清空了
        this.editingSong.hasLyric = false;
      }
      lyricManager.saveLyricFile(destPath, lyricText);
      await RdbManager.updateSongLyric(songId, destPath, lyricText.length > 0);

      // 4. 同步更新全局列表（触发 UI 刷新）
      const updatedSong: SongItemType = copySong(this.editingSong)
      this.musicState.songList = this.musicState.songList.map(s => s.id === songId ? updatedSong : s);
      promptAction.showToast({ message: "保存成功" });
      this.isEditSheetOpen = false;
      this.forceUpdateUI();
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

            // 修改歌词标签行
            Row() {
              Text("歌词 (LRC格式)").fontSize(14).fontColor(Color.Gray).margin({ top: 10 })
              Blank()
              // 修改后的导入按钮：仅显示 + 号
              Button("+", { type: ButtonType.Circle })
                .fontSize(20)            // 让加号大一点
                .fontWeight(FontWeight.Bold)
                .width(28)               // 调整按钮宽度
                .height(28)              // 调整按钮高度
                .backgroundColor('#007DFF')
                .onClick(() => this.importLyricFromFile())
            }
            .width('100%')
            .margin({ top: 10 })


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
      // 触发马达振动
      vibrator.startVibration({
        type: 'preset',
        effectId: 'haptic.effect.soft',
        count: 1,
        intensity: 50,
      }, {
        usage: 'unknown'
      }, (error: BusinessError) => {
        if (error) {
          console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
        } else {
          console.info('Succeed in starting vibration');
        }
      });
    }catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`An unexpected error occurred. Code: ${e.code}, message: ${e.message}`);
    }
  }

  @Builder
  SongItemPreview(item: SongItemType) {
    Row() {
      Image(item.img || $r('app.media.ic_default'))
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
      MenuItem({ content: "播放", startIcon: $r('app.media.ic_default') })
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
                RdbManager.deleteSongById(item.id);
              }
            })
          }
        })
    }
    .onAppear(() => { setTimeout(() => {
      this.triggerVibration();
    }, 100); })
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
              Image(item.img || $r('app.media.ic_default'))
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
    .key(this.forceRefreshKey)
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