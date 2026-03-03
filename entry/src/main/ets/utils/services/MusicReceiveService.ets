import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalMusic } from '../../type/GlobalMusic';
import { MusicImportService } from './MusicImportService';
import RdbManager from '../managers/RdbManager';

export default class ShareReceiveAbility extends UIAbility {

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // 1. 在这里做极其重要的初始化：确保数据库可用！
    // 因为如果是冷启动，这里不初始化的话后续插入数据必崩
    try {
      await RdbManager.initRdb(this.context);
    } catch (e) {
      console.error('ShareReceiveAbility DB Init Error', e);
    }

    // 记录 want 等待在 window 加载后处理，或者直接处理
    await this.handleShareWant(want);
  }

  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    await this.handleShareWant(want);
  }

  // 必须实现此方法，加载一个过渡页面（哪怕是纯白页面/Loading页面）
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 建议在 pages 目录下建一个 ShareLoadingPage.ets，显示一个"正在导入..."的菊花图
    windowStage.loadContent('pages/ShareLoadingPage', (err) => {
      if (err.code) {
        console.error(`加载分享过渡页失败: ${JSON.stringify(err)}`);
        return;
      }
    });
  }

  private async handleShareWant(want: Want): Promise<void> {
    try {
      const sharedData: systemShare.SharedData = await systemShare.getSharedData(want);
      const records: systemShare.SharedRecord[] = sharedData.getRecords();

      for (const record of records) {
        await this.handleRecord(record);
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`ShareReceiveAbility: 获取分享数据失败, code=${error.code}`);
      this.startMainAbility(); // 解析失败也拉起主界面，避免卡在过渡页
    }
  }

  private async handleRecord(record: systemShare.SharedRecord): Promise<void> {
    const uri: string | undefined = record.uri;
    const title: string | undefined = record.title;
    const utd = record.utd;

    // 2. 放宽 UTD 校验，兼容 audio.mp3 / audio.flac 等子类型
    const isAudio = utd && (utd.includes('audio') || utd.includes('mp3') || utd.includes('flac'));

    if (isAudio && uri) {
      await this.handleAudio(uri, title);
    } else {
      console.warn(`不支持的分享类型: ${utd}`);
      this.startMainAbility();
    }
  }

  private async handleAudio(uri: string, title?: string): Promise<void> {
    try {
      console.info(`开始处理分享音频: ${uri}`);

      // 1. 初始化一个临时的 GlobalMusic (仅用于 importSingleFile 内部逻辑，如重复校验)
      // 注意：既然主页面已经用 RDB，这里我们只需要关心这个文件能不能导入成功
      const tempGlobalMusic = new GlobalMusic();

      // 如果你的 importSingleFile 逻辑依赖现有列表查重，则需要加载
      // 否则如果 RDB 有唯一约束，这一步甚至可以简化
      await MusicImportService.loadSongs(this.context, tempGlobalMusic);

      // 2. 调用 Service 进行物理文件拷贝和 Song 对象生成
      const song = await MusicImportService.importSingleFile(uri, this.context, tempGlobalMusic);

      if (song) {
        // 3. 核心：直接写入数据库
        // 只要写入数据库成功，持久化任务就完成了
        await RdbManager.insertSong(song);

        // 如果你还在用 Preferences 做备份，保留这行；否则可以删除
        await MusicImportService.saveSongs(this.context, tempGlobalMusic.songList);

        console.info(`分享导入成功并已存入RDB: ${song.name}`);
      }
    } catch (err) {
      console.error(`处理音频分享异常: ${JSON.stringify(err)}`);
    } finally {
      // 无论成功失败，拉起主界面，由主界面根据数据库最新状态展示
      this.startMainAbility();
    }
  }

  private startMainAbility() {
    const want: Want = {
      bundleName: this.context.abilityInfo.bundleName,
      abilityName: 'EntryAbility',
      parameters: {
        'isFromShare': true // 必须携带此标记，触发 EntryAbility 的信号桥接
      }
    };

    this.context.startAbility(want).then(() => {
      this.context.terminateSelf();
    });
  }
}