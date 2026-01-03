// src/main/ets/pages/MusicIndex.ets
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { router } from '@kit.ArkUI'; // 添加路由导入
import { GlobalMusic } from '../type/GlobalMusic';
import { songsList } from '../type/data';
import { MiniPlayBar } from './components/MiniPlayBar';
import { LibraryView } from './views/LibraryView';
import { PlaylistView } from './views/PlaylistView';
import { SongItemType } from '../type/SongItemType';

@Builder
export function layoutBuilder() {
  MusicIndex();
}

@Entry
@ComponentV2
struct MusicIndex {
  // 1. 连接状态
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!;

  private swiperController: SwiperController = new SwiperController();

  // 2. 生命周期：页面加载时初始化数据
  aboutToAppear(): void {
    this.globalMusic.initData(songsList);
  }

  // 3. 模拟：用户添加歌曲的函数
  private handleUserAddSong() {
    const newSong : SongItemType = {
      id: `user_${Date.now()}`,
      name: `用户导入歌曲 ${this.globalMusic.playList.length + 1}`,
      author: '未知艺术家',
      img: 'ic_music',
      fileName: 'test_local.mp3'
    };

    this.globalMusic.addSong(newSong);
    console.info('已添加新歌曲');
  }

  // 4. 新增：处理歌单点击跳转的函数
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

        // --- 新增：添加歌曲的悬浮按钮 (仅在测试阶段使用) ---
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
          this.handleUserAddSong();
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