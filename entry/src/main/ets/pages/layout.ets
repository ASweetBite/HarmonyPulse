// src/main/ets/pages/MusicIndex.ets
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../type/GlobalMusic';
import { songsList } from '../type/data';
import { MiniPlayBar } from './components/MiniPlayBar'; // 导入组件
import { LibraryView } from './views/LibraryView';   // 导入视图
import { PlaylistView } from './views/PlaylistView'; // 导入视图

// 如果使用了路由配置，这里可以使用 layoutBuilder
@Builder
export function layoutBuilder() {
  MusicIndex();
}

@Entry
@ComponentV2
struct MusicIndex {
  // --- 状态管理 (只在这里连接 AppStorage) ---
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => {
    const instance = new GlobalMusic()
    instance.playList = songsList
    instance.currentMusic = 0
    instance.isPlay = false
    instance.playbackStatus = "顺序播放"
    return instance
  })!

  private swiperController: SwiperController = new SwiperController();

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 主体内容区域
        Swiper(this.swiperController) {
          // 视图 1：资料库
          // 将 globalMusic 状态向下传递
          LibraryView({ musicState: this.globalMusic })

          // 视图 2：歌单
          PlaylistView({
            onPlaylistSelected: (name: string) => {
              console.info(`切换到歌单: ${name}`);
              // 可以在这里处理数据加载逻辑
              this.swiperController.changeIndex(0, true); // 切回主页
            }
          })
        }
        .loop(false)
        .index(0)
        .indicator(true)
        .width('100%')
        .height('100%')

        // 底部播放器组件
        MiniPlayBar({ musicState: this.globalMusic })
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
