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

  // 页面加载时初始化数据
  // 修改为 async，确保加载顺序
  async aboutToAppear() {
    console.info('MusicPlayer: 页面开始初始化');
    const context = getContext(this) as common.UIAbilityContext;

    try {
      // 1. 初始化数据库并建表
      await RdbManager.initRdb(context);
      console.info('MusicPlayer: 数据库初始化完成');

      // 2. 从数据库获取所有歌曲（代替原来的 loadSongs）
      let allSongs = await RdbManager.getAllSongs();

      // 3. 判断是否是初次运行：如果数据库里一首歌都没有，则导入默认写死的数据
      if (allSongs.length === 0) {
        console.info('MusicPlayer: 数据库为空，正在导入默认内置歌曲');
        // 重新获取数据
        allSongs = await RdbManager.getAllSongs();
      }

      // 4. 将数据库中的数据同步到全局状态 globalMusic，驱动 UI 显示
      this.globalMusic.songList = allSongs;
      console.info(`MusicPlayer: 成功从数据库加载了 ${allSongs.length} 首歌`);
      this.isRdbReady = true; // 标记数据库已就绪
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