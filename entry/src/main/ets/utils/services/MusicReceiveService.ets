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

  private async handleAudio(uri: string, title?: string): Promise<void> {
    try {
      const tempGlobalMusic = new GlobalMusic();
      // 查重逻辑
      await MusicImportService.loadSongs(this.context, tempGlobalMusic);
      const song = await MusicImportService.importSingleFile(uri, this.context, tempGlobalMusic);

      if (song) {
        await RdbManager.insertSong(song);
        await MusicImportService.saveSongs(this.context, tempGlobalMusic.songList);
      }
    } catch (err) {
      console.error(`处理音频分享异常: ${JSON.stringify(err)}`);
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