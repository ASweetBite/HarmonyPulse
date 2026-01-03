// src/main/ets/pages/MusicIndex.ets
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../type/GlobalMusic';
import { songsList } from '../type/data';
import { MiniPlayBar } from './components/MiniPlayBar';
import { LibraryView } from './views/LibraryView';
import { PlaylistView } from './views/PlaylistView';
import { SongItemType } from '../type/SongItemType';
import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { media } from '@kit.MediaKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

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
  private async handleUserAddSong() {
    const context = getContext(this) as common.UIAbilityContext;

    try {
      // Step 1: 调起文件选择器 (音频)
      const audioPicker = new picker.AudioViewPicker();
      const uris = await audioPicker.select(new picker.AudioSelectOptions());

      // 如果用户取消了选择，直接返回
      if (!uris || uris.length === 0) return;

      // 遍历选中的文件
      for (const uri of uris) {
        // --- 逻辑处理：提取原始文件名作为备份标题 ---
        // uri 示例: file://docs/storage/Users/currentUser/Download/SongName.mp3
        const decodeUri = decodeURIComponent(uri);
        const lastSlashIndex = decodeUri.lastIndexOf('/');
        const fullFileName = decodeUri.substring(lastSlashIndex + 1);
        const lastDotIndex = fullFileName.lastIndexOf('.');

        // 得到不带后缀的文件名 (如 "七里香") 和 后缀名 (如 ".mp3")
        const fileNameWithoutExt = lastDotIndex !== -1 ? fullFileName.substring(0, lastDotIndex) : fullFileName;
        const fileExt = lastDotIndex !== -1 ? fullFileName.substring(lastDotIndex) : '.mp3';

        // --- Step 2: 拷贝文件到应用沙箱 (filesDir) ---
        // rawfile 是只读的，导入的文件必须存放在 context.filesDir
        const newFileName = `${Date.now()}${fileExt}`; // 使用时间戳重命名防止冲突
        const destPath = `${context.filesDir}/${newFileName}`;

        const srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const destFile = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.copyFileSync(srcFile.fd, destFile.fd);
        fs.closeSync(srcFile);
        fs.closeSync(destFile);

        // --- Step 3: 解析 MP3 元数据 ---
        let title = fileNameWithoutExt; // 默认使用文件名
        let artist = '未知艺术家';
        let coverUri = 'ic_music';     // 默认图标名

        let avMetadataExtractor: media.AVMetadataExtractor | undefined = undefined;
        let targetFile: fs.File | undefined = undefined;

        try {
          avMetadataExtractor = await media.createAVMetadataExtractor();
          targetFile = fs.openSync(destPath, fs.OpenMode.READ_ONLY);
          avMetadataExtractor.fdSrc = { fd: targetFile.fd };

          // 获取元数据
          const metadata: media.AVMetadata = await avMetadataExtractor.fetchMetadata();

          // 优先级：内置标签 > 文件名
          if (metadata.title && metadata.title.trim().length > 0) {
            title = metadata.title;
          }
          if (metadata.artist && metadata.artist.trim().length > 0) {
            artist = metadata.artist;
          }

          // 提取封面图
          const pixelMap = await avMetadataExtractor.fetchAlbumCover();
          if (pixelMap) {
            const coverFileName = `cover_${Date.now()}.jpg`;
            const coverPath = `${context.filesDir}/${coverFileName}`;
            const imgFile = fs.openSync(coverPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

            const imagePacker = image.createImagePacker();
            await imagePacker.packToFile(pixelMap, imgFile.fd, { format: 'image/jpeg', quality: 80 });

            fs.closeSync(imgFile);
            coverUri = `file://${coverPath}`; // 转换为 UI 可识别的路径协议
          }
        } catch (e) {
          console.error(`解析元数据出错: ${JSON.stringify(e)}`);
        } finally {
          // 必须释放资源
          if (avMetadataExtractor) await avMetadataExtractor.release();
          if (targetFile) fs.closeSync(targetFile);
        }

        // --- Step 4: 构造对象并加入全局列表 ---
        const newSong: SongItemType = {
          id: `user_${Date.now()}_${Math.random().toString(36).slice(2, 5)}`,
          name: title,
          author: artist,
          img: coverUri,
          fileName: newFileName // 这里记录沙箱中的文件名
        };

        this.globalMusic.addSong(newSong);
      }

      console.info('所有选定歌曲已导入完毕');

    } catch (err) {
      const error = err as BusinessError;
      console.error(`导入失败: 代码 ${error.code}, 消息 ${error.message}`);
    }
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
