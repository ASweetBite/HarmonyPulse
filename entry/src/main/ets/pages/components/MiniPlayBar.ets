// src/main/ets/components/MiniPlayer.ets
import { GlobalMusic, PlaybackMode } from '../../type/GlobalMusic';
import { LyricLine, SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { LyricManager, lyricManager } from '../../utils/LyricManager';
import { number2time } from '../../utils/TimeUtils';
import Curves from '@ohos.curves';

const OFFSET_PER_LINE = 10;
const MAX_OFFSET_CAP = 30;

@ComponentV2
export struct MiniPlayBar {
  // 接收父组件传递的全局音乐状态
  @Param musicState: GlobalMusic = new GlobalMusic();

  // 播放器内部状态：全屏开关
  @Local isFullScreenPlayerOpen: boolean = false;
  @Local isUserInteracting: boolean = false; // 用户是否正在操作
  private timer: number = -1;

  // --- 歌词相关状态 ---
  @Local currentLyricIndex: number = 0;
  @Local lyricList: LyricLine[] = [];

  // 歌词滚动控制器
  private lyricScroller: Scroller = new Scroller();

  @Local isPlayListOpen: boolean = false; // 控制播放列表弹窗

  @Local private lyricBounceOffset: number = 0
  private isManualScrolling: boolean = false; // 手动跳转锁
  private targetLyricIndex: number = -1;      // 目标索引
  private jumpLockTimer: number = -1; // 专门用于处理跳转锁的定时器
  private liquidCurve = Curves.interpolatingSpring(5, 1.5, 60, 12);
  private shapCurve = Curves.cubicBezierCurve(0.3, 0, 0.6, 1)

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
        // 1. 原始解析
        const rawList = LyricManager.parseLrc(lrcContent);
        // 2. --- 核心修改：合并相同时间戳的歌词 ---
        const groupedList: LyricLine[] = [];
        rawList.forEach((item: LyricLine) => {
          // 检查新数组最后一项的时间是否与当前项相同
          if (groupedList.length > 0 && groupedList[groupedList.length - 1].time === item.time) {
            // 时间戳相同，将歌词拼接到上一行后面
            groupedList[groupedList.length - 1].text += "\n" + item.text;
          } else {
            // 时间戳不同，作为新的一行加入
            groupedList.push({ time: item.time, text: item.text });
          }
        });
        // 【关键修复点】：将合并后的 groupedList 赋值给状态变量，而不是 rawList
        this.lyricList = groupedList;
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
    // 手动拖拽时不干扰
    if (this.isManualScrolling) return;
    if (this.lyricList.length === 0) return;

    // 1. 计算目标行
    let activeIndex = this.lyricList.findIndex((line) => line.time > this.musicState.time);
    if (activeIndex === -1) activeIndex = this.lyricList.length - 1;
    else activeIndex = activeIndex - 1;

    // 2. 只有行数发生变化才执行
    if (this.currentLyricIndex !== activeIndex) {

      // --- 高级物理计算 ---
      const diff = this.currentLyricIndex - activeIndex;

      // 这里的逻辑是：
      // 如果 activeIndex 变大（向下唱），diff > 0，内容往上滚，文字应该有向下的惯性拖拽（Offset > 0）
      // 如果 activeIndex 变小（往回跳），diff < 0，内容往下滚，文字应该有向上的惯性拖拽（Offset < 0）

      // 计算原始冲量
      let rawImpulse = diff * OFFSET_PER_LINE;

      // 施加限制（Clamp）：保留符号，但绝对值不超过 MAX_OFFSET_CAP
      // 比如 diff 是 100，算出 1500，但被限制在 80
      let finalImpulse = Math.sign(rawImpulse) * Math.min(Math.abs(rawImpulse), MAX_OFFSET_CAP);

      // 更新索引和列表位置
      this.currentLyricIndex = activeIndex;
      this.lyricScroller.scrollToIndex(activeIndex, true, ScrollAlign.CENTER);

      // --- 第一阶段：快速积蓄势能 (Curve.Sharp) ---
      // 使用 Curve.Sharp 快速让歌词产生位移，避免“闪现”
      animateTo({
        duration: 200, // 稍微快一点，模拟受力瞬间
        curve: Curve.Sharp
      }, () => {
        this.lyricBounceOffset = finalImpulse;
      })

      // --- 第二阶段：液体释放回弹 (Liquid Curve) ---
      setTimeout(() => {
        animateTo({
          duration: 1400, // 慢速回弹，展现液体粘稠感
          curve: this.liquidCurve // 之前定义的 interpolatingSpring(1, 30, 15)
        }, () => {
          this.lyricBounceOffset = 0; // 最终归零
        })
      }, 180) // 略小于第一阶段 duration，实现无缝衔接
    }
  }

  // 辅助方法：处理无歌词情况
  private setDefaultLyric() {
    this.lyricList = [{ time: 0, text: "暂无歌词" }];
  }

  // 辅助方法：跳转歌词
  private scrollToLyric(index: number, time: number) {
    clearTimeout(this.timer);
    clearTimeout(this.jumpLockTimer);

    this.isUserInteracting = false;
    this.isManualScrolling = true;
    this.targetLyricIndex = index;


    const diff = this.currentLyricIndex - index;

    // 计算原始冲量
    let rawImpulse = diff * OFFSET_PER_LINE;
    let finalImpulse = Math.sign(rawImpulse) * Math.min(Math.abs(rawImpulse), MAX_OFFSET_CAP);

    // 更新索引和列表位置
    this.currentLyricIndex = index;
    this.lyricScroller.scrollToIndex(index, true, ScrollAlign.CENTER);

    // --- 第一阶段：快速积蓄势能 (Curve.Sharp) ---
    // 使用 Curve.Sharp 快速让歌词产生位移，避免“闪现”
    animateTo({
      duration: 180, // 稍微快一点，模拟受力瞬间
      curve: Curve.Sharp
    }, () => {
      this.lyricBounceOffset = finalImpulse;
    })

    // --- 第二阶段：液体释放回弹 (Liquid Curve) ---
    setTimeout(() => {
      animateTo({
        duration: 1400, // 慢速回弹，展现液体粘稠感
        curve: this.liquidCurve // 之前定义的 interpolatingSpring(1, 30, 15)
      }, () => {
        this.lyricBounceOffset = 0; // 最终归零
      })
    }, 160) // 略小于第一阶段 duration，实现无缝衔接

    // 5. 同步播放器
    avPlayerManage.jumpToPlay(time);
    this.musicState.isPlay = true;

    // 6. 解锁
    this.jumpLockTimer = setTimeout(() => {
      this.isManualScrolling = false;
    }, 800);
  }



  // 获取当前播放模式对应的图标
  getPlaybackModeIcon(): Resource {
    switch (this.musicState.playbackStatus) {
      case "顺序播放":
        return $r('app.media.ic_auto')     // 顺序播放图标
      case "单曲循环":
        return $r('app.media.ic_repeat')    // 单曲循环图标
      case "随机播放":
        return $r('app.media.ic_random')    // 随机播放图标
    }
  }


  // 切换播放模式
  onSwitchPlaybackMode(): void {
    const status = this.musicState.playbackStatus
    let nextStatus: PlaybackMode

    if (status === "顺序播放") nextStatus = "单曲循环"
    else if (status === "单曲循环") nextStatus = "随机播放"
    else nextStatus = "顺序播放"

    this.musicState.playbackStatus = nextStatus
  }




  @Builder
  LyricPage() {
    Column() {
      if (this.lyricList.length === 0) {
        Text("暂无歌词")
          .fontColor('rgba(255,255,255,0.4)')
          .margin({ top: 100 })
      } else {
        List({ scroller: this.lyricScroller, space: 22 }) {
          ListItem().height('45%')

          ForEach(this.lyricList, (line: LyricLine, index: number) => {
            ListItem() {
              Text(line.text)
                .width('100%')
                .textAlign(TextAlign.Center)

                .fontSize(index === this.currentLyricIndex ? 26 : 26)
                .fontWeight(
                  index === this.currentLyricIndex
                    ? FontWeight.Medium
                    : FontWeight.Normal
                )

                .fontColor(Color.White)
                .translate({
                  // 核心：使用平滑的分层位移逻辑
                  y: this.calculateLiquidY(index)
                })
                .scale({
                  // 高亮行轻微膨胀，周围行轻微收缩，模拟挤压感
                  x: this.calculateLiquidScale(index),
                  y: this.calculateLiquidScale(index)
                })
                .animation({
                  duration: 350,
                  curve: Curve.Sharp
                })
                  // 液体感需要更柔和的透明度过渡
                .opacity(this.calculateLiquidOpacity(index))
                .blur(this.calculateLiquidBlur(index))

                .lineHeight(index === this.currentLyricIndex ? 30 : 26)
                .padding({ left: 20, right: 20 })
            }
            .onClick(() => {
              this.scrollToLyric(index, line.time)
            })
          })


          ListItem().height('45%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // —— 用户滑动时全部清晰 ——
        .onScrollFrameBegin((offset: number) => {
          if (!this.isUserInteracting) {
            clearTimeout(this.timer)
            this.isUserInteracting = true
          }
          return { offsetRemain: offset }
        })

        // —— 停止后回焦点 ——
        .onScrollStop(() => {
          clearTimeout(this.timer)
          this.timer = setTimeout(() => {
            this.isUserInteracting = false
            this.lyricScroller.scrollToIndex(
              this.currentLyricIndex,
              true,
              ScrollAlign.CENTER
            )
          }, 2500)
        })
      }
      Column()
        .width('100%')
        .height(80)
        .backgroundColor('rgba(0,0,0,0.5)')
        .blur(8)
        .align(Alignment.Top) // 顶对齐

      // 底部渐隐蒙层
      Column()
        .width('100%')
        .height(80)
        .backgroundColor('rgba(0,0,0,0.5)')
        .blur(8)
        .align(Alignment.Bottom) // 底对齐
    }
    .backgroundColor(Color.Transparent)
  }

  // --- 液体感计算逻辑 ---

  // 1. 透明度：当前行最亮，向两边柔和递减
  private calculateLiquidOpacity(index: number): number {
    const dist = Math.abs(index - this.currentLyricIndex);
    if (this.isUserInteracting) return 1.0;
    return Math.max(0.2, Math.exp(-dist * 0.5));
  }


  // 2. 位移：液体波动效果
  private calculateLiquidY(index: number): number {
    const dist = Math.abs(index - this.currentLyricIndex);
    // 将 0.8 改为 0.5 或 0.6，可以让波动传递得更远，液体感更强
    return this.lyricBounceOffset * Math.exp(-dist * 0.6);
  }


  // 3. 缩放：中心挤压感
  private calculateLiquidScale(index: number): number {
    const dist = Math.abs(index - this.currentLyricIndex);
    // 获取偏移幅度的绝对值，确保无论是向上还是向下跳转，高亮行都会有“膨胀”感
    const magnitude = Math.abs(this.lyricBounceOffset);

    if (dist === 0) {
      // 高亮行：根据位移幅度膨胀（限制在 1.08 附近波动）
      return 1.08 + (magnitude / 1000);
    }
    // 非高亮行：保持轻微收缩状态，并随波动微颤
    return 0.95 + (magnitude / 2000);
  }

  private calculateLiquidBlur(index: number): number {
    if (this.isUserInteracting) return 0;
    const dist = Math.abs(index - this.currentLyricIndex);
    // 除了中心点，其他行带一点点动态模糊，液体感更强
    return Math.min(dist * 2, 8);
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
      Image(this.musicState.img ? this.musicState.img : $r('app.media.ic_default'))
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
      Row({ space: 25 }) {
        // 1. 新增播放列表按钮
        Image($r('app.media.ic_list'))
          .width(30)
          .height(30)
          .fillColor(Color.White)
          .onClick(() => {
            this.isPlayListOpen = true;
          })

        Image($r('app.media.ic_prev'))
          .width(35)
          .fillColor(Color.White)
          .onClick(() => avPlayerManage.preSong())

        Image(this.musicState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(65)
          .height(65)
          .fillColor(Color.White)
          .onClick(() => avPlayerManage.stopOrContinueSong())

        Image($r('app.media.ic_next'))
          .width(35)
          .fillColor(Color.White)
          .onClick(() => avPlayerManage.nextSong())

        Image(this.getPlaybackModeIcon())
          .width(30)
          .height(30)
          .fillColor(Color.White)
          .onClick(() => this.onSwitchPlaybackMode())

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
    NavDestination() {
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
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 核心沉浸效果
      .width('100%')
      .height('100%')
      .backgroundColor('#1c1c1e')
      .bindSheet(this.isPlayListOpen, this.PlayListSheet(), {
        height: SheetSize.MEDIUM, // 显示一半高度
        dragBar: true,
        backgroundColor: '#2c2c2e',
        onDisappear: () => {
          this.isPlayListOpen = false
        }
      })
    }
    .hideTitleBar(true)
  }

  // --- 播放列表弹窗内容 ---
  @Builder
  PlayListSheet() {
    Column() {
      Row() {
        Text("播放列表")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(`(${this.musicState.songList.length})`)
          .fontSize(14)
          .fontColor('#999')
          .margin({ left: 5 })
        Blank()

          .onClick(() => { this.isPlayListOpen = false })
      }
      .width('100%')
      .padding(20)

      List() {
        ForEach(this.musicState.songList, (item: SongItemType, index: number) => {
          ListItem() {
            Row() {
              // 当前播放标识
              if (this.musicState.currentID === item.id) {
                Image($r('app.media.ic_play')) // 或者一个音波动画图标
                  .width(16)
                  .height(16)
                  .fillColor('#E23241')
                  .margin({ right: 10 })
              }

              Column() {
                Text(item.name)
                  .fontSize(16)
                  .fontColor(this.musicState.currentID === item.id ? '#E23241' : Color.White)
                  .maxLines(1)
                Text(item.author)
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Image($r('app.media.ic_more')) // 更多操作按钮
                .width(20)
                .fillColor('#666')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .onClick(() => {
              // 点击切换音乐
              avPlayerManage.playResources(item);
              this.musicState.isPlay = true;
              // 选做：切换后是否自动关闭列表
              // this.isPlayListOpen = false;
            })
          }
        }, (item: SongItemType) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2c2c2e') // 深色背景
  }

  // --- 迷你播放条构建 ---
  build() {
    Row() {
      // 小封面
      Image(this.musicState.img ? this.musicState.img : $r('app.media.ic_default'))
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