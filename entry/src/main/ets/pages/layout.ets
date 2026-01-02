import TabClass from '../type/tabs';
import find from './body/find';
import mine from './body/mine';
import moment from './body/moment';
import recommend from './body/recommend';
import playBar from './playBar';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../type/GlobalMusic';

@Builder
export function layoutBuilder() {
  layout();
}

@Entry
@ComponentV2
struct layout {
  @Local  pathStack: NavPathStack = new NavPathStack();

  @Local currentIndex: number = 0;
  tabData: TabClass[] = [
    { text: '推荐', icon: $r('app.media.ic_recommend') },
    { text: '发现', icon: $r('app.media.ic_find') },
    { text: '动态', icon: $r('app.media.ic_moment') },
    { text: '我的', icon: $r('app.media.ic_mine') }
  ]
  @Local
  GlobalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!


  @Builder
  tabBuilder(item: TabClass, targetIndex: number) {
    Column({ space: 3 }) {
      Image(item.icon)
        .size({ width: 25, height: 25 })
        .fillColor(this.currentIndex === targetIndex ? '#ff992d2d' : '#ff25857f')
      Text(item.text)
        .fontColor(this.currentIndex === targetIndex ? '#ff992d2d' : '#ff25857f')
    }
    .width('100%')
    .height(50)
    .margin({ top: 10 })
    .justifyContent(FlexAlign.Center)
  }

  build() {

    NavDestination() {
      Stack(){
         Tabs({ barPosition: BarPosition.End }) {
        ForEach(this.tabData, ((item: TabClass, index: number) => {
          TabContent() {
            if (index == 0) {
              recommend()
            }
            else if (index == 1) {
              find()
            }
            else if (index == 2) {
              moment()
            } else if (index == 3) {
              mine()
            }

          }.tabBar(this.tabBuilder(item, index))

        }))

      }
      .barBackgroundColor("#3A3E41")
      .backgroundColor("#131312")
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      .onChange((Index: number) => {
        this.currentIndex = Index
      })


        Flex({justifyContent:FlexAlign.Center}){
          playBar() .width("95%")
        }.visibility(this.GlobalMusic.isShowPlayBar?Visibility.Visible:Visibility.None)
         .position({bottom:66})
        }


    }.hideTitleBar(true)


    .height('100%')
    .width('100%')
  }
}


