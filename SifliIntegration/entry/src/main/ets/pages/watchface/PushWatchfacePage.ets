import { SFLog,SFError } from '@sifli/siflicore'
import picker from '@ohos.file.picker';
import  { SFFileUtil,SFTransmitFileUtil } from '@sifli/siflicore'
import { SFWatchfaceFilePushManager,SFWatchfaceFilePushManagerCallback } from '@sifli/sfwatchfacesdk'
import { UIContext } from '@kit.ArkUI';
import { PushWatchfaceCallbackImpl } from "./PushWatchfaceCallbackImpl"
import promptAction from '@ohos.promptAction';
import { ArrayList } from '@kit.ArkTS';
import { SpeedView } from '../utils/SpeedView/SpeedView';


const TAG:string = "PushWatchfacePage"
@Entry
@Component
export  struct PushWatchfacePage {
  @State title: string = 'Push Watchface';
  @State selectedMac: string = ''; // 新增状态变量存储MAC地址
  @State selectFileName: string = ''; // 新增状态变量存储MAC地址
  @State selectFilePath: string | null = null; // 新增状态变量存储MAC地址
  @State withByteAlign: boolean = false; // 定义状态变量
  @State fileType:number = 0;
  @State logs: string[] = []; // 使用 Array 替代 ArrayList
  @State progress:number = 0;
  @State speedText:string = "瞬时 0KB/s 平均 0KB/s";
  private manager:SFWatchfaceFilePushManager = SFWatchfaceFilePushManager.getInstance();
  private speedView:SpeedView = new SpeedView();
  // 定义回调实现类
  private callbackImpl: PushWatchfaceCallbackImpl | null = null;
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
        Button("Select File")
          .width(120)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(async () =>{
             await this.onSelectFileBtnTouch();
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
      Row(){
        Text("File Type")
          .fontSize(15)
          .fontColor("#333333")
          .margin({left:15})
        TextInput({ placeholder: 'File type',text:this.fileType.toString()})
          .type(InputType.Number)  // 限制输入仅限数字
          .fontColor("#333333")
          .fontSize(15)
          .margin({left:10})
          .height(40)
          .width(100)
          .onChange((value:string) => {
            this.onFileTypeChanged(value);
          })

      }.width('100%').height(50).margin({top:10})
      Row(){
        Text("0-表盘，1-多语言，2-背景图，3-自定义，4-音乐,5-JS,8-4G模块,9-GUIBuilder 表盘")
          .fontSize(13)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis }) //
          .fontColor("#666666")
          .margin({left:40,right:10})
      }.width('100%').height(50)
      Row(){
        Text("With Byte Align")
          .fontSize(15)
          .fontColor("#333333")
          .margin({left:15})
         Checkbox()
           .width(30)
           .height(30)
           .margin({left:5})
           .select(this.withByteAlign)
           .onChange((isChecked:boolean) => {
            this.onWithByteAlignCheckChanged(isChecked)
           })
      }.width('100%').height(40)

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
      .height(200)

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
          .width(80)
          .height(40)
          .margin({left:10})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onStartBtnTouch()
          })
        Button("Stop")
          .width(80)
          .height(40)
          .margin({left:10})
          .fontSize(16)
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
    this.manager = SFWatchfaceFilePushManager.getInstance();
    this.manager.init(this.getUIContext().getHostContext()!);
    this.callbackImpl = new PushWatchfaceCallbackImpl(this);
    this.manager.setCallback(this.callbackImpl);
  }
  onPageShow(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>; // 获取传递过来的参数对象
    if (params) {
      const info: string = params.mac as string; // 获取info属性的值
      SFLog.i(TAG,"select device:" + info);
      this.selectedMac = info;
    }
  }

  private async onSelectFileBtnTouch(): Promise<void> {
    SFLog.i(TAG, "onSelectFileBtnTouch");
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();

      const result = await documentPicker.select(documentSelectOptions);
      if (result && result.length > 0) {
        const selPath = result[0]; // 返回第一个选中文件的URI
        SFLog.i(TAG,"selpath=" + selPath);
        this.selectFileName = SFFileUtil.getFileName(selPath);
        this.selectFilePath = await SFTransmitFileUtil.transmitFile(selPath,this.getUIContext().getHostContext()!)
        
        SFLog.i(TAG,`selectFilePath=${this.selectFilePath}`);
      }

    } catch (err) {
      SFLog.e(TAG, 'File picker error: ' + JSON.stringify(err));
    }
  }

  private async  onStartBtnTouch(): Promise<void>{
    try{
      SFLog.i(TAG,"onStartBtnTouch");
      if(this.selectFilePath == null){
        this.toast("请先选择文件");
        return;
      }
      this.speedView.clear();
      this.logs.push("推送文件:" + this.selectFilePath);
      this.manager.setUseHighSpeedMode(true);
      await this.manager.pushWatchfaceFile(this.selectedMac,this.fileType,this.selectFilePath,this.withByteAlign,8 * 1024);
    }catch (e) {
      this.toast("推送文件是比啊" + e.message);
    }

  }

  private  onStopBtnTouch():void{
    SFLog.i(TAG,"onStopBtnTouch");
    this.manager.stop();
  }

  private onWithByteAlignCheckChanged(isChecked:boolean):void{
    this.withByteAlign = isChecked;
  }

  private onFileTypeChanged(value:string){
    this.fileType = Number(value) || 0;
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


}