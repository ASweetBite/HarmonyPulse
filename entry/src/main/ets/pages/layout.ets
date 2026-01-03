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
  // 修改为 async，确保加载顺序
  async aboutToAppear() {
    console.info('MusicPlayer: 页面开始初始化');
    const context = getContext(this) as common.UIAbilityContext;

    try {
      // 1. 先尝试从首选项（Preferences）加载永久存储的歌曲
      await MusicImportService.loadSongs(context, this.globalMusic);

      // 2. 逻辑判断：如果缓存里一首歌都没有，说明是第一次安装或清空了，此时才加载默认列表
      if (this.globalMusic.songList.length === 0) {
        console.info('MusicPlayer: 缓存为空，加载默认内置歌曲');
        this.globalMusic.initData(songsList);
        // 加载了默认数据后，也可以顺手存一下
        await MusicImportService.saveSongs(context, this.globalMusic.songList);
      } else {
        console.info(`MusicPlayer: 成功从持久化存储恢复了 ${this.globalMusic.songList.length} 首歌`);
      }
    } catch (e) {
      console.error('MusicPlayer: 初始化数据失败', JSON.stringify(e));
    }
  }


  //处理歌单点击跳转
  private handlePlaylistSelected(playlistName: string) {
    // 使用路由跳转到歌单详情页[6](@ref)
    router.pushUrl({
      url: 'pages/PlaylistDetail', // 目标页面路径
      params: {
        playlistName: playlistName,
        songCount: this.globalMusic.songList.length // 传递歌曲数量
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
        .onClick(async () => {
          const context = getContext(this) as common.UIAbilityContext;
          // 导入歌曲
          await MusicImportService.importFromPicker(context, this.globalMusic);
          // 导入函数内部应该已经执行了 saveSongs，这里为了保险也可以再补一次
          await MusicImportService.saveSongs(context, this.globalMusic.songList);
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