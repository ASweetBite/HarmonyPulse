export interface SongItemType {
  img: string
  name: string
  author: string
  lyricPath?: string        // 本地 lrc 文件路径（file:// 或绝对路径）
  hasLyric?: boolean        // 是否有歌词（快速判断）
  filePath: string
  id:string
}
