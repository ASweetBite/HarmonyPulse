// src/main/ets/views/LibraryView.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { promptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit'; // 1. 导入振动服务
import { BusinessError } from '@kit.BasicServicesKit';

@ComponentV2
export struct LibraryView {
  @Param musicState: GlobalMusic = new GlobalMusic();

  // 触发振动的封装函数
  triggerVibration() {
    try {
      // 使用预置的触感振动效果 (haptic.style.heavy 或 medium)
      vibrator.startVibration({
        type: 'preset',
        effectId: 'haptic.style.medium',
        count: 1
      }, {
        usage: 'touch'
      });
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to start vibration, code: ${err.code}, message: ${err.message}`);
    }
  }

  // 2. 定义“悬浮”时的样式 (Preview)
  // 这是长按那一瞬间，用户手里“捏”着的那个组件的样子
  @Builder
  SongItemPreview(item: SongItemType) {
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
          .fontColor(Color.Black)
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
    }
    .width('100%')
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(12) // 增加圆角，体现悬浮感
    // 增加阴影，体现Z轴高度，让它看起来浮在半空
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.2)', offsetY: 10 })
  }

  // 3. 菜单构建器
  @Builder
  MusicActionMenu(item: SongItemType, index: number) {
    Menu() {
      MenuItem({ content: "播放", startIcon: $r('app.media.ic_music') }) // 假设有图标
        .onClick(() => {
          this.musicState.isPlay = true;
          avPlayerManage.playResources(item);
        })

      MenuItem({ content: "添加到歌单" })
        .onClick(() => promptAction.showToast({ message: "功能开发中" }))

      MenuItem({ content: "查看详情" })
        .onClick(() => promptAction.showToast({ message: `歌曲ID: ${item.id}` }))

      MenuItem({ content: "删除" })
        .contentFontColor(Color.Red)
        .onClick(() => avPlayerManage.deleteSong(index))
    }
    // 关键点：菜单出现时触发振动
    .onAppear(() => {
      this.triggerVibration();
    })
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
            // 这里为了代码简洁，省略了 empty 判断逻辑，保留核心列表项
            if (this.musicState.playList && this.musicState.playList.length > 0) {
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
                    // 选中高亮逻辑
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
              // 4. 绑定上下文菜单，并配置 Preview 和样式
              .bindContextMenu(
                this.MusicActionMenu(item, index), // 菜单内容
                ResponseType.LongPress, // 响应方式：长按
                {
                  // 启用背景模糊 (API 10+ 默认通常为 true，显式声明更保险)
                  enableArrow: false, // 是否显示小箭头，关闭后更像 iOS 风格
                  preview: this.SongItemPreview(item), // 传入自定义的悬浮预览组件
                  backgroundColor: Color.Transparent // 菜单容器背景透明，避免遮挡圆角
                }
              )
            }
          }
        })
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
