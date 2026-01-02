import { PLAYLIST_COLLECTIONS } from '../../common/Constants';

// 独立组件
@ComponentV2
export struct PlaylistCollectionView {
  // 接收 Swiper 控制器（用于切换回资料库，仅必要传参）
  swiperController: SwiperController = new SwiperController();

  // 歌单图标覆盖层（内部 Builder）
  @Builder
  private PlaylistIconOverlay() {
    Stack() {
      Image($r('app.media.ic_song_list'))
        .width('40%')
        .fillColor(Color.Gray)
    }
  }

  build() {
    Column() {
      Text("我的歌单")
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .padding({ left: 20, top: 60, bottom: 10 })
        .backgroundColor('#F2F2F7')

      Grid() {
        ForEach(PLAYLIST_COLLECTIONS, (item: string) => {
          GridItem() {
            Column() {
              // 歌单封面模拟
              Rect()
                .width('100%')
                .aspectRatio(1)
                .fill('#ddd')
                .borderRadius(12)
                .overlay(this.PlaylistIconOverlay())

              Text(item)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 8 })
                .width('100%')
            }
            .padding(10)
            .onClick(() => {
              console.info(`切换到歌单: ${item}`);
              // 切换后自动滑回主页
              this.swiperController.changeIndex(0, true);
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(15)
      .padding({ left: 10, right: 10 })
      .width('100%')
      .layoutWeight(1)

      // 底部垫高
      Column().height(90)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}