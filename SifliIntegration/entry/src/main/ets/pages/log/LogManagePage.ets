import { SFFileUtil, SFLog } from '@sifli/siflicore';
import { SFLogReceiver } from '../utils/log/SFLogReceiver';
import { LogItem } from './LogItem';

import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';

const TAG = "LogManagePage";
@Entry
@Component
struct LogManagePage {
  @State title: string = '日志管理';
  @State logItems: Array<LogItem> = []

  build() {
    Column() {
      Text(this.title)
        .width('90%')
        .margin({ top: 20, bottom: 10 })
        .fontSize(18)
        .fontColor('#000000')
        .textAlign(TextAlign.Center)

      // 设备列表
      List({ space: 10 }) {
        ForEach(this.logItems, (item:LogItem) => {
          ListItem() {
            Row() {
              Text(`${item.filename}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
              Button("分享")
                .height(25)
                .margin({left:15})
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .onClick(async () =>{
                  await this.onShareBtnTouch(item);
                })
            }
            .width('100%')
            .padding(10)
            .borderRadius(8)
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }

  onPageShow(): void {
    this.readLogs();
  }

  private async onShareBtnTouch(item:LogItem): Promise<void> {
    SFLog.i(TAG,"onShareBtnTouch " + item.filename);
    this.shareFile(item.filePath,item.filename);
  }

  private async  readLogs(): Promise<void>{
    SFLog.i(TAG,"readLogs");
    const logDir = SFLogReceiver.getInstance().getLogDir();
    if(logDir == null){
      return;
    }
    const logFiles = await SFFileUtil.listFilesInDir(logDir);
    if(logFiles == null){
      return;
    }
    for(const  file of logFiles){
      const filename = SFFileUtil.getFileName(file);
      const item:LogItem = {filename:filename,filePath:file}
      this.logItems = this.logItems.concat(item);
    }
  }

  private shareFile(filePath: string,fileName:string): void {
    // 获取文件扩展名并匹配UTD类型
    const fileExt = filePath.split('.').pop() ?? '';
    const utdType = utd.getUniformDataTypeByFilenameExtension(`.${fileExt}`, utd.UniformDataType.FILE);

    // 构造分享数据
    const shareData = new systemShare.SharedData({
      utd: utdType,
      uri: fileUri.getUriFromPath(filePath),
      title: fileName,
      description: `来自应用的日志文件`
    });

    // 创建分享控制器
    const controller = new systemShare.ShareController(shareData);
    const context = getContext(this) as common.UIAbilityContext;

    // 显示分享面板
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    }).then(() => {
      SFLog.i(TAG,'分享面板已调起');
    }).catch((err: BusinessError) => {
      SFLog.e(TAG,`分享失败 code:${err.code}, message:${err.message}`);
    });
  }
}