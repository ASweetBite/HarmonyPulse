import { SongItemType } from "./SongItemType"

export interface SongListItemType {
  id: number
  img: string
  name: string
  num : number
  songs: SongItemType[]
}
