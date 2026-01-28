import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { SongItemType } from '../type/SongItemType';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit'; // 引入 fs 用于检查文件是否存在

class musicShareService {

  private context: common.UIAbilityContext | null = null;

  setContext(ctx: common.UIAbilityContext) {
    this.context = ctx;
  }

  /**
   * 分享单首歌曲
   */
  async shareSong(song: SongItemType): Promise<void> {
    if (!this.context) {
      console.error("MusicShareService: Context is null");
      return;
    }

    try {
      // —— 1. 处理音频 URI —— //
      const fileExt = "." + song.filePath.split('.').pop(); // 'mp3' 等
      const songPath: string = `${this.context.filesDir}/${song.filePath}`;

      // 检查文件是否存在，避免无效 URI 导致的 401 或其他错误
      if (!fs.accessSync(songPath)) {
        console.error(`MusicShareService: 音频文件不存在 -> ${songPath}`);
        return;
      }

      const shareUri: string = fileUri.getUriFromPath(songPath);

      // —— 2. 处理封面 URI (关键修复点) —— //
      let validThumbnailUri: string | undefined = undefined;

      if (song.img && song.img.length > 0) {
        // 如果 song.img 已经是 file://com.example... 格式则直接用
        // 如果是 /data/... 开头的路径，或者 file:///data... (无包名) 的格式，需要重新转换
        if (song.img.startsWith('file://') && !song.img.startsWith('file:///')) {
          validThumbnailUri = song.img;
        } else {
          let cleanImgPath = song.img.replace('file://', '');
          if (fs.accessSync(cleanImgPath)) {
            validThumbnailUri = fileUri.getUriFromPath(cleanImgPath);
          }
        }
      }

      console.info(`MusicShareService: 准备分享 \nAudio: ${shareUri} \nThumb: ${validThumbnailUri}`);

      // —— 3. 构造 SharedRecord —— //
      const audioRecord: systemShare.SharedRecord = {
        utd: utd.UniformDataType.AUDIO,
        uri: shareUri,
        title: song.name + fileExt, // 确保不为空
        description: song.author, // 确保不为空
        thumbnailUri: validThumbnailUri // 只有是有效 URI 时才传
      };

      // —— 4. 构造 SharedData (直接传入 Record) —— //
      // 修复点：直接在构造函数中传入 record，而不是先 new 再 add
      const sharedData: systemShare.SharedData = new systemShare.SharedData(audioRecord);

      // —— 5. 显示分享面板 —— //
      const controller = new systemShare.ShareController(sharedData);

      await controller.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.SINGLE
      });

    } catch (err) {
      const error = err as BusinessError;
      console.error(
        `MusicShareService: 分享失败 code: ${error.code}, msg: ${error.message}`
      );
    }
  }
}

export const MusicShareService = new musicShareService();