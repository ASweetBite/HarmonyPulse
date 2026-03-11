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

        if (!this.globalMusic.isSelecting) {
          Button({ type: ButtonType.Circle }) {
            Text("+").fontSize(30).fontColor(Color.White)
          }
          .width(56).height(56)
          .position({ x: '82%', y: '72%' })
          .backgroundColor('#E23241')
          .shadow({ radius: 15, color: 'rgba(226, 50, 65, 0.4)', offsetY: 6 })
          .onClick(async () => {
            const context = getContext(this) as common.UIAbilityContext;
            await MusicImportService.importFromPicker(context, this.globalMusic);
          })
          .transition(
            TransitionEffect.OPACITY
              .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 消失时缩写到0
              .animation({ duration: 250, curve: Curve.EaseInOut })
          )
        }

        // 3. 底部播放条：位移转场
        if (!this.globalMusic.isSelecting) {
          Column() {
            MiniPlayBar({ musicState: this.globalMusic })
          }
          .width('100%')
          .transition(
            TransitionEffect.move(TransitionEdge.BOTTOM) // 修正：小写 move
              .animation({ duration: 300, curve: Curve.Friction })
          )
        }
      }
      .width('100%')
      .height('100%')
      .clip(false) // 重要：允许子组件在转场过程中超出边界
    }
    .hideTitleBar(true)
    .backgroundColor(Color.White)
  }
}