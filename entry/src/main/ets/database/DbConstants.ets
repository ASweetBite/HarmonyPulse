import { relationalStore } from '@kit.ArkData';

interface GeneratedObjectLiteralInterface_1 {
  id: string;
  name: string;
  author: string;
  img: string;
  filePath: string;
  lyricPath: string;
  hasLyric: string;
}

interface GeneratedObjectLiteralInterface_2 {
  tableName: string;
  columns: GeneratedObjectLiteralInterface_1;
}

export class DbConstants {
  // 数据库基本配置
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'MusicApp.db', // 数据库文件名
    securityLevel: relationalStore.SecurityLevel.S1
  };

  // 歌曲表信息
  static readonly SONG_TABLE: GeneratedObjectLiteralInterface_2 = {
    tableName: 'song_list',
    columns: ({
      id: 'id',
      name: 'name',
      author: 'author',
      img: 'img',
      filePath: 'filePath',
      lyricPath: 'lyricPath',
      hasLyric: 'hasLyric'
    } as GeneratedObjectLiteralInterface_1)
  };

  // 建表语句
  static readonly CREATE_SONG_TABLE_SQL = `
    CREATE TABLE IF NOT EXISTS ${DbConstants.SONG_TABLE.tableName} (
      ${DbConstants.SONG_TABLE.columns.id} TEXT PRIMARY KEY,
      ${DbConstants.SONG_TABLE.columns.name} TEXT,
      ${DbConstants.SONG_TABLE.columns.author} TEXT,
      ${DbConstants.SONG_TABLE.columns.img} TEXT,
      ${DbConstants.SONG_TABLE.columns.filePath} TEXT,
      ${DbConstants.SONG_TABLE.columns.lyricPath} TEXT,
      ${DbConstants.SONG_TABLE.columns.hasLyric} INTEGER
    )`;
}