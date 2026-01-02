@Preview
@Component
struct mine{
  build() {
    Column() {
      // 图片区域 - 占高度70%
      Stack({
        alignContent: Alignment.Bottom
      }) {
        // 背景大图片
        Image($r('app.media.wave'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        // 上层logo
        Image($r('app.media.logo'))
          .width(80)
          .height(80)
          .margin({ bottom: 30 })
      }
      .height('70%')
      
      // 介绍区域 - 占高度30%
      Column() {
        // 第一行：软件名字
        Text('马楼玉米')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 10 })
        
        // 第二行：用户基本信息
        Text('00后 双子座 北京 歌龄:18年')
          .fontSize(14)
          .fontColor(Color.White)
          .opacity(0.8)
          .margin({ bottom: 20 })
        
        // 第三行：账户信息
        Row() {
          Column() {
            Text('1')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('关注')
              .fontSize(12)
              .fontColor(Color.White)
              .opacity(0.8)
          }
          .flexGrow(1)
          
          Column() {
            Text('100万')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('粉丝')
              .fontSize(12)
              .fontColor(Color.White)
              .opacity(0.8)
          }
          .flexGrow(1)
          
          Column() {
            Text('1.67亿')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('赞')
              .fontSize(12)
              .fontColor(Color.White)
              .opacity(0.8)
          }
          .flexGrow(1)
        }.width("60%")
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .height('30%')
      .justifyContent(FlexAlign.Center)

    }
    .width('100%')
    .height('100%')

    .expandSafeArea()
  }
}
export default mine