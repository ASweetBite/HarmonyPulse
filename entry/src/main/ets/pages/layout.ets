import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../type/GlobalMusic'; // 确保路径正确
import { SongItemType } from '../type/SongItemType'; // 确保路径正确
import { avPlayerManage } from '../utils/avPlayerMusic'; // 确保路径正确
import { MultiNavigation, MultiNavPathStack, SplitPolicy } from '@kit.ArkUI';
import { songsList } from '../type/data'

@Builder
export function layoutBuilder() {
  layout();
}

@Entry
@ComponentV2
struct layout {
  // --- 状态管理 ---
  @Local GlobalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => {
    // 初始化 GlobalMusic 实例时，注入 songsList 到 playList
    const globalMusicInstance = new GlobalMusic()
    // 核心：将静态歌曲列表赋值给全局播放列表
    globalMusicInstance.playList = songsList
    // 初始化当前播放索引（默认第一首）
    globalMusicInstance.currentMusic = 0
    // 初始化播放状态（默认暂停）
    globalMusicInstance.isPlay = false
    // 初始化播放模式（默认顺序播放，需确保 GlobalMusic 中有该属性）
    globalMusicInstance.playbackStatus = "顺序播放"
    return globalMusicInstance
  })!
  // 控制全屏播放器是否展开
  @Local isFullScreenPlayerOpen: boolean = false;
  // Swiper 控制器，用于左右滑动切换
  private swiperController: SwiperController = new SwiperController();
  // 模拟歌单集合数据
  private playlistCollections: string[] = ["我喜欢的音乐", "最近播放", "车载经典", "周杰伦合集", "轻音乐", "助眠歌单"];

  // --- 1. 资源库视图 (主页 - 所有歌曲) ---
  @Builder
  LibraryView() {
    Column() {
      // 顶部大标题
      Text("资料库")
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black) // 浅色模式用黑，深色用白，此处演示用黑
        .width('100%')
        .padding({ left: 20, top: 60, bottom: 10 })
        .backgroundColor(Color.White)

      Divider()

      List() {
        ForEach(this.GlobalMusic.playList, (item: SongItemType, index: number) => {
          ListItem() {
            if (this.GlobalMusic.playList?.length === 0) {
              ListItem() {
                Text("暂无歌曲数据")
                  .fontSize(16)
                  .fontColor(Color.Gray)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding(50)
              }
            } else {
              Row() {
                // 封面
                Image(item.img || $r('app.media.ic_cd')) // 假设有默认图
                  .width(50)
                  .height(50)
                  .borderRadius(6)
                  .margin({ right: 15 })
                  .fillColor(Color.Gray)

                // 信息
                Column() {
                  Text(item.name)
                    .fontSize(16)
                    .fontColor(this.GlobalMusic.currentID === item.id ? '#E23241' : Color.Black)
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

                // 更多操作
                Image($r('app.media.ic_more'))
                  .width(20)
                  .height(20)
                  .fillColor(Color.Gray)
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 10,
                bottom: 10
              })
              .backgroundColor(Color.White)
              .onClick(() => {
                avPlayerManage.playResources(item)
              })
            }
          }
          .swipeAction({ end: this.DeleteButton(index) }) // 侧滑删除
        })

        // 底部垫高，防止被 PlayBar 遮挡
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

  @Builder
  PlaylistIconOverlay() {
    Stack() { // 布局上下文包裹
      Image($r('app.media.ic_song_list'))
        .width('40%')
        .fillColor(Color.Gray)
    }
  }

  // --- 2. 歌单集合视图 (侧滑进入 - 选择不同歌单) ---
  @Builder
  PlaylistCollectionView() {
    Column() {
      Text("我的歌单")
        .fontSize(34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .width('100%')
        .padding({ left: 20, top: 60, bottom: 10 })
        .backgroundColor('#F2F2F7') // 稍作区分的背景色

      Grid() {
        ForEach(this.playlistCollections, (item: string) => {
          GridItem() {
            Column() {
              // 歌单封面模拟
              Rect()
                .width('100%')
                .aspectRatio(1)
                .fill('#ddd')
                .borderRadius(12)
                .overlay(this.PlaylistIconOverlay())

              Text(item)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 8 })
                .width('100%')
            }
            .padding(10)
            .onClick(() => {
              // 这里写逻辑：切换到该歌单
              console.info(`切换到歌单: ${item}`);
              // 比如: this.GlobalMusic.playList = getSongsByPlaylist(item);
              // 切换后自动滑回主页
              this.swiperController.changeIndex(0, true);
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr') // 两列
      .rowsGap(15)
      .padding({ left: 10, right: 10 })
      .width('100%')
      .layoutWeight(1)

      // 底部垫高
      Column().height(90)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  // --- 3. 底部 PlayBar (Mini Player) ---
  @Builder
  MiniPlayBar() {
    Row() {
      // 封面 (旋转动画可选)
      Image(this.GlobalMusic.img)
        .width(40)
        .height(40)
        .borderRadius(4)
        .margin({ left: 20, right: 12 })
        .backgroundColor('#eee')

      // 歌曲信息
      Text(this.GlobalMusic.name || "未在播放")
        .fontSize(16)
        .fontColor(Color.Black)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 播放控制
      Row({ space: 15 }) {
        Image(this.GlobalMusic.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(28)
          .height(28)
          .fillColor(Color.Black)
          .onClick((event: ClickEvent) => {
            avPlayerManage.stopOrContinueSong();
          })

        Image($r('app.media.ic_next'))
          .width(28)
          .height(28)
          .fillColor(Color.Black)
          .margin({ right: 20 })
          .onClick((event: ClickEvent) => {
            avPlayerManage.nextSong();
          })
      }
    }
    .width('94%')
    .height(64)
    .backgroundColor('rgba(255, 255, 255, 0.9)') // 半透明
    .backdropBlur(20) // 毛玻璃效果 (核心 Apple 风格)
    .borderRadius(12)
    .shadow({ radius: 20, color: 'rgba(0,0,0,0.1)', offsetY: 5 })
    .margin({ bottom: 10 })
    .onClick(() => {
      // 点击 MiniBar 展开全屏
      this.isFullScreenPlayerOpen = true;
    })
    // 绑定全屏模态转场
    .bindContentCover(this.isFullScreenPlayerOpen, this.FullScreenPlayer(), {
      modalTransition: ModalTransition.DEFAULT, // 默认的从下往上滑出动画
      backgroundColor: Color.Black,
      onDisappear: () => {
        this.isFullScreenPlayerOpen = false
      }
    })
  }

  // --- 4. 全屏播放器 (展开后的界面) ---
  @Builder
  FullScreenPlayer() {
    Column() {
      // 顶部把手 (指示可以向下滑动关闭)
      Button({
        type: ButtonType.Capsule,
        stateEffect: false
      })
        .width(40)
        .height(5)
        .backgroundColor('#333') // 替代 fillColor，Button 用 backgroundColor 设置背景
        .margin({ top: 15, bottom: 20 })
        .onClick(() => {
          this.isFullScreenPlayerOpen = false
        })
      //信息区
      Column({ space: 5 }) {
        Text(this.GlobalMusic.name || "未知歌曲")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.GlobalMusic.author || "未知歌手")
          .fontSize(20)
          .fontColor('#ccc')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('85%')
      .alignItems(HorizontalAlign.Center) // 歌曲信息水平居中
      .margin({ bottom: 30 })
      // 大图
      Image(this.GlobalMusic.img)
        .width('85%')
        .aspectRatio(1)
        .borderRadius(20)
        .shadow({ radius: 40, color: 'rgba(0,0,0,0.4)', offsetY: 20 })
        .margin({ top: 30, bottom: 50 })

      // 进度条
      Row() {
        Text(this.number2time(this.GlobalMusic.time)).fontColor('#999').fontSize(12)
        Slider({ value: this.GlobalMusic.time, max: this.GlobalMusic.duration })
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
        Text(this.number2time(this.GlobalMusic.duration)).fontColor('#999').fontSize(12)
      }
      .width('85%')
      .margin({ bottom: 30 })

      // 控制按钮
      Row({ space: 40 }) {
        Image($r('app.media.ic_prev')).width(40).fillColor(Color.White).onClick(() => avPlayerManage.preSong())
        Image(this.GlobalMusic.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(70)
          .fillColor(Color.White)
          .onClick(() => avPlayerManage.stopOrContinueSong())
        Image($r('app.media.ic_next')).width(40).fillColor(Color.White).onClick(() => avPlayerManage.nextSong())
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1c1c1e')
    .justifyContent(FlexAlign.Center) // 整体垂直居中，让封面处于页面中间
    .alignItems(HorizontalAlign.Center) // 整体水平居中
    .expandSafeArea(
      [SafeAreaType.SYSTEM],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]
    )
    .gesture(
      PanGesture({ direction: PanDirection.Down })
        .onActionEnd((event) => {
          if (event.offsetY > 100) {
            this.isFullScreenPlayerOpen = false;
          }
        })
    )
  }

  // --- 辅助工具 ---
  @Builder
  DeleteButton(index: number) {
    Button() {
      Image($r('app.media.ic_close')).width(20).fillColor(Color.White)
    }
    .width(60)
    .height('100%')
    .backgroundColor(Color.Red)
    .type(ButtonType.Normal)
    .onClick(() => avPlayerManage.deleteSong(index))
  }

  number2time(number: number) {
    const m = Math.floor(number / 1000 / 60);
    const s = Math.floor(number / 1000 % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  // --- 主构建 ---
  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Swiper(this.swiperController) {
          this.LibraryView() // 左侧：本地歌曲库
          this.PlaylistCollectionView() // 右侧：歌单选择
        }
        .loop(false) // 禁止循环播放
        .index(0) // 默认显示资源库
        .indicator(true) // 显示下方的小圆点指示器
        .width('100%')
        .height('100%')

        this.MiniPlayBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .backgroundColor(Color.White)
  }

}
