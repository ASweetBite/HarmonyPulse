// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();

  @Builder
  DeleteButton(index: number) {
    Button() {
      Image($r('app.media.ic_close')).width(20).fillColor(Color.White)
    }
    .width(60)
    .height('100%')
    .backgroundColor(Color.Red)
    .type(ButtonType.Normal)
    .onClick(() => avPlayerManage.deleteSong(index))
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
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
              .onClick(() => {
                this.musicState.isPlay = true;
                avPlayerManage.playResources(item)
              })
            }
          }
          .swipeAction({ end: this.DeleteButton(index) })
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
