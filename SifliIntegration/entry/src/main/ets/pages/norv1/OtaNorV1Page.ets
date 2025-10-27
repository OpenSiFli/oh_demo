import { SFLog,SFError, SFFileUtil,SFTransmitFileUtil  } from '@sifli/siflicore'
import picker from '@ohos.file.picker';

import promptAction from '@ohos.promptAction';
import { ArrayList } from '@kit.ArkTS';
import { SpeedView } from '../utils/SpeedView/SpeedView';
import { SFOtaManager,NorImageID,OTAImageFileInfo } from '@sifli/sifliotasdk';
import { ImageFileItem } from '../nand/ImageFileItem';
import { OtaNorV1CallbackImpl } from './OtaNorV1CallbackImpl';
import { NorV1TriggerMode } from '@sifli/sifliotasdk';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG:string = "OtaNorV1Page"
@Entry
@Component
export  struct OtaNorV1Page {
  @State title: string = 'Ota NorV1';
  @State selectedMac: string = ''; // 新增状态变量存储MAC地址
  @State selectCtrlFileName: string = ''; // 控制文件名称
  @State selectCtrlFilePath: string | null = null; // 控制文件路径
  @State imageFiles: ImageFileItem[] = []; // 控制文件路径
  @State imageRspFrq:number = 20;//回复频率
  @State logs: string[] = []; // 使用 Array 替代 ArrayList
  @State progress:number = 0;
  @State speedText:string = "瞬时 0KB/s 平均 0KB/s";
  @State imageTypeItems:MenuElement[] =[];
  @State imageListVisible:boolean = true;
  private manager:SFOtaManager = SFOtaManager.getInstance();
  private speedView:SpeedView = new SpeedView();
  // 定义回调实现类
  private callbackImpl: OtaNorV1CallbackImpl | null = null;
  private currentImageFile:ImageFileItem | null = null;

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
        Button("Select Ctrl File")
          .width(200)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(async () =>{
            await this.onSelectCtrlFileBtnTouch();
          })
        Text(this.selectCtrlFileName ? `${this.selectCtrlFileName}` : '---')
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
        Button("Select Image File")
          .width(200)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(async () =>{
            await this.onSelectImageFileBtnTouch();
          })
      }
      .width('100%')
      .height(40)
      .margin({top:10})

      Row(){
        Text("回复频率")
          .fontSize(15)
          .fontColor("#333333")
          .margin({left:15})
        TextInput({ placeholder: 'Rsp Frq',text:this.imageRspFrq.toString()})
          .type(InputType.Number)  // 限制输入仅限数字
          .fontColor("#333333")
          .fontSize(15)
          .margin({left:10})
          .height(40)
          .width(100)
          .onChange((value:string) => {
            this.onRspFrequencyChanged(value);
          })

      }.width('100%').height(50).margin({top:10})

      Scroll() {
        Column() {
          ForEach(this.imageFiles, (item: ImageFileItem) => {
            Row(){
              Text(item.fileName)
                .fontColor('#333333')
                .fontSize(14)
                .width(150)
                .textAlign(TextAlign.Start)
              Button(item.imageType)
                .bindMenu(this.imageTypeItems)
                .height(25)
                .margin({left:15})
                .fontSize(12)
                .fontWeight(FontWeight.Medium)

                .onClick(async () =>{
                  await this.onSelectTypeBtnTouch(item);
                })
              Button("Remove")

                .height(25)
                .margin({left:10})
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .onClick(async () =>{
                  await this.onRemoveBtnTouch(item);
                })
            }.width('100%').height(30).margin({left:15})
          })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .visibility(this.imageListVisible ? Visibility.Visible : Visibility.Hidden)
      }
      .backgroundColor('#f5f5f5')
      .alignSelf(ItemAlign.Start)
      .width('100%')
      .height(160)



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

        Button("Normal")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onStartBtnTouch()
          })
        Button("Resume")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onResumeBtnTouch()
          })
        Button("Force")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onForceBtnTouch()
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
    this.callbackImpl = new OtaNorV1CallbackImpl(this);
    this.manager.setCallback(this.callbackImpl);
    this.initTypeMenus();
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

  private initTypeMenus(): void {
    this.imageTypeItems = [
      { value: "HCPU 0", action: () => this.onImageTypeMenuTouched(NorImageID.HCPU,"HCPU") },
      { value: "LCPU 1", action: () => this.onImageTypeMenuTouched(NorImageID.LCPU,"LCPU") },
      { value: "PATCH 2", action: () => this.onImageTypeMenuTouched(NorImageID.PATCH,"PATCH") },
      { value: "RES 3", action: () => this.onImageTypeMenuTouched(NorImageID.RES,"RES") },
      { value: "FONT 4", action: () => this.onImageTypeMenuTouched(NorImageID.FONT,"FONT") },
      { value: "EX 5", action: () => this.onImageTypeMenuTouched(NorImageID.EX,"EX") },
      { value: "OTA_MANAGER 6", action: () => this.onImageTypeMenuTouched(NorImageID.OTA_MANAGER,"OTA_MANAGER") },
      { value: "TINY_FONT 7", action: () => this.onImageTypeMenuTouched(NorImageID.TINY_FONT,"TINY_FONT") },
      { value: "BOOT_LOADER 11", action: () => this.onImageTypeMenuTouched(NorImageID.BOOT_LOADER,"BOOT_LOADER") }
    ];
  }

  private onImageTypeMenuTouched(imageId:number,imageType:string){
    if(this.currentImageFile != null){
      this.currentImageFile.imageId = imageId;
      this.currentImageFile.imageType = imageType;
      // this.imageListVisible = false;
      // setTimeout(() => { this.imageListVisible = true; }, 1000);
      this.imageFiles = [...this.imageFiles];
    }
  }

  // private async onSelectResFileBtnTouch(): Promise<void> {
  //   SFLog.i(TAG, "onSelectResFileBtnTouch");
  //   try {
  //     let documentSelectOptions = new picker.DocumentSelectOptions();
  //     let documentPicker = new picker.DocumentViewPicker();
  //
  //     const result = await documentPicker.select(documentSelectOptions);
  //     if (result && result.length > 0) {
  //       const selPath = result[0]; // 返回第一个选中文件的URI
  //       SFLog.i(TAG,"selpath=" + selPath);
  //       this.selectResFileName = SFFileUtil.getFileName(selPath);
  //       this.selectResFilePath = await SFTransmitFileUtil.transmitFile(selPath,this.getUIContext().getHostContext()!)
  //
  //       SFLog.i(TAG,`selectFilePath=${this.selectResFilePath}`);
  //     }
  //
  //   } catch (err) {
  //     SFLog.e(TAG, 'File picker error: ' + err.message);
  //   }
  // }

  private async onSelectCtrlFileBtnTouch(): Promise<void> {
    SFLog.i(TAG, "onSelectCtrlFileBtnTouch");
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();

      const result = await documentPicker.select(documentSelectOptions);
      if (result && result.length > 0) {
        const selPath = result[0]; // 返回第一个选中文件的URI
        SFLog.i(TAG,"selpath=" + selPath);
        this.selectCtrlFileName = SFFileUtil.getFileName(selPath);
        this.selectCtrlFilePath = await SFTransmitFileUtil.transmitFile(selPath,this.getUIContext().getHostContext()!)

        SFLog.i(TAG,`selectCtrlFilePath=${this.selectCtrlFilePath}`);
      }

    } catch (err) {
      SFLog.e(TAG, 'File picker error: ' + err.message);
    }
  }

  private async onSelectImageFileBtnTouch(): Promise<void> {
    SFLog.i(TAG, "onSelectImageFileBtnTouch");
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();

      const result = await documentPicker.select(documentSelectOptions);
      if (result && result.length > 0) {
        for(const  selPath of result){
          SFLog.i(TAG, "selpath=" + selPath);

          const fileName = SFFileUtil.getFileName(selPath);
          const filePath = await SFTransmitFileUtil.transmitFile(selPath, this.getUIContext().getHostContext()!)
          if(filePath == null){
            SFLog.e(TAG,"onSelectImageFileBtnTouch filepath is null");
            return;
          }
          // const imageFile: ImageFileItem = new ImageFileItem(fileName: fileName, filePath: filePath, imageId: -1,imageType:'<Select Type>'
          const imageFile: ImageFileItem = new ImageFileItem(-1,fileName,filePath,'<Select Type>');
          this.imageFiles = this.imageFiles.concat(imageFile);
          SFLog.i(TAG, `onSelectImageFileBtnTouch=${filePath}`);
        }

      }
    } catch (err) {
      SFLog.e(TAG, 'File picker error: ' + err.message);
    }
  }

  private async onRemoveBtnTouch(item:ImageFileItem): Promise<void> {
    SFLog.i(TAG,"onRemoveBtnTouch " + item.fileName);
    const index = this.imageFiles.indexOf(item);
    if(index >= 0){
      this.imageFiles.splice(index,1);
    }

  }

  private async onSelectTypeBtnTouch(item:ImageFileItem): Promise<void> {
    SFLog.i(TAG,"onSelectTypeBtnTouch " + item.fileName);
    this.currentImageFile = item;
  }

  private async  onStartBtnTouch(): Promise<void>{
    try{
      this.speedView.clear();
      if(this.selectCtrlFilePath == null){
        this.toast("请选择控制文件");
        return;
      }
      this.startOtaNorV1WithMode(NorV1TriggerMode.NORMAL);
    }catch (ex){
      this.toast("异常:" + ex.message);
    }

  }

  private onResumeBtnTouch(): void {
    SFLog.i(TAG, "onStopBtnTouch");
    try {
      this.speedView.clear();
      if (this.selectCtrlFilePath == null) {
        this.toast("请选择控制文件");
        return;
      }

      this.startOtaNorV1WithMode(NorV1TriggerMode.RESUME);
    } catch (ex) {
      this.toast("异常:" + ex.message);
    }
  }

  private onForceBtnTouch(): void {
    SFLog.i(TAG, "onForceBtnTouch");
    try {
      this.speedView.clear();
      if (this.selectCtrlFilePath == null) {
        this.toast("请选择控制文件");
        return;
      }

      this.startOtaNorV1WithMode(NorV1TriggerMode.FORCE);
    } catch (ex) {
      this.toast("异常:" + ex.message);
    }
  }

  private startOtaNorV1WithMode(mode: NorV1TriggerMode) {
    const imageFiles = new ArrayList<OTAImageFileInfo>();
    for (const item of this.imageFiles) {
      if (item.imageId < 0) {
        this.toast("请选择Image File Type");
        return;
      }
      const fileInfo = new OTAImageFileInfo(item.filePath, item.imageId);
      imageFiles.add(fileInfo);
    }
    this.addLog("启动ota nor v1...");
    this.manager.startOTANorV1(this.selectedMac, this.selectCtrlFilePath!, imageFiles, mode,
      this.imageRspFrq);
  }

  private  onStopBtnTouch():void{
    SFLog.i(TAG,"onStopBtnTouch");
    this.manager.stop();
  }


  private onRspFrequencyChanged(value:string){
    // this.fileType = Number(value) || 0;
    this.imageRspFrq = Number(value) || 0;
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