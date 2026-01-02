import { avSession } from "@kit.AVSessionKit";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { backgroundTaskManager } from "@kit.BackgroundTasksKit";
import { wantAgent } from "@kit.AbilityKit";
import { GlobalMusic } from "../type/GlobalMusic";
import { AppStorageV2 } from "@kit.ArkUI";
import { SongItemType } from "../type/SongItemType";
import { avPlayerManage } from "./avPlayerMusic";


class AVSessionManager {
  session: avSession.AVSession | null = null
  GlobalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!

  async init(context: Context) {
    try {
      this.session = await avSession.createAVSession(context, 'bgPlay', 'audio');
      this.RegisterControlCommand()
    } catch (error) {
      hilog.error(0x0000, "ss", error);
    }
  }

  //申请长时任务
  async startContinuousTask() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: "com.example.heimayun",
          abilityName: "EntryAbility"
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };
    try {
      const want = await wantAgent.getWantAgent(wantAgentInfo)
      await backgroundTaskManager.startBackgroundRunning(getContext(),
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, want)
    } catch (error) {
      hilog.error(0x0000, "ss", error);
    }
  }

  //设置元数据
  SetMetaData(song: SongItemType) {
    this.session?.setAVMetadata({
      assetId: song.id, // 由应用指定，用于标识应用媒体库里的媒体。
      title: song.name,
      mediaImage: song.img,
      artist: song.author,
      duration: this.GlobalMusic.duration
    })

  }

  //设置播放状态
  setPlaybackStatus() {
    this.session?.setAVPlaybackState({
      state: this.GlobalMusic.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY :
        avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      speed: 1,
      position: { elapsedTime: this.GlobalMusic.time, updateTime: Date.now() },
      duration: this.GlobalMusic.duration,
    })

  }

  //注册控制命令
  RegisterControlCommand() {
    this.session?.on("play", () => {
      avPlayerManage.stopOrContinueSong()
    })

    this.session?.on("pause", () => {
      avPlayerManage.stopOrContinueSong()
    })

    this.session?.on("playNext", () => {
      avPlayerManage.nextSong()
    })
    this.session?.on("playPrevious", () => {
      avPlayerManage.preSong()
    })

    this.session?.on("seek", (n:number) => {
      avPlayerManage.jumpToPlay(n)
    })

    //激活session
    this.session?.activate()
  }

  //注销会话
async   DestroySession(){
  await  this.session?.destroy()
  }
}

export const SessionManager: AVSessionManager = new AVSessionManager()