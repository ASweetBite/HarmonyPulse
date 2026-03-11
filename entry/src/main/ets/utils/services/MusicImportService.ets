import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { media } from '@kit.MediaKit'
import { image } from '@kit.ImageKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
// 导入首选项模块
import { preferences } from '@kit.ArkData'
import { SongItemType } from '../../type/SongItemType'
import { GlobalMusic } from '../../type/GlobalMusic'
import RdbManager from '../managers/RdbManager'
import { lyricManager, LyricManager } from '../managers/LyricManager'

const PREF_NAME = 'music_storage'
const KEY_SONG_LIST = 'song_list'

export class MusicImportService {

  /**
   * 对外唯一入口：从系统文件选择器导入音乐
   */
  static async importFromPicker(
    context: common.UIAbilityContext,
    globalMusic: GlobalMusic
  ): Promise<void> {
    try {
      const audioPicker = new picker.AudioViewPicker()
      // 允许选择多个音频文件
      const uris = await audioPicker.select(new picker.AudioSelectOptions())

      if (!uris || uris.length === 0) return

      console.info(`开始批量导入, 共选择 ${uris.length} 个文件`)

      // 1. 优化去重：先提取现有歌曲的唯一键 (歌名+歌手) 存入 Set
      const existingKeys = new Set<string>()
      globalMusic.songList.forEach(s => {
        existingKeys.add(`${s.name}-${s.author}`)
      })

      let successCount = 0
      let skipCount = 0

      // 2. 循环处理每一个选中的 URI
      for (const uri of uris) {
        try {
          // 传入 existingKeys 进行快速查重
          const song = await MusicImportService.importSingleFile(uri, context, existingKeys)

          if (song) {
            // 更新内存列表
            globalMusic.addSong(song)
            // 写入 RDB 数据库
            await RdbManager.insertSong(song)
            // 将新歌也加入查重 Set，防止本次导入中出现重复文件
            existingKeys.add(`${song.name}-${song.author}`)
            successCount++
          } else {
            skipCount++
          }
        } catch (itemError) {
          // 单个文件导入失败不影响后续文件
          console.error(`文件导入异常 [${uri}]:`, JSON.stringify(itemError))
        }
      }

      // 3. 批量处理完后，进行一次性的持久化备份（Preferences）
      await MusicImportService.saveSongs(context, globalMusic.songList)

      console.info(`导入任务完成: 成功 ${successCount} 首, 跳过 ${skipCount} 首`)

    } catch (err) {
      const error = err as BusinessError
      console.error(`AudioPicker 呼起失败: ${error.code}, ${error.message}`)
    }
  }


  /**
   * 函数一：持久化保存歌曲列表
   * 将 SongItemType 数组序列化为 JSON 字符串存入首选项
   */
  static async saveSongs(context: common.Context, songs: SongItemType[]): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME)
      await pref.put(KEY_SONG_LIST, JSON.stringify(songs))
      await pref.flush()
    } catch (e) {
      console.error('Preferences 保存失败', e)
    }
  }

  /**
   * 修正版：从数据库加载歌曲列表
   */
  static async loadSongs(context: common.Context, globalMusic: GlobalMusic): Promise<void> {
    try {
      // 1. 确保数据库已初始化
      await RdbManager.initRdb(context);

      // 2. 从数据库获取最新数据
      const allSongs = await RdbManager.getAllSongs();

      // 3. 直接赋值给全局状态（配合 @Trace 触发 UI 刷新）
      // 不要用 forEach add，直接替换数组效率更高且能保证同步
      globalMusic.songList = allSongs;

      console.info(`MusicImportService: 已加载 ${allSongs.length} 首歌曲`);
    } catch (e) {
      console.error('加载歌曲列表失败', JSON.stringify(e));
    }
  }

  /**
   * 导入单个音频文件
   */
  public static async importSingleFile(
    uri: string,
    context: common.Context,
    existingKeys?: Set<string>
  ): Promise<SongItemType | null> {

    const decodeUri = decodeURIComponent(uri)
    const fullName = decodeUri.substring(decodeUri.lastIndexOf('/') + 1)
    const dotIndex = fullName.lastIndexOf('.')
    const ext = dotIndex !== -1 ? fullName.substring(dotIndex) : '.mp3'
    const baseName = dotIndex !== -1 ? fullName.substring(0, dotIndex) : fullName

    let title: string = baseName
    let artist: string = '未知艺术家'
    let extractor: media.AVMetadataExtractor | undefined
    let srcFile: fs.File | undefined

    try {
      // --- 阶段 1: 预解析元数据进行查重 ---
      srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      extractor = await media.createAVMetadataExtractor()
      extractor.fdSrc = { fd: srcFile.fd }
      const metadata = await extractor.fetchMetadata()

      if (metadata.title?.trim()) title = metadata.title
      if (metadata.artist?.trim()) artist = metadata.artist

      // 快速查重逻辑
      if (existingKeys && existingKeys.has(`${title}-${artist}`)) {
        console.info(`[去重] 跳过重复歌曲: ${title} - ${artist}`)
        return null
      }

      // --- 阶段 2: 物理拷贝文件 ---
      const newFileName = `${Date.now()}_${Math.floor(Math.random() * 1000)}${ext}`
      const destPath = `${context.filesDir}/${newFileName}`
      const destFile = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)

      // 使用 copyFileSync 进行 FD 拷贝
      fs.copyFileSync(srcFile.fd, destFile.fd)
      fs.closeSync(destFile)

      // --- 阶段 3: 提取并保存封面 ---
      let coverUri = ''
      try {
        const pixelMap = await extractor.fetchAlbumCover()
        if (pixelMap) {
          coverUri = await MusicImportService.saveCover(pixelMap, context)
        }
      } catch (coverErr) {
        console.warn(`封面提取失败: ${title}`)
      }

      const tempId = `user_${Date.now()}_${Math.random().toString(36).slice(2, 5)}`

      return {
        id: tempId,
        name: title,
        author: artist,
        img: coverUri,
        filePath: newFileName,
        lyricPath: lyricManager.getOrCreateLyricPath(tempId),
        hasLyric: false
      }

    } finally {
      // 无论成功失败，必须释放资源
      if (extractor) await extractor.release()
      if (srcFile) fs.closeSync(srcFile)
    }
  }

  private static async saveCover(
    pixelMap: image.PixelMap,
    context: common.Context
  ): Promise<string> {
    const fileName = `cover_${Date.now()}_${Math.floor(Math.random() * 100)}.jpg`
    const coverPath = `${context.filesDir}/${fileName}`
    const file = fs.openSync(coverPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    const packer = image.createImagePacker()
    await packer.packToFile(pixelMap, file.fd, { format: 'image/jpeg', quality: 80 })
    fs.closeSync(file)
    return `file://${coverPath}`
  }

  /**
   * 删除与歌曲关联的歌词文件。
   * 此方法只负责文件系统的删除操作。
   * @param lyricPath 歌词文件的完整路径（需要转换为本地文件系统路径，如果它是一个URI）。
   */
  private static async _deleteLyricFileInternal(lyricPath: string): Promise<void> {
    // 假设 lyricPath 已经是完整的本地文件路径或 fs 可以直接处理的路径
    // 由于歌词管理器通常返回的可能是 {context.filesDir}/{id}.lrc 这样的路径，我们直接使用。
    // 如果 lyricManager.getOrCreateLyricPath 返回的是 file:// URI，需要做兼容处理
    let pathToDelete = lyricPath;
    if (pathToDelete.startsWith('file://')) {
      pathToDelete = pathToDelete.substring('file://'.length);
    }

    try {
      if (fs.accessSync(pathToDelete)) {
        fs.unlinkSync(pathToDelete);
        console.info(`文件系统: 已删除歌词文件: ${pathToDelete}`);
      } else {
        console.warn(`文件系统: 歌词文件不存在，跳过删除: ${pathToDelete}`);
      }
    } catch (e) {
      console.error(`文件系统: 删除歌词文件失败 (${pathToDelete}): ${JSON.stringify(e)}`);
    }
  }

  /**
   * 删除指定的歌曲，包括清理文件、数据库和本地缓存。
   * @param context UIAbilityContext，用于文件操作和首选项。
   * @param globalMusic 全局音乐数据管理实例。
   * @param songToDelete 要删除的歌曲对象。
   */
  public static async deleteSongs(
    context: common.UIAbilityContext,
    songToDelete: SongItemType
  ): Promise<void> {
    console.info(`开始删除歌曲: ${songToDelete.name} (ID: ${songToDelete.id})`)

    // 1. 清理本地文件
    try {
      // 清理音频文件
      const audioFilePath = `${context.filesDir}/${songToDelete.filePath}`
      if (fs.accessSync(audioFilePath)) {
        fs.unlinkSync(audioFilePath)
        console.info(`已删除音频文件: ${audioFilePath}`)
      } else {
        console.warn(`音频文件不存在，跳过删除: ${audioFilePath}`)
      }

      // 清理封面图片文件 (如果存在)
      if (songToDelete.img && songToDelete.img.startsWith('file://')) {
        const coverPath = songToDelete.img.substring('file://'.length)
        if (fs.accessSync(coverPath)) {
          fs.unlinkSync(coverPath)
          console.info(`已删除封面文件: ${coverPath}`)
        } else {
          console.warn(`封面文件不存在，跳过删除: ${coverPath}`)
        }
      }

      // 2. 清理歌词文件 (调用内部文件删除函数)
      await MusicImportService._deleteLyricFileInternal(songToDelete.lyricPath)
      console.info(`已尝试删除歌词文件 (路径: ${songToDelete.lyricPath})`)

    } catch (e) {
      console.error(`文件清理过程中发生错误: ${JSON.stringify(e)}`)
    }
  }
}