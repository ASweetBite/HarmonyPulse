
import { dailyRecommend, recommendList } from "../../type/data"
import recommendDailyType from "../../type/recommendDailyType"
import recommendListType from "../../type/recommendListType"


@Preview
@Component
struct recommend {
  // 轮播图数据
  swiperList: string[] = [
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner1.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner2.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner3.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner4.png",
    "http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner5.png"
  ]
  @State dailyRecommend: recommendDailyType[] = []
  @State recommendList: recommendListType[] = []

  aboutToAppear(): void {
    this.dailyRecommend = dailyRecommend
    this.recommendList = recommendList
  }

  @Builder
  naviRow(title: string) {
    Flex({ justifyContent: FlexAlign.SpaceBetween }) {
      Text(title).fontColor("#fff6f5f5").fontSize(18).fontWeight(FontWeight.Bold)
      Image($r("app.media.ic_more")).height(20).fillColor("#ffd6d6d6")
    }.margin(10)
  }

  build() {
    Column() {

      Flex({ justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
        Image($r("app.media.ic_search")).height(20).fillColor("#ffa5a5a5")
        TextInput({ placeholder: "基尼太美🧨" }).fontColor("##fff").placeholderColor("#FF696969")
        Image($r("app.media.ic_code")).height(20).fillColor("#ffa5a5a5")
      }
      .backgroundColor("#ff2b2b2b")
      .margin({ left: 10, right: 10, bottom: 10 })
      .padding({ left: 10, right: 10 })
      .borderRadius("50%")

      Swiper() {
        ForEach(this.swiperList, ((item: string) => {
          Image(item).width("100%").height("25%").borderRadius("3%")
        }))
      }.margin(10).autoPlay(true)

      this.naviRow("每日推荐")

      List() {
        ForEach(dailyRecommend, ((item: recommendDailyType) => {
          ListItem() {
            Column() {
              Text(item.type)
                .height("15%")
                .width("100%")
                .backgroundColor(item.top)
                .fontColor(Color.White)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .padding({ left: 5 })
                .borderRadius({ topLeft: 5, topRight: 5 })

              Image(item.img).height("65%").width("100%")

              Text(item.title)
                .height("20%")
                .width("100%")
                .backgroundColor(item.bottom)
                .fontColor(Color.White)
                .fontSize(13)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .ellipsisMode(EllipsisMode.END)
                .padding({ left: 5 })
                .borderRadius({ bottomLeft: 5, bottomRight: 5 })

            }.width("40%").height("100%")

          }.margin({ left: 10 })
        }))
      }.scrollBar(BarState.Off)
      .width("100%")
      .height("30%")
      .listDirection(Axis.Horizontal)

      this.naviRow("推荐歌单")

      List() {
        ForEach(this.recommendList, ((item: recommendListType) => {
          ListItem() {
            Column() {
              Stack() {
                Image(item.img).width(100).height(100).borderRadius(10)
                Text(item.count).fontColor(Color.White).fontSize(12).fontWeight(FontWeight.Bold)
                  .padding(10).position({top:0})
              }.width("30%")

              Text(item.title)
                .fontColor("#ffc8c8c8")
                                .fontSize(12)
                .padding({ left: 5 })
                .width("30%")
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .ellipsisMode(EllipsisMode.END)
                .margin({top:5})
            }
          }
        }))
      }
      .listDirection(Axis.Horizontal)
      .width("100%")
      .height("30%")

    }


    .width("100%")
    .height("100%")
  }
}

export default recommend