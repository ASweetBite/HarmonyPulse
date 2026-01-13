import fs from '@ohos.file.fs'
import { LyricLine } from '../type/SongItemType';
import common from '@ohos.app.ability.common';

export class LyricManager {
  private context: common.UIAbilityContext | null = null

  // 在 EntryAbility 或程序入口调用
  setContext(ctx: common.UIAbilityContext) {
    this.context = ctx
  }

  private getBaseDir(): string {
    if (!this.context) {
      throw new Error("LyricManager: Context not initialized. Call setContext first.");
    }
    const dir = `${this.context.filesDir}/lyrics`;
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir);
    }
    return dir;
  }

  /**
   * 解析 .lrc 格式歌词 (这个逻辑不依赖 context，可以保持 static)
   */
  static parseLrc(lrcContent: string): LyricLine[] {
    // ============ 新增：前置全量合法性校验【核心】 ============
    // 1. 空内容、纯空白 → 非法格式
    if (!lrcContent || lrcContent.trim() === '') {
      return [];
    }
    const pureContent = lrcContent.trim();
    const timeExp = /\[(\d{2}):(\d{2})\.(\d{2,3})\]/g;
    const lines = pureContent.split('\n').filter(line => line.trim() !== ''); // 过滤空行

    // 2. 核心校验：没有任何一行包含标准的 [mm:ss.ms] 时间戳 → 判定为不符合LRC格式
    const hasValidTimeFormat = lines.some(line => timeExp.test(line));
    if (!hasValidTimeFormat) {
      return [];
    }

    // ============ 原有解析逻辑 完全保留 ============
    const result: LyricLine[] = [];
    // 重置正则lastIndex，避免test后exec匹配异常
    timeExp.lastIndex = 0;

    for (let line of lines) {
      let match: RegExpExecArray | null;
      const timestamps: number[] = [];
      while ((match = timeExp.exec(line)) !== null) {
        const min = parseInt(match[1]);
        const sec = parseInt(match[2]);
        const msStr = match[3];
        const ms = parseInt(msStr.length === 2 ? msStr + '0' : msStr);
        timestamps.push(min * 60 * 1000 + sec * 1000 + ms);
      }
      const text = line.replace(timeExp, '').trim();
      if (text) {
        timestamps.forEach(time => result.push({ time, text }));
      }
    }

    // ============ 补充：解析后无有效歌词内容 也返回空 ============
    return result.length > 0 ? result.sort((a, b) => a.time - b.time) : [];
  }

  /**
   * 创建并获取歌词路径 (改为实例方法)
   */
  getOrCreateLyricPath(songId: string): string {
    const lyricPath = `${this.getBaseDir()}/${songId}.lrc`;
    if (!fs.accessSync(lyricPath)) {
      const file = fs.openSync(lyricPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      const initContent = `暂无歌词`;
      fs.writeSync(file.fd, initContent);
      fs.closeSync(file);
    }
    return lyricPath;
  }


  /**
   * 读取歌词内容
   */
  readLyricFile(path: string): string {
    try {
      if (!path) return '';

      // 如果路径是以 datashare:// 或 file:// 开头的 URI，跳过 accessSync 检查
      // 只有普通沙箱路径才使用 accessSync
      if (path.startsWith('datashare://') || path.startsWith('file://')) {
        return fs.readTextSync(path);
      }

      // 如果是沙箱路径，保留检查逻辑
      if (fs.accessSync(path)) {
        return fs.readTextSync(path);
      }
    } catch (e) {
      // 这里的错误日志能帮你定位问题
      const err = e as BusinessError;
      console.error(`Read lyric failed. Code: ${err.code}, Message: ${err.message}`);
    }
    return '';
  }

  /**
   * 保存歌词内容
   */
  saveLyricFile(path: string, content: string): void {
    try {
      const file = fs.openSync(path, fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
    } catch (e) {
      console.error(`Save lyric failed: ${JSON.stringify(e)}`);
    }
  }
}

// 导出单例
export const lyricManager = new LyricManager();
