import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { SongItemType } from '../../type/SongItemType';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit'; // 引入 fs 用于检查文件是否存在

class musicShareService {

  private context: common.UIAbilityContext | null = null;
  private appLogoUri: string = ''; // 缓存 Logo 的 URI

  async setContext(ctx: common.UIAbilityContext) {
    this.context = ctx;
    await this.initAppLogo(ctx);
  }

  /**
   * 初始化时将资源图片转换为可共享的 URI
   */
  async initAppLogo(ctx: common.UIAbilityContext) {
    // 使用传入的 ctx，而不是 this.context
    const logoPath = `${ctx.filesDir}/app_logo.png`;

    if (!fs.accessSync(logoPath)) {
      try {
        const resourceMgr = ctx.resourceManager;
        const fileData = await resourceMgr.getMediaContent($r('app.media.logo'));
        const file = fs.openSync(logoPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, fileData.buffer);
        fs.closeSync(file);
      } catch (e) {
        console.error('MusicShareService: Logo 转换失败', JSON.stringify(e));
      }
    }
    this.appLogoUri = fileUri.getUriFromPath(logoPath);
  }

  getAppLogoUri(): string {
    return this.appLogoUri;
  }

  /**
   * 构造 SharedRecord 对象，包含 URI 构造逻辑
   * @param song 歌曲数据
   * @returns systemShare.SharedRecord
   */
  buildSharedRecord(song: SongItemType): systemShare.SharedRecord {
    if (!this.context) {
      throw new Error("MusicShareService not initialized");
    }

    // —— 1. 处理音频文件 URI (必须转换) ——
    // 假设 song.filePath 存的是文件名 "123.mp3"
    const audioAbsPath = `${this.context.filesDir}/${song.filePath}`;
    // 关键：不要手动拼 "file://"，要用 getUriFromPath
    const audioShareUri = fileUri.getUriFromPath(audioAbsPath);

    // —— 2. 处理封面图 URI (必须转换) ——
    let validThumbnailUri: string | undefined = undefined;

    if (song.img) {
      let imgAbsPath = '';

      // 如果数据库里存的是 "cover_xxx.jpg" 这种文件名
      if (!song.img.includes('/')) {
        imgAbsPath = `${this.context.filesDir}/${song.img}`;
      } else {
        // 如果存的是完整路径，先去掉可能存在的旧 file:// 前缀
        imgAbsPath = song.img.replace('file://', '');
      }

      // 检查文件确实存在后，转换为系统可识别的分享 URI
      try {
        if (fs.accessSync(imgAbsPath)) {
          // 这一步会生成类似 file://com.example.music/data/storage/... 的格式
          validThumbnailUri = fileUri.getUriFromPath(imgAbsPath);
        } else {
          console.warn(`MusicShareService: 封面文件不存在于路径: ${imgAbsPath}`);
        }
      } catch (e) {
        console.error(`MusicShareService: 检查封面权限失败: ${JSON.stringify(e)}`);
      }
    }

    // 如果歌曲没有封面，可以退而求其次使用 App Logo
    if (!validThumbnailUri) {
      validThumbnailUri = this.getAppLogoUri();
    }

    return {
      utd: 'general.audio', // 或者使用 utd.UniformDataType.AUDIO
      uri: audioShareUri,
      title: song.name,
      description: song.author,
      thumbnailUri: validThumbnailUri // 现在的 validThumbnailUri 是跨进程可读的了
    };
  }

  /**
   * 分享多首歌曲
   * @param songs 歌曲数组
   */
  async shareSongs(songs: SongItemType[]): Promise<void> {
    if (!this.context) {
      console.error("MusicShareService: Context is null");
      return;
    }

    if (!songs || songs.length === 0) {
      console.warn("MusicShareService: 分享列表为空");
      return;
    }

    try {
      console.info(`MusicShareService: 开始准备批量分享, 数量: ${songs.length}`);

      let sharedData: systemShare.SharedData | null = null;
      let validCount = 0;

      for (const song of songs) {
        // 检查物理文件是否存在
        const songPath: string = `${this.context.filesDir}/${song.filePath}`;
        if (!fs.accessSync(songPath)) {
          console.warn(`MusicShareService: 忽略不存在的文件 -> ${song.name}`);
          continue;
        }

        // 构造单条记录
        const record = this.buildSharedRecord(song);

        // 初始化 SharedData 或 添加记录
        if (!sharedData) {
          // 第一条记录用于初始化
          sharedData = new systemShare.SharedData(record);
        } else {
          // 后续记录通过 addRecord 添加
          sharedData.addRecord(record);
        }
        validCount++;
      }

      if (!sharedData || validCount === 0) {
        console.error("MusicShareService: 没有有效的歌曲可供分享");
        return;
      }

      // —— 显示分享面板 —— //
      const controller = new systemShare.ShareController(sharedData);

      // 对于多文件分享，建议使用 BATCH 模式
      await controller.show(this.context, {
        previewMode: systemShare.SharePreviewMode.DEFAULT,
        selectionMode: systemShare.SelectionMode.BATCH
      });

      console.info(`MusicShareService: 批量分享面板已弹出, 有效数量: ${validCount}`);

    } catch (err) {
      const error = err as BusinessError;
      console.error(
        `MusicShareService: 批量分享失败 code: ${error.code}, msg: ${error.message}`
      );
    }
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
  /**
   * 封装集合分享数据（用于资料库或歌单）
   * @param songs 歌曲列表
   * @param collectionName 显示的集合名称（如“资料库”或歌单名）
   * @param collectionCover 集合封面图（如歌单封面）
   */
  buildCollectionSharedData(songs: SongItemType[], collectionName: string, collectionCover?: string): systemShare.SharedData | null {
    if (songs.length === 0) return null;

    let sharedData: systemShare.SharedData | null = null;

    for (let i = 0; i < songs.length; i++) {
      const song = songs[i];
      const record = this.buildSharedRecord(song);

      // --- 关键视觉优化：重写第一条记录的元数据用于展示 ---
      // 系统通常取第一条 record 的 title 和 thumbnail 作为整个分享任务的预览
      if (i === 0) {
        record.title = collectionName; // 显示为“资料库”或“周杰伦精选集”
        if (collectionCover) {
          // 如果有歌单封面，第一条记录使用歌单封面
          record.thumbnailUri = fileUri.getUriFromPath(collectionCover);
        }
        record.description = `共 ${songs.length} 首歌曲`;
      }

      if (!sharedData) {
        sharedData = new systemShare.SharedData(record);
      } else {
        sharedData.addRecord(record);
      }
    }
    return sharedData;
  }
}

export const MusicShareService = new musicShareService();