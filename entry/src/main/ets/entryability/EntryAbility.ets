import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'
import { avPlayerManage } from '../utils/managers/avPlayerManager'
import { SessionManager } from '../utils/managers/AVSessionManager'
import { lyricManager } from '../utils/managers/LyricManager'
import { MusicShareService } from '../utils/services/MusicShareService'

const DOMAIN = 0x0000

export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 1. 初始化所有单例的 Context
    avPlayerManage.setContext(this.context)
    lyricManager.setContext(this.context)
    MusicShareService.setContext(this.context)

    try {
      this.context
        .getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch (err) {
      hilog.error(DOMAIN, 'testTag',
        'Failed to set colorMode. Cause: %{public}s',
        JSON.stringify(err))
    }

    hilog.info(DOMAIN, 'testTag', 'Ability onCreate')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 初始化播放器（此时 context 已就绪）
    avPlayerManage.init()

    // 初始化 AVSession
    SessionManager.init(this.context)

    hilog.info(DOMAIN, 'testTag', 'Ability onWindowStageCreate')

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(
          DOMAIN,
          'testTag',
          'Failed to load the content. Cause: %{public}s',
          JSON.stringify(err)
        )
        return
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.')
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onWindowStageDestroy')

    // 释放播放器和会话
    avPlayerManage.release()
    SessionManager.DestroySession()
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onDestroy')
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', 'Ability onBackground')
  }
}
