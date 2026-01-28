import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { media } from '@kit.MediaKit'
import { image } from '@kit.ImageKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
// 导入首选项模块
import { preferences } from '@kit.ArkData'
import { SongItemType } from '../type/SongItemType'
import { GlobalMusic } from '../type/GlobalMusic'
import RdbManager from './RdbManager'
import { lyricManager, LyricManager } from './LyricManager'

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
      const uris = await audioPicker.select(new picker.AudioSelectOptions())

      if (!uris || uris.length === 0) return

      for (const uri of uris) {
        const song = await MusicImportService.importSingleFile(uri, context, globalMusic)
        if (song) {
          globalMusic.addSong(song)
          RdbManager.insertSong(song)
        }
      }

      // --- 关键改动：导入完成后持久化保存整个列表 ---
      await MusicImportService.saveSongs(context, globalMusic.songList)
      console.info('歌曲导入并持久化完成')

    } catch (err) {
      const error = err as BusinessError
      console.error(`导入失败: ${error.code}, ${error.message}`)
    }
  }

  /**
   * 函数一：持久化保存歌曲列表
   * 将 SongItemType 数组序列化为 JSON 字符串存入首选项
   */
  static async saveSongs(context: common.UIAbilityContext, songs: SongItemType[]): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME)
      // 将数组转为字符串存储
      await pref.put(KEY_SONG_LIST, JSON.stringify(songs))
      // flush 确保数据写入磁盘
      await pref.flush()
    } catch (e) {
      console.error('保存歌曲列表失败', JSON.stringify(e))
    }
  }

  /**
   * 函数二：从首选项恢复歌曲列表
   * 在 App 启动（如 EntryAbility 或主页 Entry 组件）时调用
   */
  static async loadSongs(context: common.UIAbilityContext, globalMusic: GlobalMusic): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME)
      const jsonStr = await pref.get(KEY_SONG_LIST, '[]') as string
      const list = JSON.parse(jsonStr) as SongItemType[]

      if (list && list.length > 0) {
        list.forEach((item: SongItemType) => { globalMusic.addSong(item) })
      }
    } catch (e) {
      console.error('读取歌曲列表失败', JSON.stringify(e))
    }
  }

  /**
   * 导入单个音频文件
   */
  public static async importSingleFile(
    uri: string,
    context: common.UIAbilityContext,
    globalMusic: GlobalMusic  // <--- 确保这一行存在！
  ): Promise<SongItemType | null> {

    const decodeUri = decodeURIComponent(uri)
    const fullName = decodeUri.substring(decodeUri.lastIndexOf('/') + 1)
    const dotIndex = fullName.lastIndexOf('.')

    const baseName = dotIndex !== -1 ? fullName.substring(0, dotIndex) : fullName
    const ext = dotIndex !== -1 ? fullName.substring(dotIndex) : '.mp3'

    // --- 去重逻辑 ---
    let title: string = baseName
    let artist: string = '未知艺术家'
    let preExtractor: media.AVMetadataExtractor | undefined
    let preSrcFile: fs.File | undefined

    try {
      preSrcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      preExtractor = await media.createAVMetadataExtractor()
      preExtractor.fdSrc = { fd: preSrcFile.fd }
      const metadata = await preExtractor.fetchMetadata()

      if (metadata.title?.trim()) title = metadata.title
      if (metadata.artist?.trim()) artist = metadata.artist

      // 【关键点3】检查 globalMusic.songList (因为你的类里主要用这个)
      const currentList = globalMusic.songList
      let isDuplicate = false
      for (let i = 0; i < currentList.length; i++) {
        const item: SongItemType = currentList[i]
        if (item.name === title && item.author === artist) {
          isDuplicate = true
          break
        }
      }

      if (isDuplicate) {
        console.info(`[去重] 歌曲已存在: ${title}`)
        return null
      }
    } catch (e) {
      console.warn('查重阶段解析失败')
    } finally {
      if (preExtractor) await preExtractor.release()
      if (preSrcFile) fs.closeSync(preSrcFile)
    }

    // --- 剩下的拷贝逻辑保持原样 ---
    const newFileName = `${Date.now()}${ext}`
    const destPath = `${context.filesDir}/${newFileName}`

    const src = fs.openSync(uri, fs.OpenMode.READ_ONLY)
    const dest = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    fs.copyFileSync(src.fd, dest.fd)
    fs.closeSync(src)
    fs.closeSync(dest)

    let coverUri = ''
    let extractor: media.AVMetadataExtractor | undefined
    let targetFile: fs.File | undefined

    try {
      extractor = await media.createAVMetadataExtractor()
      targetFile = fs.openSync(destPath, fs.OpenMode.READ_ONLY)
      extractor.fdSrc = { fd: targetFile.fd }
      const metadata = await extractor.fetchMetadata()
      if (metadata.title?.trim()) title = metadata.title
      if (metadata.artist?.trim()) artist = metadata.artist
      const pixelMap = await extractor.fetchAlbumCover()
      if (pixelMap) {
        coverUri = await MusicImportService.saveCover(pixelMap, context)
      }
    } catch (e) {
      console.warn(`元数据解析失败: ${JSON.stringify(e)}`)
    } finally {
      if (extractor) await extractor.release()
      if (targetFile) fs.closeSync(targetFile)
    }
    const tempId = `user_${Date.now()}_${Math.random().toString(36).slice(2, 5)}`

    // ---------- 适配新的 SongItemType 结构 ----------
    return {
      id: tempId,
      name: title,
      author: artist,
      img: coverUri,
      filePath: newFileName, // 存储沙箱内的文件名
      lyricPath: lyricManager.getOrCreateLyricPath(tempId),   //导入歌曲时自动创建歌词
      hasLyric: false        // 初始为 false
    }
  }

  private static async saveCover(
    pixelMap: image.PixelMap,
    context: common.UIAbilityContext
  ): Promise<string> {
    const coverPath = `${context.filesDir}/cover_${Date.now()}.jpg`
    const file = fs.openSync(coverPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    const packer = image.createImagePacker()
    await packer.packToFile(pixelMap, file.fd, { format: 'image/jpeg', quality: 80 })
    fs.closeSync(file)
    return `file://${coverPath}`
  }
}