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
   * 构造 SharedRecord 对象，包含 URI 构造逻辑
   * @param song 歌曲数据
   * @returns systemShare.SharedRecord
   */
  buildSharedRecord(song: SongItemType): systemShare.SharedRecord {
    // —— 1. 处理音频 URI —— //
    const fileExt = "." + song.filePath.split('.').pop(); // 'mp3' 等
    const songPath: string = `${this.context!.filesDir}/${song.filePath}`; // 假设 context 已经设置

    // 检查文件是否存在
    if (!fs.accessSync(songPath)) {
      console.warn(`MusicShareService: _buildSharedRecord 警告: 音频文件不存在 -> ${songPath}`);
    }

    const shareUri: string = fileUri.getUriFromPath(songPath);

    // —— 2. 处理封面 URI —— //
    let validThumbnailUri: string | undefined = undefined;

    if (song.img && song.img.length > 0) {
      // 如果 song.img 已经是 file://com.example... 格式则直接用
      if (song.img.startsWith('file://') && !song.img.startsWith('file:///')) {
        validThumbnailUri = song.img;
      } else {
        // 否则尝试清理并检查路径是否有效
        let cleanImgPath = song.img.replace('file://', '');
        if (fs.accessSync(cleanImgPath)) {
          validThumbnailUri = fileUri.getUriFromPath(cleanImgPath);
        }
      }
    }

    console.info(`MusicShareService: _buildSharedRecord 构建 \nAudio: ${shareUri} \nThumb: ${validThumbnailUri}`);


    // —— 3. 构造 SharedRecord —— //
    const audioRecord: systemShare.SharedRecord = {
      utd: utd.UniformDataType.AUDIO,
      uri: shareUri,
      title: song.name + fileExt, // 确保不为空
      description: song.author, // 确保不为空
      thumbnailUri: validThumbnailUri // 只有是有效 URI 时才传
    };

    return audioRecord;
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
      // **重要：为了确保 _buildSharedRecord 中 fs.accessSync 不会因 this.context 导致的潜在问题而失败，
      // 并且保持 shareSong 内部对文件存在的明确控制，这里仍然保留文件存在的检查。
      // 如果 _buildSharedRecord 完全独立，它将需要 context 作为参数。
      // 在当前设计下，我们仅在 _buildSharedRecord 中调用它，并依赖 context 存在。

      const songPath: string = `${this.context.filesDir}/${song.filePath}`;
      if (!fs.accessSync(songPath)) {
        console.error(`MusicShareService: 音频文件不存在 -> ${songPath}`);
        return;
      }

      // —— 1. 构造 SharedRecord (调用封装函数) —— //
      const audioRecord: systemShare.SharedRecord = this.buildSharedRecord(song);

      // —— 2. 构造 SharedData —— //
      const sharedData: systemShare.SharedData = new systemShare.SharedData(audioRecord);

      // —— 3. 显示分享面板 —— //
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