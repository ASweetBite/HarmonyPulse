import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@Component
struct Index {
 // pageStack: NavPathStack = new NavPathStack()
  pageStack: NavPathStack = AppStorageV2.connect(NavPathStack,"navStack",()=> new NavPathStack())!
  build() {
    Navigation(this.pageStack) {
    }.onAppear(() => {
      this.pageStack.pushPathByName("startAdv", null, false);
    })
    .hideNavBar(true)
  }
}