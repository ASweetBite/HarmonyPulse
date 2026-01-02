// components/LibraryListView.ets
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';

// 独立组件（无需 @Entry，仅 @ComponentV2）
@ComponentV2
export struct LibraryListView {
  // 绑定全局状态（与主组件共享同一 GlobalMusic 实例，解耦核心）
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic()) ?? new GlobalMusic();

  // 侧滑删除按钮（内部 Builder，仅当前组件使用）
  @Builder
  private DeleteButton(index: number) {
    Button() {
      Image($r('app.media.ic_close'))
        .width(20)
        .fillColor(Color.White)
    }
    .width(60)
    .height('100%')
    .backgroundColor(Color.Red)
    .type(ButtonType.Normal)
    .onClick(() => avPlayerManage.deleteSong(index))
  }

  build() {
    Column() {
      // 顶部大标题
      Text("资料库")
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .padding({ left: 20, top: 60, bottom: 10 })
        .backgroundColor(Color.White)

      Divider()

      List() {
        // 空数据判断（移到 ForEach 外部，避免嵌套 ListItem）
        if (this.globalMusic.playList?.length === 0) {
          ListItem() {
            Text("暂无歌曲数据")
              .fontSize(16)
              .fontColor(Color.Gray)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(50)
          }
        } else {
          // 遍历歌曲列表
          ForEach(this.globalMusic.playList, (item: SongItemType, index: number) => {
            ListItem() {
              Row() {
                // 封面
                Image(item.img || $r('app.media.ic_cd'))
                  .width(50)
                  .height(50)
                  .borderRadius(6)
                  .margin({ right: 15 })
                  .fillColor(Color.Gray)

                // 信息
                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontColor(this.globalMusic.currentID === item.id ? '#E23241' : Color.Black)
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

                // 更多操作
                Image($r('app.media.ic_more'))
                  .width(20)
                  .height(20)
                  .fillColor(Color.Gray)
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
              .onClick(() => {
                avPlayerManage.playResources(item)
              })
            }
            .swipeAction({ end: this.DeleteButton(index) }) // 侧滑删除
          })
        }

        // 底部垫高，防止被 MiniPlayBar 遮挡
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