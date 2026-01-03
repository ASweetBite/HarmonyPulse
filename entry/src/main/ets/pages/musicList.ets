import { AppStorageV2 } from '@kit.ArkUI'
import { GlobalMusic } from '../type/GlobalMusic'
import { SongItemType } from '../type/SongItemType'
import { avPlayerManage } from '../utils/avPlayerMusic'

@ComponentV2
struct musicList{
  @Event
  panelHeight:string
  @Event
  panelOpacity:boolean
  // 当前播放的歌曲
  @Local
   playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!
  @Local
  songs: SongItemType[] = this.playState.songList

  @Builder
  deleteButton(index: number) {
    Button('删除')
      .backgroundColor('#ec5c87')
      .fontColor('#fff')
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)

  }

  build() {
    // 列表
    Column() {
      Column() {

      }
      .width('100%')
      .layoutWeight(1)
      .onClick(() => {
        this.panelHeight = '0%'
        this.panelOpacity = false
      })

      Column() {
        Row() {
          Row() {
            Image($r("app.media.ic_play"))
              .width(20)
              .fillColor('#ff5186')
          }
          .width(50)
          .aspectRatio(1)
          .justifyContent(FlexAlign.Center)

          Row({ space: 8 }) {
            Text(`播放列表 ${this.songs.length}`)
              .fontColor(Color.White)
              .fontSize(14)
          }
          .layoutWeight(1)

          Image($r('app.media.ic_close'))
            .fillColor('#ffa49a9a')
            .width(24)
            .height(24)
            .margin({ right: 16 })
            .onClick(() => {

              this.panelHeight = '0%'
              this.panelOpacity = false
            })
        }
        .width('100%')
        .backgroundColor('#ff353333')
        .padding(8)
        .border({
          width: { bottom: 1 },
          color: '#12ec5c87'
        })
        .borderRadius({
          topLeft: 4,
          topRight: 4
        })

        // 播放列表
        List() {
          ForEach(this.songs, (item: SongItemType, index: number) => {
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
        .layoutWeight(1)
        .backgroundColor('#ff353333')

      }
      .height(400)
    }
    .height(this.panelHeight)
    .visibility(this.panelOpacity?Visibility.Visible:Visibility.Hidden)
    // .height('50%')
    .animation({
      duration: 300
    })
    .backgroundColor('#ff353333')
    .opacity(1)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

  }

}
export default musicList