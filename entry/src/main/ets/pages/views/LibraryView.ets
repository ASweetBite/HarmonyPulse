// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { promptAction } from '@kit.ArkUI'; // 导入弹窗工具，用于演示未实现的功能

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();

  // 1. 定义长按弹出的菜单
  @Builder
  MusicActionMenu(item: SongItemType, index: number) {
    Menu() {
      // 选项一：详情
      MenuItem({ content: "歌曲详情" })
        .onClick(() => {
          // 这里写跳转详情页的逻辑
          try {
            promptAction.showToast({ message: `查看: ${item.name}` });
          } catch (error) {
            // TODO: Implement error handling.
          }
        })

      // 选项二：添加到歌单
      MenuItem({ content: "添加到歌单" })
        .onClick(() => {
          // 这里写添加到歌单的逻辑
          try {
            promptAction.showToast({ message: "添加到歌单功能待开发" });
          } catch (error) {
            // TODO: Implement error handling.
          }
        })

      // 选项三：删除 (通常删除用红色警示)
      MenuItem({ content: "删除" })
        .contentFontColor(Color.Red)
        .onClick(() => {
          // 调用之前的删除逻辑
          avPlayerManage.deleteSong(index);
        })
    }
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
        // 注意：原代码逻辑中，如果 list 为空，ForEach 不会执行，因此"暂无歌曲"永远不会显示。
        // 建议在 List 外层或使用 if/else 包裹 List 来处理空状态，这里保留原结构仅修改交互。
        ForEach(this.musicState.playList, (item: SongItemType, index: number) => {
          ListItem() {
            if (this.musicState.playList?.length === 0) {
              Text("暂无歌曲数据")
                .fontSize(16)
                .fontColor(Color.Gray)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(50)
            } else {
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
                // 也可以给这个小图标单独绑定点击事件弹出菜单，看交互需求
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
              .onClick(() => {
                // 单击播放
                this.musicState.isPlay = true;
                avPlayerManage.playResources(item);
              })
              // 2. 绑定上下文菜单，设置响应类型为长按 (LongPress)
              .bindContextMenu(this.MusicActionMenu(item, index), ResponseType.LongPress)
            }
          }
          // 3. 已移除 .swipeAction(...)
        })

        // 底部垫高，防止被 MiniPlayer 遮挡
        ListItem().height(90)
      }
      .width('100%')
      .height('100%')
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
