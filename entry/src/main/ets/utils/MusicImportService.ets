import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { media } from '@kit.MediaKit'
import { image } from '@kit.ImageKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
// 导入首选项模块
import { preferences } from '@kit.ArkData'
import { SongItemType } from '../type/SongItemType'
import { GlobalMusic } from '../type/GlobalMusic'

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
        const song = await MusicImportService.importSingleFile(uri, context)
        if (song) {
          globalMusic.addSong(song)
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
        // 清理当前内存列表（视业务而定），然后重新添加
        list.forEach(item => {
          globalMusic.addSong(item)
        })
        console.info(`成功恢复 ${list.length} 首歌曲`)
      }
    } catch (e) {
      console.error('读取歌曲列表失败', JSON.stringify(e))
    }
  }

  /**
   * 导入单个音频文件
   */
  private static async importSingleFile(
    uri: string,
    context: common.UIAbilityContext
  ): Promise<SongItemType | null> {

    const decodeUri = decodeURIComponent(uri)
    const fullName = decodeUri.substring(decodeUri.lastIndexOf('/') + 1)
    const dotIndex = fullName.lastIndexOf('.')

    const baseName = dotIndex !== -1 ? fullName.substring(0, dotIndex) : fullName
    const ext = dotIndex !== -1 ? fullName.substring(dotIndex) : '.mp3'

    const newFileName = `${Date.now()}${ext}`
    const destPath = `${context.filesDir}/${newFileName}`

    const src = fs.openSync(uri, fs.OpenMode.READ_ONLY)
    const dest = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    fs.copyFileSync(src.fd, dest.fd)
    fs.closeSync(src)
    fs.closeSync(dest)

    let title = baseName
    let artist = '未知艺术家'
    let coverUri = 'ic_music'

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

    // ---------- 适配新的 SongItemType 结构 ----------
    return {
      id: `user_${Date.now()}_${Math.random().toString(36).slice(2, 5)}`,
      name: title,
      author: artist,
      img: coverUri,
      filePath: newFileName, // 存储沙箱内的文件名
      lyricPath: '',         // 初始为空
      hasLyric: false        // 初始为 false
    }
  }

  /**
   * 保存封面图
   */
  private static async saveCover(
    pixelMap: image.PixelMap,
    context: common.UIAbilityContext
  ): Promise<string> {
    const coverPath = `${context.filesDir}/cover_${Date.now()}.jpg`
    const file = fs.openSync(coverPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)

    const packer = image.createImagePacker()
    await packer.packToFile(pixelMap, file.fd, {
      format: 'image/jpeg',
      quality: 80
    })

    fs.closeSync(file)
    return `file://${coverPath}`
  }
}