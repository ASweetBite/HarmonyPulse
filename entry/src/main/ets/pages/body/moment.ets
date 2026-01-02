import { GlobalMusic } from "../../type/GlobalMusic";
import { AppStorageV2 } from "@kit.ArkUI";
import { momentList, songsList } from "../../type/data";
import { momentListType } from "../../type/momentListType";
import { SongItemType } from "../../type/SongItemType";
import { avPlayerManage } from "../../ulits/avPlayerMusic";


@Preview
@ComponentV2
struct moment {
  // 歌曲数据
  @Local
  songs: SongItemType[] = songsList
  @Local
  momentList:momentListType[]=momentList
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!
  // 当前播放的歌曲


  build() {
    Scroll() {
      Column() {
        // 标题
        Text('互动广场')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ top: 20, bottom: 20, left: 20 })
          .alignSelf(ItemAlign.Start)

        // 动态列表
        List() {
          ForEach(this.momentList, (item: momentListType) => {
            ListItem() {
              Column() {
                // 用户信息和内容区域
                Row() {
                  // 用户头像
                  Image(item.avatar)
                    .width(48)
                    .height(48)
                    .borderRadius(24)
                    .margin({ right: 12 })
                    .objectFit(ImageFit.Cover)

                  // 用户信息和内容
                  Column() {
                    // 用户名
                    Text(item.author)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.White)
                      .alignSelf(ItemAlign.Start)
                      .margin({ bottom: 8 })

                    // 内容
                    Text(item.content)
                      .width("80%")
                      .maxLines(1)
                      .ellipsisMode(EllipsisMode.END)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .fontSize(16)
                      .fontColor(Color.White)
                      .alignSelf(ItemAlign.Start)
                      .margin({ bottom: 12 })
                      .lineHeight(24)

                    // 歌曲信息卡片
                    Row() {
                      Image(item.song.img)
                        .width(48)
                        .height(48)
                        .borderRadius(4)
                        .objectFit(ImageFit.Cover)

                      Column() {
                        Text(item.song.name)
                          .fontSize(14)
                          .fontColor(Color.White)
                          .fontWeight(FontWeight.Medium)
                          .alignSelf(ItemAlign.Start)
                          .lineHeight(20)

                        Text(item.song.author)
                          .fontSize(12)
                          .fontColor(Color.Gray)
                          .alignSelf(ItemAlign.Start)
                          .lineHeight(18)
                      }




                      // 播放按钮文本
                      Image(item.song.id===this.playState.currentID&&
                      this.playState.isPlay?$r('app.media.ic_paused'):$r('app.media.ic_play'))
                        .width(20) .margin({ left: 'auto' })
                        .onClick(()=>{
                          if (item.song.id===this.playState.currentID) {
                            avPlayerManage.stopOrContinueSong()
                          }else {
                            avPlayerManage.playResources(item.song)
                          }

                        })
                    } .width("65%")
                    .justifyContent(FlexAlign.SpaceBetween)


                    .backgroundColor('#2A2A2A')
                    .borderRadius(8)
                    .padding(8)
                    .margin({ bottom: 12 })
                  }

                  .alignItems(HorizontalAlign.Start)
                }
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Top)

                // 操作按钮区域
                Row() {
                  // 分享按钮
                  Row() {
                    Text('↗ 分享')
                      .fontSize(14)
                      .fontColor(Color.White)
                  }
                  .margin({ right: 24 })

                  // 评论按钮
                  Row() {
                    Text('💬 ' + item.comment.toString())
                      .fontSize(14)
                      .fontColor(Color.White)
                  }
                  .margin({ right: 24 })

                  // 点赞按钮
                  Row() {
                    Text('❤️ ' + item.like.toString())
                      .fontSize(14)
                      .fontColor(Color.White)
                  }
                }
                .margin({left:10})
                .alignSelf(ItemAlign.Start)
              }

              .width("100%")

            }.margin({ bottom: 5, top: 5 })
          }, (item: momentListType) => item.author)
        }
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .nestedScroll({
          scrollForward: NestedScrollMode.PARENT_FIRST, //向前 不是可滚动组件优先
          scrollBackward: NestedScrollMode.SELF_FIRST // 向后 自身优先
        })
        .divider({ strokeWidth: 1, color: "#ff343434" })
        .width('100%')
        .height('100%')
        .padding({ top: 10, left: 10, right: 10 })
        .scrollBar(BarState.Off)
      }

    }.scrollBar(BarState.Off)
    .width('100%')
    .height('100%')

    .expandSafeArea()
  }
}

export default moment