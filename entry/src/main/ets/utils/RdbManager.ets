import relationalStore from '@ohos.data.relationalStore';
import { SongItemType} from '../type/SongItemType';
import common from '@ohos.app.ability.common';
import { SongListItemType } from '../type/SongListItemType';
import { ValuesBucket } from '@kit.ArkData';

class RdbManager {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableNameSong = 'song';
  private tableNamePlaylist = 'playlist';
  private tableNameMap = 'playlist_song_map';

  /**
   * 初始化数据库
   */
  initRdb(context: common.Context): Promise<void> {
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'MusicPlayer.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    return new Promise((resolve, reject) => {
      relationalStore.getRdbStore(context, STORE_CONFIG, (err, store) => {
        if (err) {
          console.error(`Get RdbStore failed. Code:${err.code}, message:${err.message}`);
          reject(err);
          return;
        }
        this.rdbStore = store;
        this.createTables();
        resolve();
      });
    });
  }

  /**
   * 创建数据表
   */
  private createTables() {
    if (!this.rdbStore) return;

    // 1. 创建歌曲表
    // hasLyric 使用 0(false) 和 1(true) 存储
    const sqlSong = `CREATE TABLE IF NOT EXISTS ${this.tableNameSong} (
      id TEXT PRIMARY KEY,
      img TEXT,
      name TEXT,
      author TEXT,
      filePath TEXT,
      lyricPath TEXT,
      hasLyric INTEGER
    )`;

    // 2. 创建歌单表
    // 歌单ID我们让它自增
    const sqlPlaylist = `CREATE TABLE IF NOT EXISTS ${this.tableNamePlaylist} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      img TEXT
    )`;

    // 3. 创建 歌单-歌曲 映射表 (多对多关系)
    const sqlMap = `CREATE TABLE IF NOT EXISTS ${this.tableNameMap} (
      playlist_id INTEGER,
      song_id TEXT,
      PRIMARY KEY (playlist_id, song_id)
    )`;

    this.rdbStore.executeSql(sqlSong);
    this.rdbStore.executeSql(sqlPlaylist);
    this.rdbStore.executeSql(sqlMap);
  }

  // ==================== 数据插入逻辑 ====================

  /**
   * 将写死的 SongListItemType[] 数据导入数据库
   * 注意：这个方法应该只在应用第一次启动或重置时调用
   */
  async importInitialData(playlists: SongListItemType[]) {
    if (!this.rdbStore) return;

    // 开启事务，保证数据完整性
    this.rdbStore.beginTransaction();

    try {
      for (const playlist of playlists) {
        // 1. 插入歌单，并获取生成的歌单ID
        const playlistValue: ValuesBucket = {
          name: playlist.name,
          img: playlist.img
        };
        const playlistId = await this.rdbStore.insert(this.tableNamePlaylist, playlistValue);

        // 2. 遍历该歌单下的所有歌曲
        for (const song of playlist.songs) {
          // 2.1 插入歌曲 (使用 replace 避免重复插入报错)
          const songValue: ValuesBucket = {
            id: song.id,
            img: song.img,
            name: song.name,
            author: song.author,
            filePath: song.filePath,
            lyricPath: song.lyricPath || '',
            hasLyric: song.hasLyric ? 1 : 0
          };
          // ConflictResolution.REPLACE: 如果ID已存在则更新，不存在则插入
          await this.rdbStore.insert(
            this.tableNameSong,
            songValue,
            relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
          );
          // 2.2 建立关联：将歌曲ID和歌单ID写入映射表
          const mapValue: relationalStore.ValuesBucket = {
            playlist_id: playlistId,
            song_id: song.id
          };

          await this.rdbStore.insert(
            this.tableNameMap,
            mapValue,
            relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
          );
        }
      }
      this.rdbStore.commit(); // 提交事务
      console.info('Data import successful');
    } catch (e) {
      console.error('Data import failed, rolling back', e);
      this.rdbStore.rollBack(); // 发生错误回滚
    }
  }

  // ==================== 数据查询逻辑 ====================

  /**
   * 获取所有歌单及其包含的歌曲
   * 用于还原成 SongListItemType[] 格式
   */
  async getAllPlaylists(): Promise<SongListItemType[]> {
    if (!this.rdbStore) return [];

    const result: SongListItemType[] = [];

    // 1. 查询所有歌单
    const predicates = new relationalStore.RdbPredicates(this.tableNamePlaylist);
    const playlistSet = await this.rdbStore.query(predicates);

    while (playlistSet.goToNextRow()) {
      const playlistId = playlistSet.getLong(playlistSet.getColumnIndex('id'));
      const name = playlistSet.getString(playlistSet.getColumnIndex('name'));
      const img = playlistSet.getString(playlistSet.getColumnIndex('img'));

      // 2. 查询当前歌单包含的所有歌曲
      // 通过子查询或连接查询获取歌曲信息
      // SQL: SELECT * FROM song WHERE id IN (SELECT song_id FROM map WHERE playlist_id = ?)
      const sqlGetSongs = `
        SELECT s.* FROM ${this.tableNameSong} s
        INNER JOIN ${this.tableNameMap} m ON s.id = m.song_id
        WHERE m.playlist_id = ?
      `;

      const songSet = await this.rdbStore.querySql(sqlGetSongs, [playlistId]);
      const songs: SongItemType[] = [];

      while (songSet.goToNextRow()) {
        try {
          songs.push({
            id: songSet.getString(songSet.getColumnIndex('id')),
            name: songSet.getString(songSet.getColumnIndex('name')),
            img: songSet.getString(songSet.getColumnIndex('img')),
            author: songSet.getString(songSet.getColumnIndex('author')),
            filePath: songSet.getString(songSet.getColumnIndex('filePath')),
            lyricPath: songSet.getString(songSet.getColumnIndex('lyricPath')),
            hasLyric: songSet.getLong(songSet.getColumnIndex('hasLyric')) === 1
          });
        } catch (error) {
          // TODO: Implement error handling.
        }
      }
      songSet.close();

      result.push({
        id: playlistId,   // ⭐ 新增：主键 id
        name: name,
        img: img,
        songs: songs,
        num: songs.length // ⭐ 顺手修正：num 应该等于歌曲数
      });

    }
    playlistSet.close();
    return result;
  }

  /**
   * 根据 ID 从数据库删除单首歌曲
   */
  async deleteSongById(songId: string): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      let predicates = new relationalStore.RdbPredicates(this.tableNameSong);
      predicates.equalTo('id', songId);

      // 同时也删除映射表中的关联记录，防止产生脏数据
      let mapPredicates = new relationalStore.RdbPredicates(this.tableNameMap);
      mapPredicates.equalTo('song_id', songId);
      await this.rdbStore.delete(mapPredicates);

      const rows = await this.rdbStore.delete(predicates);
      return rows > 0;
    } catch (e) {
      console.error('Database delete song failed', e);
      return false;
    }
  }
  /**
   * 更新歌曲的歌词信息到数据库
   */
  async updateSongLyric(songId: string, lyricPath: string, hasLyric: boolean): Promise<boolean> {
    if (!this.rdbStore) return false;

    const value: ValuesBucket = {
      'lyricPath': lyricPath,
      'hasLyric': hasLyric ? 1 : 0
    };

    let predicates = new relationalStore.RdbPredicates(this.tableNameSong);
    predicates.equalTo('id', songId);

    try {
      const rows = await this.rdbStore.update(value, predicates);
      console.info(`[RDB] 数据库更新歌词成功: ${songId}, 路径: ${lyricPath}`);
      return rows > 0;
    } catch (e) {
      console.error(`[RDB] 数据库更新歌词失败: ${JSON.stringify(e)}`);
      return false;
    }
  }





  // ==================== 歌单 (Playlist) 操作 ====================

  /**
   * 创建新歌单
   * @param name 歌单名称
   * @param img 封面图片路径
   * @returns 返回新生成的 playlistId
   */
  async createPlaylist(name: string, img: string): Promise<number> {
    if (!this.rdbStore) return -1;

    const value:ValuesBucket = {
      name: name,
      img: img
    };
    // 插入并返回自增的主键 ID
    const rowId = await this.rdbStore.insert(this.tableNamePlaylist, value);
    return rowId;
  }

  /**
   * 删除歌单
   * 注意：不仅要删除歌单本身，还要删除映射表中该歌单的所有记录
   */
  async deletePlaylist(playlistId: number): Promise<boolean> {
    if (!this.rdbStore) return false;

    // 开启事务，确保两个删除操作要么都成功，要么都失败
    this.rdbStore.beginTransaction();
    try {
      // 1. 删除映射表中的关联关系
      let predicatesMap = new relationalStore.RdbPredicates(this.tableNameMap);
      predicatesMap.equalTo('playlist_id', playlistId);
      await this.rdbStore.delete(predicatesMap);

      // 2. 删除歌单本体
      let predicatesList = new relationalStore.RdbPredicates(this.tableNamePlaylist);
      predicatesList.equalTo('id', playlistId);
      const rows = await this.rdbStore.delete(predicatesList);

      this.rdbStore.commit();
      return rows > 0;
    } catch (e) {
      console.error('Delete playlist failed', e);
      this.rdbStore.rollBack();
      return false;
    }
  }

  /**
   * 向指定歌单中添加一首歌曲
   * @param playlistId 歌单 ID
   * @param songId 歌曲 ID
   */
  async addSongToPlaylist(playlistId: number, songId: string): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      const mapValue: relationalStore.ValuesBucket = {
        playlist_id: playlistId,
        song_id: songId
      };

      const rowId = await this.rdbStore.insert(
        this.tableNameMap,
        mapValue,
        relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
      );

      return rowId !== -1;
    } catch (e) {
      console.error('Add song to playlist failed', e);
      return false;
    }
  }

  /**
   * 根据歌单 ID 获取单个歌单的完整信息
   * @param playlistId 歌单 ID
   * @returns 对应的 SongListItemType （无匹配则返回 null）
   */
  async getPlaylistById(playlistId: number): Promise<SongListItemType | null> {
    if (!this.rdbStore) return null;

    try {
      // 1. 查询指定 ID 的歌单基础信息
      const predicates = new relationalStore.RdbPredicates(this.tableNamePlaylist);
      predicates.equalTo('id', playlistId); // 精准匹配歌单 ID
      const playlistSet = await this.rdbStore.query(predicates);

      // 检查是否存在该歌单
      if (!playlistSet.goToNextRow()) {
        playlistSet.close();
        console.warn(`Playlist with id ${playlistId} not found`);
        return null;
      }

      // 提取歌单基础信息
      const name = playlistSet.getString(playlistSet.getColumnIndex('name'));
      const img = playlistSet.getString(playlistSet.getColumnIndex('img'));
      playlistSet.close();

      // 2. 查询该歌单下的所有歌曲（复用现有方法，减少冗余）
      const songs = await this.getSongsByPlaylistId(playlistId);

      // 3. 构造并返回 SongListItemType 格式数据
      const playlistInfo: SongListItemType = {
        id: playlistId,
        name: name,
        img: img,
        num: songs.length, // 歌曲数量与 songs 数组长度保持一致
        songs: songs
      };

      return playlistInfo;
    } catch (e) {
      console.error(`Get playlist by id ${playlistId} failed`, e);
      return null;
    }
  }


  /**
   * 根据歌单 ID 获取该歌单下的所有歌曲
   * @param playlistId 歌单 ID
   */
  async getSongsByPlaylistId(playlistId: number): Promise<SongItemType[]> {
    if (!this.rdbStore) return [];

    const songs: SongItemType[] = [];

    const sql = `
    SELECT s.* FROM ${this.tableNameSong} s
    INNER JOIN ${this.tableNameMap} m
      ON s.id = m.song_id
    WHERE m.playlist_id = ?
  `;

    try {
      const resultSet = await this.rdbStore.querySql(sql, [playlistId]);

      while (resultSet.goToNextRow()) {
        songs.push({
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')),
          img: resultSet.getString(resultSet.getColumnIndex('img')),
          author: resultSet.getString(resultSet.getColumnIndex('author')),
          filePath: resultSet.getString(resultSet.getColumnIndex('filePath')),
          lyricPath: resultSet.getString(resultSet.getColumnIndex('lyricPath')),
          hasLyric: resultSet.getLong(resultSet.getColumnIndex('hasLyric')) === 1
        });
      }

      resultSet.close();
      return songs;
    } catch (e) {
      console.error('Get songs by playlistId failed', e);
      return [];
    }
  }


  /**
   * 从指定歌单中移除一首歌曲
   * @param playlistId 歌单 ID
   * @param songId 歌曲 ID
   */
  async removeSongFromPlaylist(playlistId: number, songId: string): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      const predicates = new relationalStore.RdbPredicates(this.tableNameMap);
      predicates.equalTo('playlist_id', playlistId)
        .and()
        .equalTo('song_id', songId);

      const rows = await this.rdbStore.delete(predicates);
      return rows > 0;
    } catch (e) {
      console.error('Remove song from playlist failed', e);
      return false;
    }
  }


  /**
   * 修改歌单信息（例如重命名）
   */
  async updatePlaylist(playlistId: number, newName: string, newImg?: string): Promise<boolean> {
    if (!this.rdbStore) return false;

    const value: relationalStore.ValuesBucket = { name: newName };
    if (newImg) {
      value.img = newImg;
    }

    let predicates = new relationalStore.RdbPredicates(this.tableNamePlaylist);
    predicates.equalTo('id', playlistId);

    const rows = await this.rdbStore.update(value, predicates);
    return rows > 0;
  }
  // ==================== 歌曲 (Song) 独立查询与管理 ====================

  /**
   * 插入一首新歌到数据库（不绑定歌单）
   * 场景：扫描本地文件后，将歌曲存入“所有歌曲”库
   */
  async insertSong(song: SongItemType): Promise<boolean> {
    if (!this.rdbStore) return false;

    const songValue: relationalStore.ValuesBucket = {
      id: song.id,
      img: song.img,
      name: song.name,
      author: song.author,
      filePath: song.filePath,
      lyricPath: song.lyricPath ?? '',
      hasLyric: song.hasLyric ? 1 : 0
    };

    // 使用 REPLACE 策略，如果歌曲已存在（ID相同）则更新信息，否则插入
    const rowId = await this.rdbStore.insert(this.tableNameSong, songValue, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    return rowId !== -1;
  }

  /**
   * 获取本地库中的“所有歌曲”
   * 场景：展示“我的音乐 -> 本地歌曲”列表
   */
  async getAllSongs(): Promise<SongItemType[]> {
    if (!this.rdbStore) return [];

    let predicates = new relationalStore.RdbPredicates(this.tableNameSong);
    // 按添加时间或名称排序，这里默认按名称
    predicates.orderByAsc('name');

    const resultSet = await this.rdbStore.query(predicates);
    return this.parseSongResultSet(resultSet);
  }

  /**
   * 根据 ID 查询单首歌曲详情
   */
  async getSongById(songId: string): Promise<SongItemType | null> {
    if (!this.rdbStore) return null;

    let predicates = new relationalStore.RdbPredicates(this.tableNameSong);
    predicates.equalTo('id', songId);

    const resultSet = await this.rdbStore.query(predicates);
    const songs = this.parseSongResultSet(resultSet);

    return songs.length > 0 ? songs[0] : null;
  }

  /**
   * 模糊搜索歌曲
   * 场景：搜索栏输入关键词，查找歌名或歌手
   */
  async searchSongs(keyword: string): Promise<SongItemType[]> {
    if (!this.rdbStore) return [];

    let predicates = new relationalStore.RdbPredicates(this.tableNameSong);
    // 歌名 包含 keyword 或者 歌手 包含 keyword
    predicates.contains('name', keyword)
      .or()
      .contains('author', keyword);

    const resultSet = await this.rdbStore.query(predicates);
    return this.parseSongResultSet(resultSet);
  }

  // --- 辅助方法：将数据库结果集转为对象数组 ---
  private parseSongResultSet(resultSet: relationalStore.ResultSet): SongItemType[] {
    const songs: SongItemType[] = [];
    while (resultSet.goToNextRow()) {
      songs.push({
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        img: resultSet.getString(resultSet.getColumnIndex('img')),
        author: resultSet.getString(resultSet.getColumnIndex('author')),
        filePath: resultSet.getString(resultSet.getColumnIndex('filePath')),
        lyricPath: resultSet.getString(resultSet.getColumnIndex('lyricPath')),
        hasLyric: resultSet.getLong(resultSet.getColumnIndex('hasLyric')) === 1
      });
    }
    resultSet.close();
    return songs;
  }

}

export default new RdbManager();
