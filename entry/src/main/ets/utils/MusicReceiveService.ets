import { UIAbility, Want } from '@kit.AbilityKit'
import { systemShare } from '@kit.ShareKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { GlobalMusic } from '../type/GlobalMusic' // 假设路径
import { MusicImportService } from './MusicImportService' // 假设路径
import RdbManager from './RdbManager' // 假设路径

export default class ShareReceiveAbility extends UIAbility {

  async onCreate(want: Want): Promise<void> {
    await this.handleShareWant(want)
  }

  async onNewWant(want: Want): Promise<void> {
    await this.handleShareWant(want)
  }

  /**
   * 统一处理分享数据
   */
  private async handleShareWant(want: Want): Promise<void> {
    try {
      const sharedData: systemShare.SharedData = await systemShare.getSharedData(want)
      const records: systemShare.SharedRecord[] = sharedData.getRecords()

      for (const record of records) {
        // 这里的上下文 this.context 是 ShareReceiveAbility 的上下文
        await this.handleRecord(record)
      }
    } catch (err) {
      const error = err as BusinessError
      console.error(`ShareReceiveAbility: 获取分享数据失败, code=${error.code}, msg=${error.message}`)
    }
  }

  private async handleRecord(record: systemShare.SharedRecord): Promise<void> {
    const uri: string | undefined = record.uri
    const title: string | undefined = record.title
    const utd = record.utd

    if (utd === 'general.audio' && uri) {
      await this.handleAudio(uri, title)
    }
  }

  /**
   * 处理音频分享
   */
  private async handleAudio(
    uri: string,
    title?: string,
    artist?: string,
    coverUri?: string
  ): Promise<void> {
    try {
      console.info(`开始处理分享音频: ${uri}`)

      // 1. 初始化临时的 GlobalMusic 容器
      // ShareAbility 和 MainAbility 内存不共享，需要新建实例
      const tempGlobalMusic = new GlobalMusic()

      // 2. 从首选项加载现有歌曲列表
      // 这一步至关重要：为了让 importSingleFile 中的【去重逻辑】生效
      await MusicImportService.loadSongs(this.context, tempGlobalMusic)

      // 3. 调用 Service 进行导入
      // 注意：请确保 MusicImportService.importSingleFile 已改为 public
      const song = await MusicImportService.importSingleFile(uri, this.context, tempGlobalMusic)

      if (song) {
        // 4.1 更新内存列表
        tempGlobalMusic.addSong(song)

        // 4.2 写入 RDB 数据库
        // 确保 RdbManager 已初始化，如果 RdbManager 依赖 context，可能需要手动 init
        await RdbManager.insertSong(song)

        // 4.3 持久化更新后的列表到首选项
        await MusicImportService.saveSongs(this.context, tempGlobalMusic.songList)

        console.info(`分享导入成功: ${song.name}`)

        // 5. 导入成功后，拉起主应用 (EntryAbility)
        this.startMainAbility()
      } else {
        console.warn('导入返回空，可能是重复歌曲或解析失败')
        // 也可以选择在这里拉起主应用提示用户
        this.startMainAbility()
      }

    } catch (err) {
      console.error(`处理音频分享异常: ${JSON.stringify(err)}`)
    }
  }

  /**
   * 拉起主应用
   */
  private startMainAbility() {
    const want: Want = {
      bundleName: this.context.abilityInfo.bundleName,
      abilityName: 'EntryAbility' // 请根据你的实际主 Ability 名称修改
    }
    this.context.startAbility(want).then(() => {
      // 可选：拉起主应用后关闭当前的分享面板 Ability
      this.context.terminateSelf()
    }).catch((err: BusinessError) => {
      console.error(`拉起主应用失败: ${err.code}`)
    })
  }
}