
@ObservedV2
export class AppSignal {
  @Trace shareImportCount: number = 0; // 只要这个数字变了，就代表有新导入
}