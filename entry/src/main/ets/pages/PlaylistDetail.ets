// src/main/ets/pages/PlaylistDetail.ets
import { router } from '@kit.ArkUI';

@Entry
@Component
struct PlaylistDetail {
  @State playlistName: string = '默认歌单';
  @State songCount: number = 0;

  aboutToAppear() {
    // 使用 Record 类型来定义参数的结构
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      // 使用点操作符访问属性，并进行类型断言
      this.playlistName = (params.playlistName as string) || '默认歌单';
      this.songCount = Number(params.songCount) || 0; // 注意转换为Number类型
    }
  }

  build() {
    Column() {
      // 头部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back(); // 返回上一页[2](@ref)
          })

        Text('歌单详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(56)
      .padding(16)

      // 歌单内容
      Scroll() {
        Column() {
          Text(this.playlistName)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)

          Text(`共${this.songCount}首歌曲`)
            .fontSize(14)
            .fontColor('#666')
            .margin({ top: 8 })

          // 这里可以添加歌曲列表展示
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}