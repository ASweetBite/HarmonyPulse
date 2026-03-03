// src/main/ets/pages/MusicIndex.ets
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { GlobalMusic } from '../type/GlobalMusic';
import { MiniPlayBar } from './components/MiniPlayBar';
import { LibraryView } from './views/LibraryView';
import { PlaylistView } from './views/PlaylistView';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MusicImportService } from '../utils/services/MusicImportService';
import RdbManager from '../utils/managers/RdbManager';
import { SongListItemType } from '../type/SongListItemType';
import { AppSignal } from '../type/AppSignal';

@Builder
export function layoutBuilder() {
  MusicIndex();
}

@Entry
@ComponentV2
struct MusicIndex {
  // 连接状态
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!;
  @Local isRdbReady: boolean = false; // 数据库准备状态
  private swiperController: SwiperController = new SwiperController();

  @Local appSignal: AppSignal = AppStorageV2.connect(AppSignal, "AppSignal", () => new AppSignal())!;
  // 2. 使用 @Monitor 监听信号类中的属性
  // 当 shareImportCount 发生变化时执行
  @Monitor("appSignal.shareImportCount")
  async onShareImportChanged() {
    console.info('MusicIndex: 检测到分享导入，准备重新加载数据库');
    await this.refreshDataFromDb();
  }

  async refreshDataFromDb() {
    try {
      const allSongs = await RdbManager.getAllSongs();
      // 这里确保 GlobalMusic 类也使用了 @ObservedV2 和 @Trace
      this.globalMusic.songList = allSongs;
    } catch (e) {
      console.error('刷新失败');
    }
  }
  // 页面加载时初始化数据
  async aboutToAppear() {
    console.info('MusicPlayer: 页面开始初始化');
    const context = getContext(this) as common.UIAbilityContext;

    try {
      await RdbManager.initRdb(getContext(this));
      await this.refreshDataFromDb();
      this.isRdbReady = true;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`MusicPlayer: 初始化失败. Code: ${err.code}, Msg: ${err.message}`);
    }
  }


  // 修改参数，接收包含 id 的歌单对象或直接接收 id
  private handlePlaylistSelected(playlist: SongListItemType) {
    router.pushUrl({
      url: 'pages/PlaylistDetail',
      params: {
        playlistId: playlist.id, // 核心：传递数据库 ID
        playlistName: playlist.name
      }
    }).then(() => {
      console.info(`成功跳转到歌单ID: ${playlist.id}`);
    }).catch((err: Error) => {
      console.error(`跳转失败: ${err.message}`);
    });
  }


  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        if (this.isRdbReady) {
          Swiper(this.swiperController) {
            // 传递状态给子视图
            LibraryView({ musicState: this.globalMusic })

            // 修改PlaylistView，传递点击处理函数
            PlaylistView({
              onPlaylistSelected: (item: SongListItemType) => {
                this.handlePlaylistSelected(item);
              }
            })

          }
          .loop(false)
          .index(0)
          .indicator(true)
          .width('100%')
          .height('100%')
        }else {
          // 数据库加载中的占位提示
          LoadingProgress().width(50).height(50).color('#E23241')
        }

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
        .onClick(async () => {
          const context = getContext(this) as common.UIAbilityContext;
          await MusicImportService.importFromPicker(context, this.globalMusic);

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