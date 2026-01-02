// src/main/ets/pages/MusicIndex.ets
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
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
    // 调用我们在 Class 中封装好的初始化方法
    // 这样 UI 代码就不用关心怎么赋值了
    this.globalMusic.initData(songsList);
  }

  // 3. 模拟：用户添加歌曲的函数
  private handleUserAddSong() {
    // 这里未来可以接入 FilePicker 选择文件
    // 现在我们模拟添加一首新歌
    const newSong : SongItemType = {
      id: `user_${Date.now()}`,
      name: `用户导入歌曲 ${this.globalMusic.playList.length + 1}`,
      author: '未知艺术家',
      img: 'ic_music', // 假设有个默认图
      fileName: 'test_local.mp3'
    };

    // 调用 Class 的方法
    this.globalMusic.addSong(newSong);

    // 提示用户 (PromptAction 需要导入，这里简单 console)
    console.info('已添加新歌曲');
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Swiper(this.swiperController) {
          // 传递状态给子视图
          LibraryView({ musicState: this.globalMusic })
          PlaylistView()
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
