// @Builder
// export function PageTwoBuilder() {
//   startAdv();
// }
// @Preview
// @Component
// //广告也
// struct  startAdv{
//   @State Countdown:number=5
//   @Prop timer:number
//   pathStack: NavPathStack = new NavPathStack();
//   build() {
//     NavDestination(){
//       Stack(){
//         Image($r("app.media.ad"))
//           .width("100%")
//           .height("100%")
//           .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
//
//         Text(`跳过 ${this.Countdown}`).position({top:0,right:0}).margin(20).padding(5)
//           .backgroundColor("#ff858585").fontColor("#ffe0e0e0")
//           .width(60) .textAlign(TextAlign.Center)
//           .borderRadius("30%")
//           .onClick(()=>{
//             clearInterval(this.timer)
//             this.pathStack.replacePathByName("layout",null)
//           })
//           .onAppear(()=>{
//              this.timer=setInterval(()=>{
//               if (this.Countdown<=0) {
//                 clearInterval(this.timer)
//                 this.pathStack.replacePathByName("layout",null)
//               }else {
//                 this.Countdown--
//               }
//               },1000)
//           })
//       }
//     }
//
//     .backgroundColor(Color.Black)
//     .onReady((context: NavDestinationContext) => {
//       this.pathStack = context.pathStack;
//     })
//   }
// }
//
