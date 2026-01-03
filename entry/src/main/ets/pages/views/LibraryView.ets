// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { promptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit'; // 1. 导入振动服务
import { BusinessError } from '@kit.BasicServicesKit';

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();
  @Local isEditSheetOpen: boolean = false; // 控制编辑页打开
  @Local editingSong: SongItemType | null = null; //正在编辑的歌曲
  @Local editingLyricText: string = ""; // 正在编辑的歌词文本

  saveSongInfo() {
    if (this.editingSong) {
      // 在这里处理保存逻辑，比如写入文件或更新数据库
      //  如果有歌词输入，保存歌词路径或内容
      this.editingSong.hasLyric = this.editingLyricText.length > 0;
      promptAction.showToast({ message: "保存成功 (模拟)" });
      this.isEditSheetOpen = false;
    }
  }

  @Builder
  EditSongSheet() {
    Column() {
      Text("编辑歌曲信息")
        .fontSize(20)
        .fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 20 })
      List() {
        ListItem() {
          Column({ space: 10 }) {
            Text("歌名").fontSize(14).fontColor(Color.Gray)
            TextInput({ text: this.editingSong?.name, placeholder: "请输入歌名" }).onChange((val) => {
              if (this.editingSong) {
                this.editingSong.name = val
              }
            })
            Text("歌手").fontSize(14).fontColor(Color.Gray)
            TextInput({ text: this.editingSong?.author, placeholder: "请输入歌手" }).onChange((val) => {
              if (this.editingSong) {
                this.editingSong.author = val
              }
            })
            Text("歌词 (LRC格式)").fontSize(14).fontColor(Color.Gray).margin({ top: 10 })
            TextArea({ text: this.editingLyricText, placeholder: "[00:00.00]在此粘贴LRC歌词..." })
              .height(200)
              .onChange((val) => {
                this.editingLyricText = val
              })
          }.alignItems(HorizontalAlign.Start)
        }
      }.layoutWeight(1).width('100%').padding(20)

      Button("保存修改").width('90%').margin({ bottom: 20 }).onClick(() => this.saveSongInfo())
    }.height('80%') // Sheet 高度
    .backgroundColor(Color.White)
  }

    // 触发振动的封装函数
    triggerVibration() {
      try {
        // 使用预置的触感振动效果 (haptic.style.heavy 或 medium)
        vibrator.startVibration({
          type: 'preset',
          effectId: 'haptic.style.medium',
          count: 1
        }, {
          usage: 'touch'
        });
      } catch (error) {
        const err = error as BusinessError;
        console.error(`Failed to start vibration, code: ${err.code}, message: ${err.message}`);
      }
    }

    // 2. 定义“悬浮”时的样式 (Preview)
    // 这是长按那一瞬间，用户手里“捏”着的那个组件的样子
    @Builder
    SongItemPreview(item:
    SongItemType
    )
    {
      Row() {
        Image((item.img) || $r('app.media.ic_music'))
          .width(50)
          .height(50)
          .borderRadius(6)
          .margin({ right: 15 })
          .fillColor(Color.Gray)

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
      .borderRadius(12) // 增加圆角，体现悬浮感
      // 增加阴影，体现Z轴高度，让它看起来浮在半空
      .shadow({ radius: 20, color: 'rgba(0,0,0,0.2)', offsetY: 10 })
    }

    // 3. 菜单构建器
    @Builder
    MusicActionMenu(
      item: SongItemType,
      index: number
    ) {
      Menu() {
        MenuItem({ content: "播放", startIcon: $r('app.media.ic_music') }) // 假设有图标
          .onClick(() => {
            this.musicState.isPlay = true;
            avPlayerManage.playResources(item);
          })

        MenuItem({ content: "添加到歌单" })
          .onClick(() => promptAction.showToast({ message: "功能开发中" }))

        MenuItem({ content: "查看详情" })
          .onClick(() => promptAction.showToast({ message: `歌曲ID: ${item.id}` }))
        MenuItem({ content: "编辑信息/歌词" })
          .onClick(() => {          // 初始化编辑数据
            this.editingSong = {
              id: item.id,
              name: item.name,
              author: item.author,
              img: item.img,
              filePath: item.filePath,
              lyricPath: item.lyricPath,
              hasLyric: item.hasLyric
            }; // 浅拷贝，防止直接修改原数据
            //  这里应该读取真实的歌词文件内容，这里暂用空或假数据模拟
             this.editingLyricText = "[00:00.00]暂无歌词，请粘贴...";
             this.isEditSheetOpen = true; // 打开 Sheet
            })
        MenuItem({ content: "删除" })
          .contentFontColor(Color.Red)
          .onClick(() => avPlayerManage.deleteSong(index))
      }
      // 关键点：菜单出现时触发振动
      .onAppear(() => {
        this.triggerVibration();
      })
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
            // 这里为了代码简洁，省略了 empty 判断逻辑，保留核心列表项
            if (this.musicState.songList && this.musicState.songList.length > 0) {
              Row() {
                Image((item.img) || $r('app.media.ic_music'))
                  .width(50)
                  .height(50)
                  .borderRadius(6)
                  .margin({ right: 15 })
                  .fillColor(Color.Gray)

                  Column() {
                    Text(item.name)
                      .fontSize(16)
                      // 选中高亮逻辑
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

                  Image($r('app.media.ic_more'))
                    .width(20)
                    .height(20)
                    .fillColor(Color.Gray)
                }
                .width('100%')
                .padding({
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 10
                })
                .backgroundColor(Color.White)
                .onClick(() => {
                  this.musicState.isPlay = true;
                  avPlayerManage.playResources(item)
                })
                // 4. 绑定上下文菜单，并配置 Preview 和样式
                .bindContextMenu(
                  this.MusicActionMenu(item, index), // 菜单内容
                  ResponseType.LongPress, // 响应方式：长按
                  {
                    // 启用背景模糊 (API 10+ 默认通常为 true，显式声明更保险)
                    enableArrow: false, // 是否显示小箭头，关闭后更像 iOS 风格
                    preview: this.SongItemPreview(item), // 传入自定义的悬浮预览组件
                    backgroundColor: Color.Transparent // 菜单容器背景透明，避免遮挡圆角
                  }
                )
              }
            }
          })
          ListItem().height(90)
        }
        .width('100%')
        .height('100%')
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
