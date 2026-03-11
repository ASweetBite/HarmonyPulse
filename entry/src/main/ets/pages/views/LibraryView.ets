// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/managers/avPlayerManager';
import { promptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { lyricManager } from '../../utils/managers/LyricManager'; // 确保导入路径正确
import { picker } from '@kit.CoreFileKit'; // 导入选择器模块
import { fileIo as fs } from '@kit.CoreFileKit'; // 确保有 fs 别名用于读取外部文件
import { util } from '@kit.ArkTS';
import RdbManager from '../../utils/managers/RdbManager';
import { MusicShareService } from '../../utils/services/MusicShareService';
import { MusicImportService } from '../../utils/services/MusicImportService';
import { common } from '@kit.AbilityKit';
import { harmonyShare, systemShare } from '@kit.ShareKit';

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();
  @Local isEditSheetOpen: boolean = false; // 控制编辑页打开
  @Local editingSong: SongItemType | null = null; // 正在编辑的歌曲
  @Local editingLyricText: string = ""; // 正在编辑的歌词文本
  @Local forceRefreshKey: string = "0";
  @Local selectedIds: string[] = [];    // 已选中的歌曲ID列表
  private isListening: boolean = false;

  // --- 1. 核心分享回调逻辑 ---
  private libraryImmersiveCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
    let songsToShare = this.musicState.songList;
    let title = "资料库";

    if (this.musicState.isSelecting) {
      if (this.selectedIds.length === 0) return;
      songsToShare = this.musicState.songList.filter(s => this.selectedIds.includes(s.id));
      title = `资料库 (选中${songsToShare.length}首)`;
    }

    // 获取刚才初始化的 Logo URI
    const logoUri = MusicShareService.getAppLogoUri();

    try {
      const sharedData = MusicShareService.buildCollectionSharedData(
        songsToShare,
        title,
        logoUri
      );

      if (sharedData) {
        await sharableTarget.share(sharedData);
      }
    } catch (err) {
      console.error('资料库分享失败', err);
    }
  };

  // --- 2. 监听器开关控制 ---
  private enableShare() {
    if (this.isListening) return;
    harmonyShare.on('gesturesShare', this.libraryImmersiveCallback);
    harmonyShare.on('knockShare', this.libraryImmersiveCallback);
    this.isListening = true;
    console.info('LibraryView: 开启分享监听');
  }

  private disableShare() {
    if (!this.isListening) return;
    harmonyShare.off('gesturesShare', this.libraryImmersiveCallback);
    harmonyShare.off('knockShare', this.libraryImmersiveCallback);
    this.isListening = false;
    console.info('LibraryView: 关闭分享监听');
  }

  // --- 3. 状态联动与生命周期 ---

  // 监听：如果播放页展开了，资料库必须关闭监听（互斥）
  @Monitor("musicState.isFullPage")
  onPlayerExpansionChange() {
    this.updateListenerState();
  }

  private updateListenerState() {
    // 只有当：播放页没展开 且 应用在前台 时，资料库才抢占监听权
    if (!this.musicState.isFullPage) {
      this.enableShare();
    } else {
      this.disableShare();
    }
  }

  // 处理前后台切换 (由 EntryAbility 触发)
  private onForeGround = () => {
    this.updateListenerState();
  }

  private onBackGround = () => {
    this.disableShare();
  }

  aboutToAppear() {
    let context = getContext(this) as common.UIAbilityContext;
    context.eventHub.on('onForeGround', this.onForeGround);
    context.eventHub.on('onBackGround', this.onBackGround);

    // 初始化状态
    this.updateListenerState();
  }

  aboutToDisappear() {
    let context = getContext(this) as common.UIAbilityContext;
    context.eventHub.off('onForeGround', this.onForeGround);
    context.eventHub.off('onBackGround', this.onBackGround);
    this.disableShare();
  }

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

      MenuItem({ content: "分享" })
        .onClick(() => {
            MusicShareService.shareSong(item)
        })

      MenuItem({ content: "多选"}) // 建议添加一个图标
        .onClick(() => {
          animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
            this.musicState.isSelecting = true;
          });
          this.selectedIds = [item.id];
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
                if(item.id === this.musicState.currentID)
                  avPlayerManage.nextSong();
                avPlayerManage.deleteSong(index);
                RdbManager.deleteSongById(item.id);
                const context = getContext(this) as common.UIAbilityContext;
                MusicImportService.deleteSongs(context,item)
              }
            })
          }
        })
    }
    .onAppear(() => { setTimeout(() => {
      this.triggerVibration();
    }, 100); })
  }

  @Builder
  MultiSelectActionBar() {
    Row() {
      // 1. 批量删除
      Column() {
        Image($r('app.media.ic_delete')).width(24).height(24).fillColor(Color.Red)
        Text("删除").fontSize(12).fontColor(Color.Red).margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => this.handleBatchDelete())

      // 2. 批量分享
      Column() {
        Image($r('app.media.ic_share')).width(24).height(24)
        Text("分享").fontSize(12).margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => this.handleBatchShare())

      // 3. 添加到歌单
      Column() {
        Image($r('app.media.ic_add_to_playlist')).width(24).height(24)
        Text("收藏").fontSize(12).margin({ top: 4 })
      }
      .layoutWeight(1)
      .onClick(() => {
        promptAction.showToast({ message: "功能开发中：弹出歌单选择列表" })
      })
    }
    .width('100%')
    .height(80)
    .backgroundColor('#F9F9F9')
    .padding({ bottom: 20 })
    .border({ width: { top: 1 }, color: '#EEEEEE' })
  }

  // 批量删除逻辑
  async handleBatchDelete() {
    if (this.selectedIds.length === 0) return;

    const result = await this.getUIContext().getPromptAction().showDialog({
      title: '批量删除',
      message: `确定要删除选中的 ${this.selectedIds.length} 首歌曲吗？`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#FF3B30' }
      ]
    });

    if (result.index === 1) {
      const context = getContext(this) as common.UIAbilityContext;

      // 过滤出未被选中的歌曲，更新 UI
      const remainingSongs = this.musicState.songList.filter(s => !this.selectedIds.includes(s.id));
      const deleteSongs = this.musicState.songList.filter(s => this.selectedIds.includes(s.id));

      for (let song of deleteSongs) {
        // 如果正在播放其中一首，先切歌
        if (song.id === this.musicState.currentID) {
          avPlayerManage.nextSong();
        }
        // 数据库和物理文件删除
        await RdbManager.deleteSongById(song.id);
        await MusicImportService.deleteSongs(context, song);
      }

      this.musicState.songList = remainingSongs;
      this.exitSelectMode();
      promptAction.showToast({ message: "已批量删除" });
    }
  }

  // 批量分享逻辑
  handleBatchShare() {
    if (this.selectedIds.length === 0) return;
    const songsToShare = this.musicState.songList.filter(s => this.selectedIds.includes(s.id));

    MusicShareService.shareSongs(songsToShare);
    this.exitSelectMode();
  }

  exitSelectMode() {
    animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
      this.musicState.isSelecting = false;
    });
    this.selectedIds = [];
  }

  build() {
    // 使用 Stack 容器，确保多选操作栏可以浮在最上层或固定在底部
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // --- 动态标题栏 ---
        Row() {
          if (this.musicState.isSelecting) {
            // 多选模式标题
            Text(`已选择 ${this.selectedIds.length} 首`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)

            Text("全选")
              .fontSize(16)
              .fontColor('#E23241')
              .margin({ right: 20 })
              .onClick(() => {
                // 全选逻辑：将所有歌曲 ID 放入数组
                this.selectedIds = this.musicState.songList.map(s => s.id);
              })

            Text("完成")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.Black)
              .onClick(() => this.exitSelectMode())
          } else {
            // 普通模式标题
            Text("资料库")
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)
              .layoutWeight(1)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 60, bottom: 10 })
        .backgroundColor(Color.White)

        Divider()

        List() {
          ForEach(this.musicState.songList, (item: SongItemType, index: number) => {
            ListItem() {
              Row() {
                // --- 多选模式：显示复选框 ---
                if (this.musicState.isSelecting) {
                  Checkbox({ name: item.id, group: 'songs' })
                    .select(this.selectedIds.includes(item.id))
                    .selectedColor('#E23241')
                    .width(20)
                    .margin({ right: 15 })
                    .onChange((value: boolean) => {
                      if (value) {
                        if (!this.selectedIds.includes(item.id)) {
                          this.selectedIds.push(item.id);
                        }
                      } else {
                        this.selectedIds = this.selectedIds.filter(id => id !== item.id);
                      }
                    })
                }

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
                if (this.musicState.isSelecting) {
                  // 多选模式：点击整行切换选中状态
                  const isSelected = this.selectedIds.includes(item.id);
                  if (isSelected) {
                    this.selectedIds = this.selectedIds.filter(id => id !== item.id);
                  } else {
                    this.selectedIds.push(item.id);
                  }
                } else {
                  // 普通模式：播放
                  this.musicState.isPlay = true;
                  avPlayerManage.playResources(item);
                }
              })
              // 多选模式下禁用长按菜单
              .bindContextMenu(
                this.musicState.isSelecting ? null : this.MusicActionMenu(item, index),
                ResponseType.LongPress,
                {
                  enableArrow: false,
                  preview: this.SongItemPreview(item),
                  backgroundColor: Color.Transparent
                }
              )
            }
          }, (item: SongItemType) => item.id + this.musicState.isSelecting) // ID 加上模式后缀强制刷新组件

          // 底部留白：多选模式需要留出操作栏的高度
          ListItem().height(this.musicState.isSelecting ? 160 : 100)
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')

      // --- 底部批量操作栏 ---
      if (this.musicState.isSelecting) {
        Row() {
          // 批量删除
          Column() {
            Image($r('app.media.ic_delete'))
              .width(24).height(24).fillColor(this.selectedIds.length > 0 ? Color.Red : '#999')
            Text("删除").fontSize(12).margin({ top: 4 })
              .fontColor(this.selectedIds.length > 0 ? Color.Red : '#999')
          }
          .layoutWeight(1)
          .onClick(() => this.handleBatchDelete())

          // 批量分享
          Column() {
            Image($r('app.media.ic_share'))
              .width(24).height(24).fillColor(this.selectedIds.length > 0 ? Color.Black : '#999')
            Text("分享").fontSize(12).margin({ top: 4 })
              .fontColor(this.selectedIds.length > 0 ? Color.Black : '#999')
          }
          .layoutWeight(1)
          .onClick(() => this.handleBatchShare())

          // 添加至歌单
          Column() {
            Image($r('app.media.ic_add_to_playlist'))
              .width(24).height(24).fillColor(this.selectedIds.length > 0 ? Color.Black : '#999')
            Text("收藏").fontSize(12).margin({ top: 4 })
              .fontColor(this.selectedIds.length > 0 ? Color.Black : '#999')
          }
          .layoutWeight(1)
          .onClick(() => {
            if (this.selectedIds.length > 0) {
              promptAction.showToast({ message: "功能开发中..." })
            }
          })
        }
        .width('94%')
        .height(72)
        .margin({ left: '3%', right: '3%', bottom: 24 }) // 居中悬浮
        .borderRadius(24)
        // 1. 高斯模糊：使用系统超薄材质
        .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
        .backgroundColor('rgba(255, 255, 255, 0.4)') // 配合模糊的半透明底色
        .shadow({ radius: 30, color: 'rgba(0,0,0,0.1)', offsetY: 10 })
        .padding({ left: 10, right: 10 })
        // 2. 修正后的转场动画：从底部滑入/滑出
        .transition(
          TransitionEffect.asymmetric(
            // 进场：从底部边缘滑入 + 渐显
            TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY),
            // 出场：向底部边缘滑出 + 渐隐
            TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY)
          ).animation({ duration: 300, curve: Curve.EaseInOut })
        )
      }
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
