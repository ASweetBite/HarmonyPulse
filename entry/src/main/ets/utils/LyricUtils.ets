// src/main/ets/utils/LyricUtils.ts
import { LyricLine } from '../type/SongItemType';

export function parseLrc(lrcContent: string): LyricLine[] {
  const lines = lrcContent.split('\n');
  const result: LyricLine[] = [];
  // 正则匹配时间标签 [mm:ss.xx] 或 [mm:ss.xxx]
  const timeExp = /\[(\d{2}):(\d{2})\.(\d{2,3})\]/;

  for (let line of lines) {
    const match = timeExp.exec(line);
    if (match) {
      const minutes = parseInt(match[1]);
      const seconds = parseInt(match[2]);
      const milliseconds = parseInt(match[3].length === 2 ? match[3] + '0' : match[3]);

      const time = minutes * 60 * 1000 + seconds * 1000 + milliseconds;
      const text = line.replace(timeExp, '').trim(); // 去掉时间标签，只留歌词

      if (text) {
        result.push({ time, text });
      }
    }
  }
  return result.sort((a, b) => a.time - b.time);
}
