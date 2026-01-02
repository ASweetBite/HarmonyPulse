// src/main/ets/components/MiniPlayer.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { number2time } from '../../utils/TimeUtils';

@ComponentV2
export struct MiniPlayBar {
  // 接收父组件传递的全局音乐状态
  @Param musicState: GlobalMusic = new GlobalMusic();

  // 播放器内部状态：全屏开关
  @Local isFullScreenPlayerOpen: boolean = false;

  @Builder
  FullScreenPlayer() {
    Column() {
      // --- 把手 ---
      Button({ type: ButtonType.Capsule, stateEffect: false })
        .width(40)
        .height(5)
        .backgroundColor('#333')
        .margin({ top: 15, bottom: 20 })
        .onClick(() => { this.isFullScreenPlayerOpen = false })

      // --- 歌曲信息 ---
      Column({ space: 5 }) {
        Text(this.musicState.name || "未知歌曲")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.musicState.author || "未知歌手")
          .fontSize(20)
          .fontColor('#ccc')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('85%')
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 30 })

      // --- 封面 ---
      Image(this.musicState.img)
        .width('85%')
        .aspectRatio(1)
        .borderRadius(20)
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.4)', offsetY: 20 })
        .margin({ top: 30, bottom: 50 })

      // --- 进度条 ---
      Row() {
        Text(number2time(this.musicState.time)).fontColor('#999').fontSize(12)
        Slider({ value: this.musicState.time, max: this.musicState.duration })
          .layoutWeight(1)
          .blockColor(Color.White)
          .trackColor('#33ffffff')
          .selectedColor(Color.White)
          .margin({ left: 10, right: 10 })
          .onChange((val, mode) => {
            if (mode === SliderChangeMode.End) {
              avPlayerManage.jumpToPlay(val)
            }
          })
        Text(number2time(this.musicState.duration)).fontColor('#999').fontSize(12)
      }
      .width('85%')
      .margin({ bottom: 30 })

      // --- 控制按钮 ---
      Row({ space: 40 }) {
        Image($r('app.media.ic_prev')).width(40).fillColor(Color.White).onClick(() => avPlayerManage.preSong())
        Image(this.musicState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .gesture(
      PanGesture({ direction: PanDirection.Down })
        .onActionEnd((event) => {
          if (event.offsetY > 100) this.isFullScreenPlayerOpen = false;
        })
    )
  }

  build() {
    Row() {
      // 小封面
      Image(this.musicState.img)
        .width(40)
        .height(40)
        .borderRadius(4)
        .margin({ left: 20, right: 12 })
        .backgroundColor('#eee')

      // 信息
      Text(this.musicState.name || "未在播放")
        .fontSize(16)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 简易控制
      Row({ space: 15 }) {
        Image(this.musicState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(28)
          .height(28)
          .fillColor(Color.Black)
          .onClick(() => avPlayerManage.stopOrContinueSong())

        Image($r('app.media.ic_next'))
          .width(28)
          .height(28)
          .fillColor(Color.Black)
          .margin({ right: 20 })
          .onClick(() => avPlayerManage.nextSong())
      }
    }
    .width('94%')
    .height(64)
    .backgroundColor('rgba(255, 255, 255, 0.9)')
    .backdropBlur(20)
    .borderRadius(12)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetY: 5 })
    .margin({ bottom: 10 })
    .onClick(() => { this.isFullScreenPlayerOpen = true })
    .bindContentCover(this.isFullScreenPlayerOpen, this.FullScreenPlayer(), {
      modalTransition: ModalTransition.DEFAULT,
      backgroundColor: Color.Black,
      onDisappear: () => { this.isFullScreenPlayerOpen = false }
    })
  }
}
