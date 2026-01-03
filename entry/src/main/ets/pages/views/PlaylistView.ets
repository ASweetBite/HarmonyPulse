import router from '@ohos.router';

@ComponentV2
export struct PlaylistView {
  // 如果需要回调操作 Swiper，可以使用 Event 或者传入回调函数
  // 这里演示传入一个简单的回调
  @Event onPlaylistSelected: (name: string) => void = (name) => {
    // 补全路由跳转功能[6,7](@ref)
    router.pushUrl({
      url: 'pages/layout', // 目标页面路径
      params: { playlistName: name } // 传递歌单名称参数[7](@ref)
    }).then(() => {
      console.info(`跳转到layout页面成功，歌单名称: ${name}`);
    }).catch((err: Error) => {
      console.error(`跳转到layout页面失败: ${err.message}`);
    });
  };

  private playlistCollections: string[] = ["我喜欢的音乐", "最近播放", "车载经典", "周杰伦合集", "轻音乐", "助眠歌单"];

  @Builder
  PlaylistIconOverlay() {
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
        ForEach(this.playlistCollections, (item: string) => {
          GridItem() {
            Column() {
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
              this.onPlaylistSelected(item);
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(15)
      .padding({ left: 10, right: 10 })
      .width('100%')
      .layoutWeight(1)

      Column().height(90)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}