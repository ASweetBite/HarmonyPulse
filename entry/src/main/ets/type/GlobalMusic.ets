import { SongItemType } from "./SongItemType"

@ObservedV2
export class GlobalMusic {
  @Trace img: string = ""  // 音乐封面
  @Trace name: string = ""  // 音乐名称
  @Trace author: string = ""  // 作者
  @Trace currentID: string = ""  // 当前播放链接
  @Trace time: number = 0  // 播放时间
  @Trace duration: number = 0  // 音乐的播放时长
  @Trace isPlay:boolean=true
  @Trace playbackStatus :"单曲循环"|"随机播放"|"顺序播放"="顺序播放"
  //当前播放音乐
  @Trace currentMusic:number = 0
  @Trace isShowPlayBar:boolean=false
  @Trace playList:SongItemType[]=[] //音乐列表
}