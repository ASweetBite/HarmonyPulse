import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window, promptAction } from '@kit.ArkUI'; // 引入 promptAction
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalMusic } from '../../type/GlobalMusic';
import { MusicImportService } from './MusicImportService';
import RdbManager from '../managers/RdbManager';

export default class ShareReceiveAbility extends UIAbility {
  private savedWant: Want | undefined = undefined;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    this.savedWant = want;
    try {
      await RdbManager.initRdb(this.context);
    } catch (e) {
      console.error('ShareReceiveAbility DB Init Error', e);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.savedWant = want;
    this.handleShareWant(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 加载透明页面
    windowStage.loadContent('pages/ShareLoadingPage', (err) => {
      if (err.code) return;

      // 窗口加载成功后，开始处理逻辑
      if (this.savedWant) {
        this.handleShareWant(this.savedWant);
      }
    });
  }

  private async handleShareWant(want: Want): Promise<void> {
    try {
      const sharedData: systemShare.SharedData = await systemShare.getSharedData(want);
      const records: systemShare.SharedRecord[] = sharedData.getRecords();

      if (records.length > 0) {
        // 提示：开始导入
        promptAction.showToast({ message: '歌曲正在导入...', duration: 2000 });

        for (const record of records) {
          await this.handleRecord(record);
        }

        // 提示：导入完成
        promptAction.showToast({ message: '导入完成', duration: 2000 });
      }
    } catch (err) {
      console.error(`ShareReceiveAbility: 获取分享数据失败`);
    } finally {
      // 延迟一小会儿跳转，确保用户能看清“导入完成”的提示
      setTimeout(() => {
        this.startMainAbility();
      }, 500);
    }
  }

  private async handleRecord(record: systemShare.SharedRecord): Promise<void> {
    const uri: string | undefined = record.uri;
    const utd = record.utd;
    const isAudio = utd && (utd.includes('audio') || utd.includes('mp3') || utd.includes('flac'));

    if (isAudio && uri) {
      await this.handleAudio(uri, record.title);
    }
  }

  /**
   * 处理分享过来的音频
   */
  private async handleAudio(uri: string, title?: string): Promise<void> {
    try {
      console.info(`ShareReceiveAbility: 开始处理分享音频: ${uri}`);

      // 1. 获取数据库中现有的歌曲，用于构造查重 Set
      // 这里的逻辑要与 MusicImportService 中的 importFromPicker 保持一致
      const currentSongs = await RdbManager.getAllSongs();
      const existingKeys = new Set<string>();
      currentSongs.forEach(s => {
        existingKeys.add(`${s.name}-${s.author}`);
      });

      // 2. 调用更新后的导入逻辑
      // 注意：这里不再需要 loadSongs 到一个临时 GlobalMusic，直接利用 RDB 的结果进行查重
      const song = await MusicImportService.importSingleFile(uri, this.context, existingKeys);

      if (song) {
        // 3. 写入数据库
        await RdbManager.insertSong(song);

        // 4. 更新 Preferences 备份
        // 将新导入的歌曲加入当前列表并全量保存一次，确保 Preferences 与 RDB 同步
        currentSongs.push(song);
        await MusicImportService.saveSongs(this.context, currentSongs);

        console.info(`ShareReceiveAbility: 分享歌曲 [${song.name}] 导入并持久化成功`);
      } else {
        console.warn('ShareReceiveAbility: 歌曲已存在或解析失败，跳过导入');
      }

    } catch (err) {
      const error = err as BusinessError;
      console.error(`ShareReceiveAbility: 处理音频分享异常, code: ${error.code}, msg: ${error.message}`);
    }
  }

  private startMainAbility() {
    const want: Want = {
      bundleName: this.context.abilityInfo.bundleName,
      abilityName: 'EntryAbility',
      parameters: {
        'isFromShare': true // 告知 EntryAbility 刷新列表
      }
    };

    this.context.startAbility(want).then(() => {
      this.context.terminateSelf();
    });
  }
}