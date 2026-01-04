// src/main/ets/components/MiniPlayer.ets
import { GlobalMusic } from '../../type/GlobalMusic';
import { LyricLine } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { LyricManager, lyricManager } from '../../utils/LyricManager';
import { number2time } from '../../utils/TimeUtils';

@ComponentV2
export struct MiniPlayBar {
  // 接收父组件传递的全局音乐状态
  @Param musicState: GlobalMusic = new GlobalMusic();

  // 播放器内部状态：全屏开关
  @Local isFullScreenPlayerOpen: boolean = false;

  // --- 歌词相关状态 ---
  @Local currentLyricIndex: number = 0;
  @Local lyricList: LyricLine[] = [];

  // 歌词滚动控制器
  private lyricScroller: Scroller = new Scroller();

  aboutToAppear() {
    // 组件加载时，订阅歌曲切换事件
    this.musicState.onSongChange(() => {
      this.loadLyricManual();
    });

    // 初始加载一次（防止首首歌不显示）
    this.loadLyricManual();
  }

  loadLyricManual() {
    console.info("MiniPlayBar: Manual loading lyric for ID: " + this.musicState.currentID);

    const path = this.musicState.lyricPath;
    if (path) {
      const lrcContent = lyricManager.readLyricFile(path);
      if (lrcContent) {
        this.lyricList = LyricManager.parseLrc(lrcContent);
        this.currentLyricIndex = 0;
        this.lyricScroller.scrollToIndex(0);
        return;
      }
    }

    // 兜底
    this.lyricList = [{ time: 0, text: "暂无歌词" }];
    this.currentLyricIndex = 0;
  }


  // 监听音乐时间变化，计算当前歌词行
  @Monitor("musicState.time")
  onTimeUpdate() {
    if (this.lyricList.length === 0) return;

    // 找到最后一个时间小于当前播放时间的歌词行
    let activeIndex = this.lyricList.findIndex((line) => line.time > this.musicState.time);

    // findIndex 找到的是第一个“大于”当前时间的，所以当前唱的是 activeIndex - 1
    // 如果返回 -1，说明所有歌词时间都小于当前时间（唱到最后一句了），则取最后一句
    if (activeIndex === -1) {
      activeIndex = this.lyricList.length - 1;
    } else {
      activeIndex = activeIndex - 1;
    }

    if (this.currentLyricIndex !== activeIndex) {
      this.currentLyricIndex = activeIndex;
      // 歌词自动滚动到中间
      this.lyricScroller.scrollToIndex(activeIndex, true, ScrollAlign.CENTER);
    }
  }


  // 辅助方法：处理无歌词情况
  private setDefaultLyric() {
    this.lyricList = [{ time: 0, text: "暂无歌词" }];
  }


  // --- 歌词页面构建器 ---
  @Builder
  LyricPage() {
    Column() {
      if (this.lyricList.length === 0) {
        Text("暂无歌词").fontColor(Color.Gray).margin({ top: 100 })
      } else {
        List({ scroller: this.lyricScroller, space: 20 }) {
          // 顶部占位，让第一句能滚到中间
          ListItem().height('40%')

          ForEach(this.lyricList, (line: LyricLine, index: number) => {
            ListItem() {
              Text(line.text)
                .width('100%')
                .textAlign(TextAlign.Center)
                .fontWeight(index === this.currentLyricIndex ? FontWeight.Bold : FontWeight.Normal)
                .fontSize(index === this.currentLyricIndex ? 24 : 18)
                .fontColor(index === this.currentLyricIndex ? Color.White : 'rgba(255,255,255,0.6)')
                // --- 视觉特效核心逻辑 ---
                // 1. 模糊：距离越远，模糊程度越高 (limit 10)
                .blur(Math.min(Math.abs(index - this.currentLyricIndex) * 1.5, 10))
                // 2. 缩放：当前行最大，其他的稍微缩小
                .scale({
                  x: index === this.currentLyricIndex ? 1.0 : 0.9,
                  y: index === this.currentLyricIndex ? 1.0 : 0.9
                })
                // 3. 动画：所有属性变化都带动画
                .animation({ duration: 300, curve: Curve.EaseOut })
                .onClick(() => {
                  // 点击跳转播放
                  avPlayerManage.jumpToPlay(line.time);
                  this.musicState.isPlay = true;
                })
            }
          })

          // 底部占位
          ListItem().height('40%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off) // 隐藏滚动条更美观
        .edgeEffect(EdgeEffect.Fade)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 30, right: 30 })
  }

  // --- 封面与控制页面 ---
  @Builder
  CoverAndControlsPage() {
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
          .height(70)
          .fillColor(Color.White)
          .onClick(() => avPlayerManage.stopOrContinueSong())
        Image($r('app.media.ic_next')).width(40).fillColor(Color.White).onClick(() => avPlayerManage.nextSong())
      }
    }
    .width('100%')
    .height('100%')
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

  // --- 全屏播放器主入口 ---
  @Builder
  FullScreenPlayer() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景层 (当前封面做高斯模糊背景)
      Image(this.musicState.img)
        .width('100%')
        .height('100%')
        .blur(80) // 极强的背景模糊
        .opacity(0.5)

      // 黑色遮罩，保证文字清晰度
      Column().width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')

      // 内容层：使用 Swiper 实现左右滑动切换
      Swiper() {
        // 第一页：封面和控制
        this.CoverAndControlsPage()

        // 第二页：歌词
        this.LyricPage()
      }
      .loop(false) // 不循环
      .indicator(true) // 显示底部的指示点
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1c1c1e')
  }

  // --- 迷你播放条构建 ---
  build() {
    Row() {
      // 小封面
      Image(this.musicState.img)
        .width(40)
        .height(40)
        .borderRadius(4)
        .margin({ left: 20, right: 12 })
        .backgroundColor('#eee')

      // 歌曲信息
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