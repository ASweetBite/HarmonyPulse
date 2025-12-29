import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  build() {
    Column() {
      Text(this.message)
        .fontSize(30)

      Button('跳转页面')
        .onClick(() => {
          router.pushUrl({ url: 'pages/test' })
        })
        .margin(20)
        .width(150)
    }
    .width('100%')
    .height('100%')
    .id('HelloWorld')
  }
}