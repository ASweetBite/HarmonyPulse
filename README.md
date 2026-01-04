 <img src="images/cover.png" alt="cover" style="zoom: 33%;" />

# 基于 OpenHarmony 的本地音乐播放器（ArkTS + AVPlayer）—比赛方向：OS应用开发赛道/开发应用程序



## 基本信息

* 参赛学校：中国海洋大学
* 比赛方向：OS应用程序开发
* 队伍编号：T202510423998121
* 队伍名称：问鼎三尊
* 题目编号：
* Project ID：

* 项目指导教师：李晓慧
* 项目成员：曲泓勃，任睿哲，郑鑫

## 项目概述

**操作系统：**OpenHarmony（Stage 模型）

**应用开发语言：**ArkTS

**UI 框架：**ArkUI（声明式 UI）

**多媒体能力：**AVPlayer（音频播放）

**文件访问：**OpenHarmony 文件系统能力

**应用架构：**分层架构 + 状态驱动（State-driven UI）

**API版本：** HarmonyOS 6.0.1(21)

**aim:**OpenHarmony 为多设备场景提供统一的应用开发框架与系统能力，音视频能力是其关键基础能力之一。本项目聚焦“**本地音频播放**”这一高频应用场景，基于 ArkTS 调用 **AVPlayer** 实现稳定播放链路，并围绕“扫描-管理-播放-交互”形成可扩展的播放器架构。



## 项目介绍

### 运行环境

#### 开发环境要求

开发工具：DevEco Studio

SDK版本：6.0.1（21）



#### 模拟机配置

支持本地模拟器或远程模拟器：

本地模拟器：在DevEco Studio中直接运行，无需真机

内存要求：建议8GB以上，16GB更佳

存储空间：至少10GB可用空间

#### 真机调试

支持以下设备进行真机调试：

* HarmonyOS 6.0.1(21) 及以上版本的华为设备
* 包括Mate 60系列、Mate 70系列、Pura系列、MatePad Pro等

#### 网络要求

* 需要稳定网络连接以下载SDK和依赖包
* 建议使用高速网络以提升编译效率

### 项目结构

 <img src=".\images\项目框架图.png" alt="image-20260104180742151" style="zoom: 50%;" />



## 仓库目录结构

```txt
Folder PATH listing for volume Data
Volume serial number is 74C8-CA5F
E:\OS-APPLICATION\PROJECT3035747-358315
│   .DS_Store
│   .gitignore
│   build-profile.json5
│   code-linter.json5
│   hvigorfile.ts
│   list.txt
│   oh-package-lock.json5
│   oh-package.json5
│   
├───.hvigor
│   ├───cache
│   │       meta.json
│   │       
│   ├───dependencyMap
│   │   │   dependencyMap.json5
│   │   │   oh-package.json5
│   │   │   
│   │   └───entry
│   │           oh-package.json5
│   │           
│   └───outputs
│       ├───build-logs
│       │       build.log
│       │       
│       └───sync
│               fileCache.json
│               output.json
│               
├───.idea
│   │   .gitignore
│   │   modules.xml
│   │   vcs.xml
│   │   workspace.xml
│   │   
│   ├───.deveco
│   │   │   project.cache.json
│   │   │   
│   │   ├───cxx
│   │   │       .clang-format
│   │   │       
│   │   └───module
│   │           entry.cache.json
│   │           
│   └───modules
│           entry.iml
│           project3035747-358315.iml
│           
├───AppScope
│   │   app.json5
│   │   
│   └───resources
│       └───base
│           ├───element
│           │       string.json
│           │       
│           └───media
│                   background.png
│                   ce.jpg
│                   foreground.png
│                   icon.png
│                   ic_auto.svg
│                   ic_back.svg
│                   ic_bells_o.svg
│                   ic_boy.svg
│                   ic_cd.png
│                   ic_close.svg
│                   ic_code.svg
│                   ic_collect.svg
│                   ic_comment.svg
│                   ic_comment_o.svg
│                   ic_default.png
│                   ic_download.svg
│                   ic_download_o.svg
│                   ic_favorite.svg
│                   ic_find.svg
│                   ic_girl.svg
│                   ic_like.svg
│                   ic_list.svg
│                   ic_logo.svg
│                   ic_mine.svg
│                   ic_moment.svg
│                   ic_more.svg
│                   ic_music.svg
│                   ic_next.svg
│                   ic_paused.svg
│                   ic_play.svg
│                   ic_playing.gif
│                   ic_prev.svg
│                   ic_random.svg
│                   ic_recommend.svg
│                   ic_repeat.svg
│                   ic_search.svg
│                   ic_share.svg
│                   ic_single_play.svg
│                   ic_song_list.svg
│                   ic_stylus.png
│                   ic_vip.png
│                   ic_widget.png
│                   layered_image.json
│                   logo.png
│                   maLouBackground.png
│                   startIcon.png
│                   wave.gif
│                   
├───entry
│   │   .gitignore
│   │   build-profile.json5
│   │   hvigorfile.ts
│   │   obfuscation-rules.txt
│   │   oh-package.json5
│   │   
│   └───src
│       ├───main
│       │   │   module.json5
│       │   │   
│       │   ├───ets
│       │   │   ├───entryability
│       │   │   │       EntryAbility.ets
│       │   │   │       
│       │   │   ├───entrybackupability
│       │   │   │       EntryBackupAbility.ets
│       │   │   │       
│       │   │   ├───pages
│       │   │   │   │   Index.ets
│       │   │   │   │   layout.ets
│       │   │   │   │   PlaylistDetail.ets
│       │   │   │   │   test.ets
│       │   │   │   │   
│       │   │   │   ├───components
│       │   │   │   │       MiniPlayBar.ets
│       │   │   │   │       
│       │   │   │   └───views
│       │   │   │           LibraryView.ets
│       │   │   │           PlaylistView.ets
│       │   │   │           
│       │   │   ├───type
│       │   │   │       data.ets
│       │   │   │       GlobalMusic.ets
│       │   │   │       SongItemType.ets
│       │   │   │       SongListItemType.ets
│       │   │   │       
│       │   │   └───utils
│       │   │           avPlayerMusic.ets
│       │   │           AVSessionManager.ets
│       │   │           LyricManager.ets
│       │   │           MusicImportService.ets
│       │   │           RdbManager.ets
│       │   │           TimeUtils.ets
│       │   │           
│       │   └───resources
│       │       ├───base
│       │       │   ├───element
│       │       │   │       color.json
│       │       │   │       float.json
│       │       │   │       string.json
│       │       │   │       
│       │       │   ├───media
│       │       │   │       background.png
│       │       │   │       foreground.png
│       │       │   │       layered_image.json
│       │       │   │       startIcon.png
│       │       │   │       
│       │       │   └───profile
│       │       │           backup_config.json
│       │       │           main_pages.json
│       │       │           route_map.json
│       │       │           
│       │       ├───dark
│       │       │   └───element
│       │       │           color.json
│       │       │           
│       │       └───rawfile
│       │           └───icon
│       │                   ic_find.svg
│       │                   ic_music.svg
│       │                   ic_recommend.svg
│       │                   
│       ├───mock
│       │       mock-config.json5
│       │       
│       ├───ohosTest
│       │   │   module.json5
│       │   │   
│       │   └───ets
│       │       └───test
│       │               Ability.test.ets
│       │               List.test.ets
│       │               PlaylistView.test.ets
│       │               
│       └───test
│               List.test.ets
│               LocalUnit.test.ets
│               
├───hvigor
│       hvigor-config.json5
│       
└───oh_modules
    ├───.ohpm
    │   │   lock.json5
    │   │   
    │   ├───@ohos+hamock@1.0.0
    │   │   └───oh_modules
    │   │       └───@ohos
    │   │           └───hamock
    │   │               │   build-profile.json5
    │   │               │   CHANGELOG.md
    │   │               │   hvigorfile.js
    │   │               │   hvigorfile.ts
    │   │               │   index.d.ts
    │   │               │   index.ets
    │   │               │   index.js
    │   │               │   index.ts
    │   │               │   LICENSE
    │   │               │   oh-package.json5
    │   │               │   README.md
    │   │               │   
    │   │               ├───libs
    │   │               └───src
    │   │                   ├───main
    │   │                   │   │   module.json
    │   │                   │   │   
    │   │                   │   └───mock
    │   │                   │           ArgumentMatchers.js
    │   │                   │           ArgumentMatchers.ts
    │   │                   │           ExtendInterface.js
    │   │                   │           ExtendInterface.ts
    │   │                   │           MockKit.js
    │   │                   │           MockKit.ts
    │   │                   │           VerificationMode.js
    │   │                   │           VerificationMode.ts
    │   │                   │           
    │   │                   └───res
    │   │                       └───schemas
    │   │                               mock-config-json5-schema.json
    │   │                               
    │   ├───@ohos+hypium@1.0.24
    │   │   └───oh_modules
    │   │       └───@ohos
    │   │           └───hypium
    │   │               │   build-profile.json5
    │   │               │   BuildProfile.ets
    │   │               │   CHANGELOG.md
    │   │               │   consumer-rules.txt
    │   │               │   hvigorfile.ts
    │   │               │   index.d.ts
    │   │               │   index.ets
    │   │               │   index.js
    │   │               │   index.ts
    │   │               │   LICENSE
    │   │               │   obfuscation-rules.txt
    │   │               │   oh-package.json5
    │   │               │   README.md
    │   │               │   
    │   │               ├───example
    │   │               ├───libs
    │   │               └───src
    │   │                   └───main
    │   │                       │   Constant.js
    │   │                       │   core.js
    │   │                       │   event.js
    │   │                       │   interface.js
    │   │                       │   module.json
    │   │                       │   service.js
    │   │                       │   
    │   │                       ├───module
    │   │                       │   ├───assert
    │   │                       │   │   │   assertClose.js
    │   │                       │   │   │   assertContain.js
    │   │                       │   │   │   assertFail.js
    │   │                       │   │   │   assertFalse.js
    │   │                       │   │   │   assertInstanceOf.js
    │   │                       │   │   │   assertLarger.js
    │   │                       │   │   │   assertLargerOrEqual.js
    │   │                       │   │   │   assertLess.js
    │   │                       │   │   │   assertLessOrEqual.js
    │   │                       │   │   │   assertNaN.js
    │   │                       │   │   │   assertNegUnlimited.js
    │   │                       │   │   │   assertNull.js
    │   │                       │   │   │   assertPosUnlimited.js
    │   │                       │   │   │   assertPromiseIsPending.js
    │   │                       │   │   │   assertPromiseIsRejected.js
    │   │                       │   │   │   assertPromiseIsRejectedWith.js
    │   │                       │   │   │   assertPromiseIsRejectedWithError.js
    │   │                       │   │   │   assertPromiseIsResolved.js
    │   │                       │   │   │   assertPromiseIsResolvedWith.js
    │   │                       │   │   │   assertThrowError.js
    │   │                       │   │   │   assertUndefined.js
    │   │                       │   │   │   ExpectExtend.js
    │   │                       │   │   │   isPromiseLike.js
    │   │                       │   │   │   
    │   │                       │   │   └───deepEquals
    │   │                       │   │           assertDeepEquals.js
    │   │                       │   │           DeepTypeUtils.js
    │   │                       │   │           
    │   │                       │   ├───config
    │   │                       │   │       configService.js
    │   │                       │   │       DataDriver.js
    │   │                       │   │       Filter.js
    │   │                       │   │       
    │   │                       │   ├───coverage
    │   │                       │   │       coverageCollect.js
    │   │                       │   │       
    │   │                       │   ├───kit
    │   │                       │   │       SysTestKit.js
    │   │                       │   │       
    │   │                       │   ├───mock
    │   │                       │   │       ArgumentMatchers.js
    │   │                       │   │       ExtendInterface.js
    │   │                       │   │       MockKit.js
    │   │                       │   │       VerificationMode.js
    │   │                       │   │       
    │   │                       │   └───report
    │   │                       │           LogExpectError.js
    │   │                       │           OhReport.js
    │   │                       │           ReportExtend.js
    │   │                       │           
    │   │                       └───testrunner
    │   │                               OpenHarmonyTestRunner.ts
    │   │                               
    │   └───oh_modules
    │       └───@ohos
    │           ├───hamock
    │           │   │   build-profile.json5
    │           │   │   CHANGELOG.md
    │           │   │   hvigorfile.js
    │           │   │   hvigorfile.ts
    │           │   │   index.d.ts
    │           │   │   index.ets
    │           │   │   index.js
    │           │   │   index.ts
    │           │   │   LICENSE
    │           │   │   oh-package.json5
    │           │   │   README.md
    │           │   │   
    │           │   ├───libs
    │           │   └───src
    │           │       ├───main
    │           │       │   │   module.json
    │           │       │   │   
    │           │       │   └───mock
    │           │       │           ArgumentMatchers.js
    │           │       │           ArgumentMatchers.ts
    │           │       │           ExtendInterface.js
    │           │       │           ExtendInterface.ts
    │           │       │           MockKit.js
    │           │       │           MockKit.ts
    │           │       │           VerificationMode.js
    │           │       │           VerificationMode.ts
    │           │       │           
    │           │       └───res
    │           │           └───schemas
    │           │                   mock-config-json5-schema.json
    │           │                   
    │           └───hypium
    │               │   build-profile.json5
    │               │   BuildProfile.ets
    │               │   CHANGELOG.md
    │               │   consumer-rules.txt
    │               │   hvigorfile.ts
    │               │   index.d.ts
    │               │   index.ets
    │               │   index.js
    │               │   index.ts
    │               │   LICENSE
    │               │   obfuscation-rules.txt
    │               │   oh-package.json5
    │               │   README.md
    │               │   
    │               ├───example
    │               ├───libs
    │               └───src
    │                   └───main
    │                       │   Constant.js
    │                       │   core.js
    │                       │   event.js
    │                       │   interface.js
    │                       │   module.json
    │                       │   service.js
    │                       │   
    │                       ├───module
    │                       │   ├───assert
    │                       │   │   │   assertClose.js
    │                       │   │   │   assertContain.js
    │                       │   │   │   assertFail.js
    │                       │   │   │   assertFalse.js
    │                       │   │   │   assertInstanceOf.js
    │                       │   │   │   assertLarger.js
    │                       │   │   │   assertLargerOrEqual.js
    │                       │   │   │   assertLess.js
    │                       │   │   │   assertLessOrEqual.js
    │                       │   │   │   assertNaN.js
    │                       │   │   │   assertNegUnlimited.js
    │                       │   │   │   assertNull.js
    │                       │   │   │   assertPosUnlimited.js
    │                       │   │   │   assertPromiseIsPending.js
    │                       │   │   │   assertPromiseIsRejected.js
    │                       │   │   │   assertPromiseIsRejectedWith.js
    │                       │   │   │   assertPromiseIsRejectedWithError.js
    │                       │   │   │   assertPromiseIsResolved.js
    │                       │   │   │   assertPromiseIsResolvedWith.js
    │                       │   │   │   assertThrowError.js
    │                       │   │   │   assertUndefined.js
    │                       │   │   │   ExpectExtend.js
    │                       │   │   │   isPromiseLike.js
    │                       │   │   │   
    │                       │   │   └───deepEquals
    │                       │   │           assertDeepEquals.js
    │                       │   │           DeepTypeUtils.js
    │                       │   │           
    │                       │   ├───config
    │                       │   │       configService.js
    │                       │   │       DataDriver.js
    │                       │   │       Filter.js
    │                       │   │       
    │                       │   ├───coverage
    │                       │   │       coverageCollect.js
    │                       │   │       
    │                       │   ├───kit
    │                       │   │       SysTestKit.js
    │                       │   │       
    │                       │   ├───mock
    │                       │   │       ArgumentMatchers.js
    │                       │   │       ExtendInterface.js
    │                       │   │       MockKit.js
    │                       │   │       VerificationMode.js
    │                       │   │       
    │                       │   └───report
    │                       │           LogExpectError.js
    │                       │           OhReport.js
    │                       │           ReportExtend.js
    │                       │           
    │                       └───testrunner
    │                               OpenHarmonyTestRunner.ts
    │                               
    └───@ohos
        ├───hamock
        │   │   build-profile.json5
        │   │   CHANGELOG.md
        │   │   hvigorfile.js
        │   │   hvigorfile.ts
        │   │   index.d.ts
        │   │   index.ets
        │   │   index.js
        │   │   index.ts
        │   │   LICENSE
        │   │   oh-package.json5
        │   │   README.md
        │   │   
        │   ├───libs
        │   └───src
        │       ├───main
        │       │   │   module.json
        │       │   │   
        │       │   └───mock
        │       │           ArgumentMatchers.js
        │       │           ArgumentMatchers.ts
        │       │           ExtendInterface.js
        │       │           ExtendInterface.ts
        │       │           MockKit.js
        │       │           MockKit.ts
        │       │           VerificationMode.js
        │       │           VerificationMode.ts
        │       │           
        │       └───res
        │           └───schemas
        │                   mock-config-json5-schema.json
        │                   
        └───hypium
            │   build-profile.json5
            │   BuildProfile.ets
            │   CHANGELOG.md
            │   consumer-rules.txt
            │   hvigorfile.ts
            │   index.d.ts
            │   index.ets
            │   index.js
            │   index.ts
            │   LICENSE
            │   obfuscation-rules.txt
            │   oh-package.json5
            │   README.md
            │   
            ├───example
            ├───libs
            └───src
                └───main
                    │   Constant.js
                    │   core.js
                    │   event.js
                    │   interface.js
                    │   module.json
                    │   service.js
                    │   
                    ├───module
                    │   ├───assert
                    │   │   │   assertClose.js
                    │   │   │   assertContain.js
                    │   │   │   assertFail.js
                    │   │   │   assertFalse.js
                    │   │   │   assertInstanceOf.js
                    │   │   │   assertLarger.js
                    │   │   │   assertLargerOrEqual.js
                    │   │   │   assertLess.js
                    │   │   │   assertLessOrEqual.js
                    │   │   │   assertNaN.js
                    │   │   │   assertNegUnlimited.js
                    │   │   │   assertNull.js
                    │   │   │   assertPosUnlimited.js
                    │   │   │   assertPromiseIsPending.js
                    │   │   │   assertPromiseIsRejected.js
                    │   │   │   assertPromiseIsRejectedWith.js
                    │   │   │   assertPromiseIsRejectedWithError.js
                    │   │   │   assertPromiseIsResolved.js
                    │   │   │   assertPromiseIsResolvedWith.js
                    │   │   │   assertThrowError.js
                    │   │   │   assertUndefined.js
                    │   │   │   ExpectExtend.js
                    │   │   │   isPromiseLike.js
                    │   │   │   
                    │   │   └───deepEquals
                    │   │           assertDeepEquals.js
                    │   │           DeepTypeUtils.js
                    │   │           
                    │   ├───config
                    │   │       configService.js
                    │   │       DataDriver.js
                    │   │       Filter.js
                    │   │       
                    │   ├───coverage
                    │   │       coverageCollect.js
                    │   │       
                    │   ├───kit
                    │   │       SysTestKit.js
                    │   │       
                    │   ├───mock
                    │   │       ArgumentMatchers.js
                    │   │       ExtendInterface.js
                    │   │       MockKit.js
                    │   │       VerificationMode.js
                    │   │       
                    │   └───report
                    │           LogExpectError.js
                    │           OhReport.js
                    │           ReportExtend.js
                    │           
                    └───testrunner
                            OpenHarmonyTestRunner.ts
                            

```



## 项目实现功能

* ✅ 歌曲添加 / 删除
* ✅ 防止重复导入（去重机制）
* ✅ 播放歌曲 + 歌词动态同步显示
* ✅ 歌单管理（创建 / 加歌）
* ✅ 播放模式（顺序 / 随机 / 单曲循环）
* ✅ 后台播放
* ✅ 通知栏控制
* ✅ 灵动岛（Live Activity 类似体验）
* ✅ 媒体库能力：读取 ID3 标签、封面图



### 后续迭代方向

* 实现播放历史 & 最近播放

* 多设备协同：跨设备播控/流转（OpenHarmony 分布式能力）

###

## 需求分析与开发思路过程

### 迭代式开发过程（从内核到体验）

  采用“**最小可用版本（MVP）→ 可用性完善 → 体验优化**”三阶段：

  **阶段 1：播放链路打通（MVP）**

* 完成 AVPlayer 初始化、setSource/prepare/play

* 能成功播放固定本地音

  **阶段 2：列表驱动播放**

* 扫描本地目录形成 MusicItem 列表

* 点击列表项切换音源并播放

* 增加上一首/下一首逻辑

  **阶段 3：状态与交互完善（应用导向）**

* 进度条与时间显示（current/duration）

* 拖动进度 seek

* 播放状态与 UI 绑定（播放/暂停按钮切换）

* 错误提示与空态页面



### 项目总结

  本项目基于 OpenHarmony，使用 ArkTS + AVPlayer 实现本地音乐播放器，完成从本地扫描到播放控制的应用闭环，并以“播放器服务化 + 状态机”的方式保证稳定性与可维护性，满足 OS 应用开发赛道对“技术实现 + 应用体验”的综合要求。
