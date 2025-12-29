import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct MarkdownEditor {
  @State mdText: string = '# 欢迎使用鸿蒙 MD 编辑器\n\n在此输入内容...';

  build() {
    Column() {
      // 1. 顶部工具栏
      Row() {
        Text('MD Editor')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Blank()
        Button('跳转页面')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Index' })
          })
          .margin(20)
          .width(150)
        Blank()
        Button('清空', { type: ButtonType.Capsule })
          .backgroundColor('#E64545')
          .height(30)
          .onClick(() => {
            this.mdText = '';
          })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#2C2C2C')
      .padding({ left: 20, right: 20 })

      // 2. 主体编辑预览区
      Row() {
        // 左侧：编辑区
        TextArea({ text: this.mdText, placeholder: '请输入 Markdown...' })
          .flexGrow(1)
          .height('100%')
          .backgroundColor('#1E1E1E')
          .fontColor('#D4D4D4')
          .fontFamily('Courier New')
          .onChange((value: string) => {
            this.mdText = value;
          })
          .borderRadius(0)

        // 中间分隔线
        Divider().vertical(true).strokeWidth(1).color('#333')

        // 右侧：预览区 (简单示例使用 Text，复杂场景建议配合 Web 组件渲染 HTML)
        Scroll() {
          Column() {
            // 注意：ArkUI 的 RichText 组件可以解析 HTML 字符串
            // 这里我们假设使用一个转换函数 getHtmlContent()
            RichText(this.parseMarkdownToHtml(this.mdText))
              .width('100%')
              .height('100%')
          }
          .padding(15)
          .alignItems(HorizontalAlign.Start)
        }
        .flexGrow(1)
        .height('100%')
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .flexGrow(1)
    }
    .width('100%')
    .height('100%')
  }

  // 简易解析逻辑：实际开发建议引入 marked 库
  private parseMarkdownToHtml(md: string): string {
    // 这里的字符串会被渲染为简单的 HTML
    // 在鸿蒙中，RichText 组件支持基础的 HTML 标签渲染
    return `<html>
              <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                  body { font-family: sans-serif; line-height: 1.5; padding: 10px; }
                  h1 { border-bottom: 1px solid #ccc; }
                  code { background: #f4f4f4; padding: 2px 4px; border-radius: 4px; }
                </style>
              </head>
              <body>
                ${md.replace(/^# (.*$)/gim, '<h1>$1</h1>')
      .replace(/^## (.*$)/gim, '<h2>$1</h2>')
      .replace(/\*\*(.*)\*\*/gim, '<b>$1</b>')}
              </body>
            </html>`;
  }
}
