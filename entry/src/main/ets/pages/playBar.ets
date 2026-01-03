import { GlobalMusic } from '../type/GlobalMusic'
import { AppStorageV2 } from '@kit.ArkUI'
import { avPlayerManage } from '../utils/avPlayerMusic'
import { SongItemType } from '../type/SongItemType'

@Preview
@ComponentV2
struct playBar {
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!
  @Local
  pageStack: NavPathStack = AppStorageV2.connect(NavPathStack, "navStack", () => new NavPathStack())!
  @Local isShow:boolean=false
  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Row() {

        Row() {
          Image(this.playState.img)
            .width(30)
            .borderRadius(40)
        }
        .backgroundImage($r('app.media.ic_cd'))
        .backgroundImageSize(ImageSize.Cover)
        .justifyContent(FlexAlign.Center)
        .height(40)
        .borderRadius(40)
        .clip(true)
        .aspectRatio(1)
        .layoutWeight(1)


        Text(this.playState.name + "-")
          .fontColor("#ffdedede")
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)

          .margin({ left: 5 })

        Text(this.playState.author)
          .fontColor("#ffdedede")
          .textAlign(TextAlign.Start)
          .width("30%")
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
      }.onClick(() => {
        this.pageStack.pushPathByName("play", null)

      })

      Row() {
        Image(this.playState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
          .width(20).margin({ right: 10 })
          .onClick(() => {
            avPlayerManage.stopOrContinueSong()
          })
        Image($r('app.media.ic_song_list')).width(20).margin({ right: 10 })
          .onClick(() => {
            this.isShow = true;
          })
          .bindSheet($$this.isShow,this.playlist(),{
            showClose: false,
            height:"70%",
            dragBar:true,
            enableFloatingDragBar:true,
            backgroundColor:"#ff2b2b2b",
          title: this.playlistTitle(),
             onDisappear:()=>{this.isShow = false;},
          })

      }.margin({ right: 10 })

    }
    .borderRadius(40)
    .backgroundColor("#ff222222")
    .width("85s%")
    .height(40)
  }
  @Builder
  playlistTitle(){
    Flex({justifyContent:FlexAlign.SpaceAround,alignItems: ItemAlign.Center}){
      Text("当前播放").fontColor(Color.White).fontSize(20)
      // 切换
      Row() {
        if (this.playState.playbackStatus === "顺序播放") {
          Image($r('app.media.ic_auto'))
            .fillColor(Color.White)
            .width(25)
            .onClick(() => {
              this.playState.playbackStatus = "单曲循环"
            })
        } else if (this.playState.playbackStatus === "单曲循环") {
          Image($r('app.media.ic_repeat'))
            .fillColor(Color.White)
            .width(25)
            .onClick(() => {
              this.playState.playbackStatus = "随机播放"
            })

        } else if (this.playState.playbackStatus === "随机播放") {
          Image($r('app.media.ic_random'))
            .fillColor(Color.White)
            .width(25)
            .onClick(() => {
              this.playState.playbackStatus = "顺序播放"
            })

        }
    }
  }.backgroundColor("#ff2b2b2b").width("100%").height("100%").border({width:{bottom:1},color:"#ff4e4e4e"})
  }
  @Builder
  playlist() {
  List(){
    ForEach(this.playState.songList,(item:SongItemType,index:number)=>{
      ListItem() {
        Row() {
          Row() {
            Text((index + 1).toString())
              .fontColor(( this.playState.currentID===item.id?"#E23241":'#ffa49a9a'))
          }
          .width(50)
          .aspectRatio(1)
          .justifyContent(FlexAlign.Center)

          // 列表
          Row({ space: 10 }) {
            Column() {
              Text(item.name)
                .fontSize(14)
                .fontColor( this.playState.currentID===item.id?"#E23241":'#ffa49a9a')
              Text(item.author)
                .fontSize(12)
                .fontColor(this.playState.currentID===item.id?"#E23241":Color.Gray)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
          }
          .onClick(()=>{
            avPlayerManage.playResources(item)
          })
          .layoutWeight(1)

          Image($r('app.media.ic_more'))
            .width(24)
            .height(24)
            .margin({ right: 16 })
            .fillColor(Color.Gray)
        }
        .alignItems(VerticalAlign.Center)
      }
      .swipeAction({
        end: this.deleteButton(index)
      })
      .border({
        width: { bottom: 1 },
        color: '#12ec5c87'
      })
    })

  }
  .width("100%")
  .height("100%").backgroundColor("#ff2b2b2b")
  }
  @Builder
  deleteButton(index: number) {
    Button('删除')
      .backgroundColor('#ec5c87')
      .fontColor('#fff')
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(()=>{
        avPlayerManage.deleteSong(index)
      })
  }
}

export default playBar