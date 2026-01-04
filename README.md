 <img src="images/cover.png" alt="cover" style="zoom: 33%;" />

# 基于 OpenHarmony 的本地音乐播放器（ArkTS + AVPlayer）—比赛方向：OS应用开发赛道/开发应用程序

[toc]

📚项目开发文档： [设计开发文档.pdf](设计开发文档.pdf)
🎥 演示视频：[musicDemo](https://pan.quark.cn/s/64c6d02dce2b)



## 基本信息

* 参赛学校：中国海洋大学
* 比赛方向：OS应用程序开发
* 队伍编号：T202510423998121
* 队伍名称：问鼎三尊
* 题目编号：project3035747-358315
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

 <img src="images/项目框架图.png" alt="image-20260104180742151" style="zoom: 50%;" />



## 仓库目录结构

**只完全展开 `entry`中的 `src`目录**，其他部分保留但不展开：

```txt
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
├───.idea
├───AppScope
├───entry
│   │   .gitignore
│   │   build-profile.json5
│   │   hvigorfile.ts
│   │   obfuscation-rules.txt
│   │   oh-package.json5
│   │
│   └───src
│       ├───main
│       │   │   module.json5        # 模块配置文件，定义HAP包信息及Ability等[1](@ref)
│       │   │
│       │   ├───ets
│       │   │   ├───entryability         # 应用入口及生命周期管理 (EntryAbility.ets)[1,4](@ref)
│       │   │   ├───entrybackupability    # 备份恢复能力 (EntryBackupAbility.ets)[4](@ref)
│       │   │   ├───pages                 # UI页面文件 (Index.ets, PlaylistDetail.ets等)[1](@ref)
│       │   │   ├───components            # 可复用组件 (MiniPlayBar.ets)
│       │   │   ├───views                 # 视图组件 (LibraryView.ets, PlaylistView.ets)
│       │   │   ├───type                  # 类型定义 (数据模型、全局状态等)
│       │   │   └───utils                 # 工具类 (音频播放、数据库管理等)
│       │   │
│       │   └───resources
│       │       ├───base          # 基础资源 (字符串、颜色、图片等)
│       │       ├───dark          # 深色模式资源
│       │       └───rawfile       # 原始资源文件（如图标）
│       │
│       ├───mock
│       ├───ohosTest              # 单元测试目录[1,2](@ref)
│       └───test
│
├───hvigor
└───oh_modules                    # 项目依赖包存放目录[1,3](@ref)
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
