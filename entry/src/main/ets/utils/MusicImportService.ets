import { fileIo as fs, picker } from '@kit.CoreFileKit'
import { media } from '@kit.MediaKit'
import { image } from '@kit.ImageKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { SongItemType } from '../type/SongItemType'
import { GlobalMusic } from '../type/GlobalMusic'

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

      console.info('歌曲导入完成')

    } catch (err) {
      const error = err as BusinessError
      console.error(`导入失败: ${error.code}, ${error.message}`)
    }
  }

  /**
   * 导入单个音频文件
   */
  private static async importSingleFile(
    uri: string,
    context: common.UIAbilityContext
  ): Promise<SongItemType | null> {

    // ---------- 1. 解析文件名 ----------
    const decodeUri = decodeURIComponent(uri)
    const fullName = decodeUri.substring(decodeUri.lastIndexOf('/') + 1)
    const dotIndex = fullName.lastIndexOf('.')

    const baseName = dotIndex !== -1 ? fullName.substring(0, dotIndex) : fullName
    const ext = dotIndex !== -1 ? fullName.substring(dotIndex) : '.mp3'

    // ---------- 2. 拷贝到沙箱 ----------
    const newFileName = `${Date.now()}${ext}`
    const destPath = `${context.filesDir}/${newFileName}`

    const src = fs.openSync(uri, fs.OpenMode.READ_ONLY)
    const dest = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
    fs.copyFileSync(src.fd, dest.fd)
    fs.closeSync(src)
    fs.closeSync(dest)

    // ---------- 3. 解析元数据 ----------
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

    // ---------- 4. 构造歌曲对象 ----------
    return {
      id: `user_${Date.now()}_${Math.random().toString(36).slice(2, 5)}`,
      name: title,
      author: artist,
      img: coverUri,
      fileName: newFileName
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
