import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class RdbHelper {
  private static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'MusicDatabase.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  private static readonly SQL_CREATE_TABLE = `
    CREATE TABLE IF NOT EXISTS song_list (
      id TEXT PRIMARY KEY,
      name TEXT,
      author TEXT,
      img TEXT,
      filePath TEXT,
      lyricPath TEXT,
      hasLyric INTEGER
    )`;

  private static rdbStore: relationalStore.RdbStore | null = null;

  static async getStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
    if (RdbHelper.rdbStore !== null) {
      return RdbHelper.rdbStore;
    }

    try {
      const store = await relationalStore.getRdbStore(context, RdbHelper.STORE_CONFIG);
      await store.executeSql(RdbHelper.SQL_CREATE_TABLE);
      RdbHelper.rdbStore = store;
      return store;
    } catch (err) {
      // 1. 先强转以获取错误详情用于日志
      const error = err as BusinessError;
      console.error(`Get RdbStore failed, code: ${error.code}, message: ${error.message}`);

      // 2. 抛出一个标准的 Error 对象，ArkTS 允许这种写法
      // 你可以将 code 和 message 拼接在一起，方便上层查看
      throw new Error(`BusinessError ${error.code}: ${error.message}`);
    }
  }
}