import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { SongItemType } from '../../type/SongItemType';
import { SongListItemType } from '../../type/SongListItemType';
// 请确保路径正确引入你的数据库管理类
import RdbManager  from '../../utils/RdbManager';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { GlobalMusic } from '../../type/GlobalMusic';

// --- 数据模型适配 ---
@ObservedV2
class PlaylistModel implements SongListItemType {
  id: number;
  @Trace img: string;
  @Trace name: string;
  @Trace num: number;
  songs: SongItemType[];

  constructor(data: SongListItemType) {
    this.id = data.id || 0; // 确保有 ID
    this.img = data.img;
    this.name = data.name;
    this.num = data.num;
    this.songs = data.songs || [];
  }
}

// --- 新建歌单弹窗 (保持不变) ---
@CustomDialog
struct CreatePlaylistDialog {
  controller: CustomDialogController;
  onConfirm: (name: string, img: string) => void = () => {};
  @State tempName: string = '';
  @State selectedImg: string = ''; // 存储选中的图片路径

  // 选择图片函数
  async selectImage() {
    try {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      PhotoSelectOptions.maxSelectNumber = 1;
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let photoSelectResult = await photoPicker.select(PhotoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        this.selectedImg = photoSelectResult.photoUris[0]; // 获取图片URI
      }
    } catch (err) {
      console.error('选择图片失败: ' + err);
    }
  }

  build() {
    Column() {
      Text("新建歌单").fontSize(20).fontWeight(FontWeight.Bold).margin({ top: 20, bottom: 20 })

      Stack() {
        if (this.selectedImg) {
          Image(this.selectedImg)
            .width(120).height(120).borderRadius(12).objectFit(ImageFit.Cover)
        } else {
          Rect().width(120).height(120).fill('#F2F2F7').borderRadius(12)
          Text("点击选择封面").fontSize(12).fontColor('#007AFF')
        }
      }
      .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
      .onClick(() => this.selectImage()) // 点击调起相册
      .margin({ bottom: 20 })

      TextInput({ placeholder: '请输入歌单名称', text: this.tempName })
        .onChange(v => this.tempName = v)
        .width('90%').height(48).backgroundColor('#F5F5F5').borderRadius(10).margin({ bottom: 20 })

      Row() {
        Button("取消").onClick(() => this.controller.close()).backgroundColor(Color.Transparent).fontColor('#8a8a8e').layoutWeight(1)
        Divider().vertical(true).height(24)
        Button("完成").onClick(() => {
          if (!this.tempName) return;
          // 如果没选图，可以传一个默认图
          this.onConfirm(this.tempName, this.selectedImg || '');
          this.controller.close();
        }).backgroundColor(Color.Transparent).fontColor('#007AFF').fontWeight(FontWeight.Bold).layoutWeight(1)
      }.width('100%').height(50).border({ width: { top: 1 }, color: '#EEEEEE' })
    }.width('80%').backgroundColor(Color.White).borderRadius(16)
  }
}

@ComponentV2
export struct PlaylistView {
  // 1. 接收父组件传入的回调函数 (关键点：这里不做默认实现，由父组件传入)
  @Event onPlaylistSelected: (item: SongListItemType) => void = (name) => {};
  @Local globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, "GlobalMusic", () => new GlobalMusic())!;

  // 2. 状态管理
  @Local playlistCollections: PlaylistModel[] = [];
  @Local isEditMode: boolean = false;

  // 3. 生命周期：加载数据库数据
  aboutToAppear() {
    this.refreshPlaylists();
  }

  // --- 业务逻辑 ---

  async refreshPlaylists() {
    try {
      // 从数据库获取数据
      const list = await RdbManager.getAllPlaylists();
      this.playlistCollections = list.map(item => new PlaylistModel(item));
    } catch (err) {
      console.error('加载歌单失败:', err);
    }
  }

  async handleDeletePlaylist(item: PlaylistModel) {
    try {
      // 数据库删除
      const success = await RdbManager.deletePlaylist(item.id);
      if (success) {
        // UI 删除 (为了性能，不重新查库，直接操作数组)
        const index = this.playlistCollections.findIndex(p => p.id === item.id);
        if (index !== -1) {
          this.playlistCollections.splice(index, 1);
        }
        promptAction.showToast({ message: '已删除' });

        // 如果删完了，自动退出编辑模式
        if (this.playlistCollections.length === 0) {
          this.isEditMode = false;
        }
      } else {
        promptAction.showToast({ message: '删除失败' });
      }
    } catch (err) {
      console.error('删除操作异常:', err);
    }
  }

  async handleAddPlaylist(name: string, img: string) {
    // 这里暂时仅做前端演示，重新刷新列表
    promptAction.showToast({ message: '歌单已创建' });
    // 实际开发请取消下面注释并实现 insert
    // await RdbManager.insertPlaylist({ name, img, ... });
    await RdbManager.createPlaylist(name, img);
    this.refreshPlaylists();
  }

  private async loadPlaylistSongs(playlistId: number): Promise<void> {
    this.globalMusic.songList = await RdbManager.getSongsByPlaylistId(playlistId);
  }


  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CreatePlaylistDialog({
      onConfirm: (name: string, img: string): Promise<void> => this.handleAddPlaylist(name, img)
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center
  });

  // --- UI 组件构建 ---

  @Builder
  PlaylistCard(item: PlaylistModel) {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 1. 卡片主体内容
      Column() {
        // 封面区域
        Stack() {
          if (item.img.startsWith('#')) {
            // 纯色封面 (模拟)
            Rect().width('100%').aspectRatio(1).fill(item.img).borderRadius(12)
          } else {
            // 图片封面
            Image(item.img || $r('app.media.ic_default_list'))
              .width('100%').aspectRatio(1).borderRadius(12)
              .alt($r('app.media.ic_song_list'))
          }
          // 漫反射阴影效果
          Rect()
            .width('90%').height('90%').fill(Color.Black).borderRadius(12)
            .position({ x: '5%', y: 10 }).blur(20).zIndex(-1).opacity(0.3)
        }
        .width('100%').aspectRatio(1)

        // 文字区域
        Column() {
          Text(item.name)
            .fontSize(16).fontWeight(FontWeight.Medium)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#1c1c1e')

          Text(`${item.num} 首歌曲`)
            .fontSize(12).fontColor('#8a8a8e').margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start).width('100%').margin({ top: 12 })
      }
      .width('100%')
      // 点击交互逻辑
      .onClick(() => {
        if (this.isEditMode) {
          return;
        }
        // 正常模式：调用父组件传入的回调
        this.loadPlaylistSongs(item.id);
        this.onPlaylistSelected(item);
      })
      // 触摸动效
      .stateStyles({
        pressed: { .scale({ x: 0.96, y: 0.96 }).animation({ duration: 100 }) },
        normal: { .scale({ x: 1, y: 1 }).animation({ duration: 100 }) }
      })

      // 2. 删除按钮 (仅编辑模式显示)
      if (this.isEditMode) {
        Stack() {
          Circle({ width: 26, height: 26 }).fill(Color.White) // 白底
          Circle({ width: 24, height: 24 }).fill('#FF3B30') // 红圈
          Text('×').fontSize(18).fontColor(Color.White).fontWeight(FontWeight.Bold).offset({ y: -1 })
        }
        .margin({ top: -10, right: -10 }) // 悬浮在右上角
        .shadow({ radius: 4, color: '#40000000', offsetY: 2 })
        .zIndex(10)
        .onClick(() => {
          // 确认弹窗
          AlertDialog.show({
            title: '删除歌单',
            message: `确定要删除 "${item.name}" 吗？`,
            primaryButton: { value: '取消', action: () => {} },
            secondaryButton: {
              value: '删除',
              fontColor: '#FF3B30',
              action: () => this.handleDeletePlaylist(item)
            }
          })
        })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }
    }
    // 编辑模式下的整体缩放提示
    .scale(this.isEditMode ? { x: 0.95, y: 0.95 } : { x: 1, y: 1 })
    .animation({ duration: 300 })
  }

  @Builder
  AddPlaylistButton() {
    Column() {
      Stack() {
        Rect().width('100%').aspectRatio(1).fill('#F2F2F7').borderRadius(12)
          .stroke('#E5E5EA').strokeWidth(1)
        Text("+").fontSize(50).fontWeight(FontWeight.Lighter).fontColor('#007AFF')
      }
      .width('100%').aspectRatio(1)
      Text("新建歌单").fontSize(16).fontWeight(FontWeight.Medium)
        .fontColor('#007AFF').margin({ top: 12 }).width('100%')
    }
    .width('100%')
    .opacity(this.isEditMode ? 0.3 : 1)
    .enabled(!this.isEditMode) // 编辑模式下禁止新建
    .onClick(() => this.dialogController?.open())
    .stateStyles({
      pressed: { .scale({ x: 0.96, y: 0.96 }) },
      normal: { .scale({ x: 1, y: 1 }) }
    })
  }

  build() {
    Column() {
      // 标题栏：确保背景色和间距紧凑
      Row() {
        Text("我的歌单")
          .fontSize(34).fontWeight(FontWeight.Bold).fontColor(Color.Black)
        Blank()
        Text(this.isEditMode ? "完成" : "编辑")
          .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#007AFF')
          .onClick(() => { this.isEditMode = !this.isEditMode; })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 60, bottom: 10 }) // 减小 bottom 间距
      .backgroundColor(Color.White)

      Grid() {
        GridItem() {
          this.AddPlaylistButton()
        }

        ForEach(this.playlistCollections, (item: PlaylistModel) => {
          GridItem() {
            this.PlaylistCard(item)
          }
        }, (item: PlaylistModel) => item.id.toString())
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(24)
      .columnsGap(16)
      .padding({ left: 20, right: 20, bottom: 40, top: 0 }) // 设置 top 为 0
      .layoutWeight(1) // 让 Grid 占满剩余高度
      .edgeEffect(EdgeEffect.Spring) // 增加弹性滚动
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

}