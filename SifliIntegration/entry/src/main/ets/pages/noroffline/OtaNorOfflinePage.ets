import { SFLog,SFError, SFFileUtil,SFTransmitFileUtil  } from '@sifli/siflicore'
import picker from '@ohos.file.picker';

import promptAction from '@ohos.promptAction';
import { ArrayList } from '@kit.ArkTS';
import { SpeedView } from '../utils/SpeedView/SpeedView';
import { SFOtaManager,NorImageID,OTAImageFileInfo } from '@sifli/sifliotasdk';
import { ImageFileItem } from '../nand/ImageFileItem';
import { OtaNorOfflineCallbackImpl } from './OtaNorOfflineCallbackImpl';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';


const TAG:string = "OtaNorOfflinePage"
@Entry
@Component
export  struct OtaNorOfflinePage {
  @State title: string = 'Ota NorOffline';
  @State selectedMac: string = ''; // 新增状态变量存储MAC地址
  @State selectFileName: string = ''; // 控制文件名称
  @State selectFilePath: string | null = null; // 控制文件路径
  @State imageFiles: ImageFileItem[] = []; // 控制文件路径

  @State logs: string[] = []; // 使用 Array 替代 ArrayList
  @State progress:number = 0;
  @State speedText:string = "瞬时 0KB/s 平均 0KB/s";

  @State imageListVisible:boolean = true;
  private manager:SFOtaManager = SFOtaManager.getInstance();
  private speedView:SpeedView = new SpeedView();
  // 定义回调实现类
  private callbackImpl: OtaNorOfflineCallbackImpl | null = null;

  build() {
    Column() {
      Text(this.title)
        .width('90%')
        .margin({ top: 20, bottom: 10 })
        .fontSize(18)
        .fontColor('#000000')
        .textAlign(TextAlign.Center)
      // 新增的MAC地址显示区域
      Text(this.selectedMac ? `设备: ${this.selectedMac}` : '未选择设备')
        .width('90%')
        .margin({ top: 20, bottom: 10,left:15 })
        .fontSize(16)
        .fontColor(this.selectedMac ? '#000000' : '#999999')
        .textAlign(TextAlign.Start)
        .width('100%')
        .height(40)
      Row(){
        Button("Select Offline File")
          .width(200)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(async () =>{
            await this.onSelectOfflineFileBtnTouch();
          })
        Text(this.selectFileName ? `${this.selectFileName}` : '---')
          .width('90%')
          .margin({ top: 20, bottom: 10,left:10})
          .fontSize(16)
          .fontColor('#999999')
          .textAlign(TextAlign.Start)
          .width('100%')
          .height('85%')
      }
      .width('100%')
      .height(40)
      .margin({top:10})

      Scroll() {
        Column() {
          ForEach(this.logs, (item: string) => {
            Text(item)
              .fontColor(Color.White)
              .fontSize(13)
              .textAlign(TextAlign.Start)
          })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
      }
      .backgroundColor(Color.Black)
      .alignSelf(ItemAlign.Start)
      .width('100%')
      .height(150)

      Row(){
        Text("进度")
          .fontSize(14)
          .margin({left:15})
          .fontColor("#666666")
        Progress({value:this.progress,type:ProgressType.Linear,total:100})
          .height(15)
          .margin({right:10})
          .layoutWeight(1)
      }.width('100%').height(20)

      Row(){
        Text("速度")
          .fontSize(14)
          .margin({left:15})
          .fontColor("#666666")
        Text(this.speedText)
          .fontSize(14)
          .margin({left:10})
          .fontColor("#333333")
      }.width('100%').height(20)

      Row(){
        Text("操作")
          .fontSize(14)
          .margin({left:15})
          .fontColor("#666666")

        Button("Start")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onStartBtnTouch()
          })

        Button("Stop")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onStopBtnTouch()
          })
      }
      .margin({top:10})
      .width('100%').height(40)

    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear(): void {
    this.manager = SFOtaManager.getInstance();
    this.manager.init(this.getUIContext().getHostContext()!);
    this.callbackImpl = new OtaNorOfflineCallbackImpl(this);
    this.manager.setCallback(this.callbackImpl);
  }

  setScreenState(isKeepScreenOn: boolean) {
    // 获取当前窗口实例
    window.getLastWindow(getContext(this)).then((curWindow) => {
      // 设置屏幕是否常亮
      curWindow.setWindowKeepScreenOn(isKeepScreenOn, (err: BusinessError) => {
        if (err.code) {
          console.error(`Failed to set the screen. Cause code: ${err.code}, message: ${err.message}`);
          return;
        }
        console.info(`Succeeded in setting the screen ${isKeepScreenOn}.`);
      });
    }).catch((err: string) => {
      console.error(`Failed to obtain the top window.. Cause code:: ${err}`);
    });
  }

  onPageShow(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>; // 获取传递过来的参数对象
    if (params) {
      const info: string = params.mac as string; // 获取info属性的值
      SFLog.i(TAG,"select device:" + info);
      this.selectedMac = info;
    }
    this.setScreenState(true);
  }

  private async onSelectOfflineFileBtnTouch(): Promise<void> {
    SFLog.i(TAG, "onSelectCtrlFileBtnTouch");
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();

      const result = await documentPicker.select(documentSelectOptions);
      if (result && result.length > 0) {
        const selPath = result[0]; // 返回第一个选中文件的URI
        SFLog.i(TAG,"selpath=" + selPath);
        this.selectFileName = SFFileUtil.getFileName(selPath);
        this.selectFilePath = await SFTransmitFileUtil.transmitFile(selPath,this.getUIContext().getHostContext()!)

        SFLog.i(TAG,`selectCtrlFilePath=${this.selectFilePath}`);
      }

    } catch (err) {
      SFLog.e(TAG, 'File picker error: ' + err.message);
    }
  }

  private onStartBtnTouch(): void{
    try{
      this.speedView.clear();
      if(this.selectFilePath == null){
        this.toast("请选择控制文件");
        return;
      }

      this.addLog("启动ota nor offline...");
      this.manager.startNorOffline(this.selectedMac,this.selectFilePath);
    }catch (ex){
      this.toast("异常:" + ex.message);
    }

  }

  private  onStopBtnTouch():void{
    SFLog.i(TAG,"onStopBtnTouch");
    this.manager.stop();
  }

  private toast(msg:string):void{
    promptAction.showToast({
      message: msg,
      duration: 2000, // 显示时长（毫秒）
      bottom: '50vp' // 距离屏幕底部距离
    });
  }

  public  handleStatus(status: number):void {
    // this.status = status;
    const msg = "handleStatus " + status;
    SFLog.i(TAG,msg);
    this.logs = [...this.logs, msg];
  }

  public updateProgress(current: number, total: number): void {
    // this.progress = (current / total * 100).toFixed(2);
    SFLog.i(TAG, `progress ${current}/${total}}`);
    this.speedView.viewSpeedByCompleteBytes(current);
    this.speedText = this.speedView.getSpeedTextWithBytes(current,total);
    if(total > 0){
      this.progress = 100 * (current / total);
    }

  }

  public  onComplete(success: boolean, error: SFError | null):void {
    const msg = `onComplete success=${success},error=${error}`;
    this.logs = [...this.logs, msg];
    SFLog.i(TAG,msg)
  }

  private addLog(msg:string){
    this.logs = [...this.logs, msg];
  }
}