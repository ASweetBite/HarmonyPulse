// components/FullScreenPlayer.ets
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../../type/GlobalMusic';
import { avPlayerManage } from '../../utils/avPlayerMusic';

// 独立组件
@ComponentV2
export struct FullScreenPlayer {
  // 绑定全局状态
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic()) ?? new GlobalMusic();
  // 新增：接收父组件传递的关闭回调（显式声明类型，符合 ArkTS 规范）
  onClose?: () => void;

  // 时间格式化工具（组件内部工具，显式声明返回值类型）
  private number2time(number: number): string {
    const m = Math.floor(number / 1000 / 60);
    const s = Math.floor(number / 1000 % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  // 修正：关闭全屏播放器（ArkTS 原生方案，无 Web API）
  private closeFullScreen(): void {
    // 1. 调用父组件传递的关闭回调（安全判断，避免可选属性未赋值）
    if (this.onClose) {
      this.onClose();
    }
  }

  build() {
    Column() {
      // 顶部把手
      Button({
        type: ButtonType.Capsule,
        stateEffect: false
      })
        .width(40)
        .height(5)
        .backgroundColor('#333')
        .margin({ top: 15, bottom: 20 })
        .onClick(() => {
          // 触发关闭全屏（调用修正后的方法）
          this.closeFullScreen();
        })

      // 信息区
      Column({ space: 5 }) {
        Text(this.globalMusic.name || "未知歌曲")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.globalMusic.author || "未知歌手")
          .fontSize(20)
          .fontColor('#ccc')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('85%')
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 30 })

      // 大图
      Image(this.globalMusic.img || $r('app.media.ic_cd'))
        .width('85%')
        .aspectRatio(1)
        .borderRadius(20)
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.4)', offsetY: 20 })
        .margin({ top: 30, bottom: 50 })

      // 进度条
      Row() {
        Text(this.number2time(this.globalMusic.time)).fontColor('#999').fontSize(12)
        Slider({ value: this.globalMusic.time, max: this.globalMusic.duration })
          .layoutWeight(1)
          .blockColor(Color.White)
          .trackColor('#33ffffff')
          .selectedColor(Color.White)
          .margin({ left: 10, right: 10 })
          .onChange((val: number, mode: SliderChangeMode) => { // 显式声明参数类型
            if (mode === SliderChangeMode.End) {
              avPlayerManage.jumpToPlay(val)
            }
          })
        Text(this.number2time(this.globalMusic.duration)).fontColor('#999').fontSize(12)
      }
      .width('85%')
      .margin({ bottom: 30 })

      // 控制按钮
      Row({ space: 40 }) {
        Image($r('app.media.ic_prev')).width(40).fillColor(Color.White).onClick(() => avPlayerManage.preSong())
        Image(this.globalMusic.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(70)
          .fillColor(Color.White)
          .onClick(() => avPlayerManage.stopOrContinueSong())
        Image($r('app.media.ic_next')).width(40).fillColor(Color.White).onClick(() => avPlayerManage.nextSong())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1c1c1e')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .expandSafeArea(
      [SafeAreaType.SYSTEM],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]
    )
    .gesture(
      PanGesture({ direction: PanDirection.Down })
        .onActionEnd((event) => {
          if (event.offsetY > 100) {
            this.closeFullScreen();
          }
        })
    )
  }
}