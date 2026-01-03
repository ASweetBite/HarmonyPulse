// src/main/ets/pages/MusicIndex.ets
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { router } from '@kit.ArkUI'; // 添加路由导入
import { GlobalMusic } from '../type/GlobalMusic';
import { songsList } from '../type/data';
import { MiniPlayBar } from './components/MiniPlayBar';
import { LibraryView } from './views/LibraryView';
import { PlaylistView } from './views/PlaylistView';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MusicImportService } from '../utils/MusicImportService';

@Builder
export function layoutBuilder() {
  MusicIndex();
}

@Entry
@ComponentV2
struct MusicIndex {
  // 连接状态
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!;

  private swiperController: SwiperController = new SwiperController();

  // 页面加载时初始化数据
  aboutToAppear(): void {
    // 调用我们在 Class 中封装好的初始化方法
    // 这样 UI 代码就不用关心怎么赋值了
    this.globalMusic.initData(songsList);
  }

  //处理歌单点击跳转
  private handlePlaylistSelected(playlistName: string) {
    // 使用路由跳转到歌单详情页[6](@ref)
    router.pushUrl({
      url: 'pages/PlaylistDetail', // 目标页面路径
      params: {
        playlistName: playlistName,
        songCount: this.globalMusic.playList.length // 传递歌曲数量
      }
    }).then(() => {
      console.info(`跳转到歌单详情页: ${playlistName}`);
    }).catch((err: Error) => {
      console.error(`跳转失败: ${err.message}`);
    });
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Swiper(this.swiperController) {
          // 传递状态给子视图
          LibraryView({ musicState: this.globalMusic })

          // 修改PlaylistView，传递点击处理函数
          PlaylistView({
            onPlaylistSelected: (name: string) => {
              this.handlePlaylistSelected(name);
            }
          })
        }
        .loop(false)
        .index(0)
        .indicator(true)
        .width('100%')
        .height('100%')

        Button({ type: ButtonType.Circle }) {
          Text("+")
            .fontSize(30)
            .fontColor(Color.White)
            .padding({ bottom: 4 }) // 视觉修正
        }
        .width(50)
        .height(50)
        .position({ x: '80%', y: '75%' }) // 悬浮在右下角
        .backgroundColor('#E23241')
        .shadow({ radius: 10, color: '#99E23241' })
        .onClick(() => {
          const context = getContext(this) as common.UIAbilityContext
          MusicImportService.importFromPicker(context, this.globalMusic);
        })

        // 底部播放器
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