// src/main/ets/components/MiniPlayer.ets
import { GlobalMusic, PlaybackMode } from '../../type/GlobalMusic';
import { LyricLine, SongItemType } from '../../type/SongItemType';
import { avPlayerManage } from '../../utils/avPlayerMusic';
import { LyricManager, lyricManager } from '../../utils/LyricManager';
import { number2time } from '../../utils/TimeUtils';

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

  private isManualScrolling: boolean = false; // 手动跳转锁
  private targetLyricIndex: number = -1;      // 目标索引
  private jumpLockTimer: number = -1; // 专门用于处理跳转锁的定时器

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
        //this.lyricList = LyricManager.parseLrc(lrcContent);
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
    // --- 核心修改：如果是手动跳转过程中，不执行自动索引计算 ---
    if (this.isManualScrolling) {
      return;
    }
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

    // 只有在非锁定状态，且索引真的变化时才更新 UI
    if (this.currentLyricIndex !== activeIndex) {
      this.currentLyricIndex = activeIndex;
      this.lyricScroller.scrollToIndex(activeIndex, true, ScrollAlign.CENTER);
    }

    // 只有索引真的变化时才滚动，减少性能消耗
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

  // 辅助方法：跳转歌词
  private scrollToLyric(index: number, time: number) {
    // 1. 立即清除任何正在等待的“恢复模糊”定时器
    clearTimeout(this.timer);
    // 1.1 清除之前的解锁定时器（防止连续点击导致逻辑混乱）
    clearTimeout(this.jumpLockTimer);

    // 2. 立即加回模糊和缩放样式（恢复非交互状态）
    this.isUserInteracting = false;

    // --- 核心修改：锁定并记录目标 ---
    this.isManualScrolling = true;
    this.targetLyricIndex = index;

    // 3. 更新当前索引并同步播放器
    this.currentLyricIndex = index;
    avPlayerManage.jumpToPlay(time);
    this.musicState.isPlay = true;

    // 4. 执行滚动：此时 List 会因为 isUserInteracting 为 false 而应用模糊样式
    // 使用 ScrollAlign.CENTER 确保点击的那行滚动到中间
    this.lyricScroller.scrollToIndex(index, true, ScrollAlign.CENTER);

    // 5. 【关键】延迟解锁：给播放器 800 毫秒的时间去稳定它的时间戳
    this.jumpLockTimer = setTimeout(() => {
      this.isManualScrolling = false;
      console.info("MiniPlayBar: 跳转锁已解除");
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




  // --- 歌词页面构建器 ---
  @Builder
  LyricPage() {
    Column() {
      if (this.lyricList.length === 0) {
        Text("暂无歌词").fontColor(Color.Gray).margin({ top: 100 })
      } else {
        List({ scroller: this.lyricScroller, space: 20 }) {
          ListItem().height('45%') // 顶部留白

          ForEach(this.lyricList, (line: LyricLine, index: number) => {
            ListItem() {
              Text(line.text)
                .width('100%')
                .textAlign(TextAlign.Center)
                .fontWeight(index === this.currentLyricIndex ? FontWeight.Bold : FontWeight.Normal)
                .fontSize(index === this.currentLyricIndex ? 24 : 18)
                .lineHeight(index === this.currentLyricIndex ? 28 : 24) // 设置行高让双语间距更舒适

                .fontColor(this.isUserInteracting || index === this.currentLyricIndex ?
                  Color.White : 'rgba(255,255,255,0.6)')
                .blur(this.isUserInteracting ? 0 : Math.min(Math.abs(index - this.currentLyricIndex) * 1.5, 10))
                .scale({
                  x: this.isUserInteracting || index === this.currentLyricIndex ? 1.0 : 0.9,
                  y: this.isUserInteracting || index === this.currentLyricIndex ? 1.0 : 0.9
                })
                .animation({ duration: 300, curve: Curve.EaseOut })
            }
            //.padding({ left: 30, right: 30 }) // 增加左右内边距防止歌词贴边
            .onClick(() => {
              this.scrollToLyric(index, line.time);

            })
          })

          ListItem().height('45%') // 底部留白
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        // 监听滑动开始
        .onScrollFrameBegin((offset: number, state: ScrollState) => {
          if (!this.isUserInteracting) {
            clearTimeout(this.timer);
            this.isUserInteracting = true; // 滑动时去掉模糊，显示清晰歌词
          }
          return { offsetRemain: offset };
        })
        // 监听滑动停止
        .onScrollStop(() => {
          clearTimeout(this.timer);
          // 如果用户只是滑动而不点击，2.5秒后恢复模糊并滚回当前播放位置
          this.timer = setTimeout(() => {
            this.isUserInteracting = false;
            this.lyricScroller.scrollToIndex(this.currentLyricIndex, true, ScrollAlign.CENTER);
          }, 2500);
        })
      }
    }
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
        Image($r('app.media.ic_list')) // 请确保你有这个图标，如果没有可用 ic_default 代替测试
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
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
    .backgroundColor('#1c1c1e')
    .bindSheet(this.isPlayListOpen, this.PlayListSheet(), {
      height: SheetSize.MEDIUM, // 显示一半高度
      dragBar: true,
      backgroundColor: '#2c2c2e',
      onDisappear: () => { this.isPlayListOpen = false }
    })
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