// components/MiniPlayBar.ets
import { AppStorageV2} from '@kit.ArkUI';
import { GlobalMusic } from '../../type/GlobalMusic';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { FullScreenPlayer } from './FullScreenPlayer';

// 独立组件
@ComponentV2
export struct MiniPlayBar {
  // 绑定全局状态
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic()) ?? new GlobalMusic();
  // 控制全屏播放器展开/收起（组件内部状态，无需全局共享）
  @Local isFullScreenPlayerOpen: boolean = false;

  build() {
    Row() {
      // 封面
      Image(this.globalMusic.img || $r('app.media.ic_cd'))
        .width(40)
        .height(40)
        .borderRadius(4)
        .margin({ left: 20, right: 12 })
        .backgroundColor('#eee')

      // 歌曲信息
      Text(this.globalMusic.name || "未在播放")
        .fontSize(16)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 播放控制
      Row({ space: 15 }) {
        Image(this.globalMusic.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(28)
          .height(28)
          .fillColor(Color.Black)
          .onClick(() => {
            avPlayerManage.stopOrContinueSong();
          })

        Image($r('app.media.ic_next'))
          .width(28)
          .height(28)
          .fillColor(Color.Black)
          .margin({ right: 20 })
          .onClick(() => {
            avPlayerManage.nextSong();
          })
      }
    }
    .width('94%')
    .height(64)
    .backgroundColor('rgba(255, 255, 255, 0.9)')
    .backdropBlur(20)
    .borderRadius(12)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetY: 5 })
    .margin({ bottom: 10 })
    .onClick(() => {
      this.isFullScreenPlayerOpen = true;
    })
    // 绑定全屏播放器
    .bindContentCover(this.isFullScreenPlayerOpen, this.FullScreenPlayerBuilder(), {
      modalTransition: ModalTransition.DEFAULT,
      backgroundColor: Color.Black,
      onDisappear: () => {
        this.isFullScreenPlayerOpen = false
      }
    })
  }

  // 全屏播放器 Builder 封装（内部调用，解耦渲染逻辑）
  @Builder
  private FullScreenPlayerBuilder() {
    FullScreenPlayer();
  }
}