export interface SongItemType {
  img: string
  name: string
  author: string
  fileName: string
  lyricPath?: string
  hasLyric?: boolean
  id:string
}

export interface LyricLine {
  time: number   // 毫秒
  text: string
}