// ShareLoadingPage.ets
@Entry
@Component
struct ShareLoadingPage {
  build() {
    Stack() {
      // 半透明背景或直接使用系统背景色
      Column() {
        // 一个优雅的加载动画
        LoadingProgress()
          .width(60)
          .height(60)
          .color($r('sys.color.ohos_id_color_emphasize'))

        Text('正在导入音乐...')
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin({ top: 20 })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background')) // 使用系统标准背景色
  }
}