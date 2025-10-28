import { SFLog,SFError, SFFileUtil,SFTransmitFileUtil  } from '@sifli/siflicore'
import picker from '@ohos.file.picker';
import { OtaNandCallbackImpl } from "./OtaNandCallbackImpl"
import promptAction from '@ohos.promptAction';
import { ArrayList } from '@kit.ArkTS';
import { SpeedView } from '../utils/SpeedView/SpeedView';
import { SFOtaManager,NandImageID,OTAImageFileInfo, SFOTAProgressStage } from '@sifli/sifliotasdk';
import { ImageFileItem } from './ImageFileItem';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';


const TAG:string = "OtaNandPage"
@Entry
@Component
export  struct OtaNandPage {
  @State title: string = 'Ota Nand';
  @State selectedMac: string = ''; // 新增状态变量存储MAC地址
  @State selectResFileName: string = ''; //差分包名称
  @State selectResFilePath: string | null = null; // 差分包路径
  @State selectCtrlFileName: string = ''; // 控制文件名称
  @State selectCtrlFilePath: string | null = null; // 控制文件路径
  @State imageFiles: ImageFileItem[] = []; // 控制文件路径
  @State imageRspFrq:number = 4;//回复频率
  @State logs: string[] = []; // 使用 Array 替代 ArrayList
  @State progress:number = 0;
  @State speedText:string = "瞬时 0KB/s 平均 0KB/s";
  @State imageTypeItems:MenuElement[] =[];
  @State imageListVisible:boolean = true;
  private manager:SFOtaManager = SFOtaManager.getInstance();
  private speedView:SpeedView = new SpeedView();
  // 定义回调实现类
  private callbackImpl: OtaNandCallbackImpl | null = null;
  private currentImageFile:ImageFileItem | null = null;
  private progressStage:SFOTAProgressStage = SFOTAProgressStage.NAND_RES;

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
        Button("Select Res File")
          .width(200)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(async () =>{
            await this.onSelectResFileBtnTouch();
          })
        Text(this.selectResFileName ? `${this.selectResFileName}` : '---')
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

        Button("Start")

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
    this.callbackImpl = new OtaNandCallbackImpl(this);
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
      { value: "HCPU", action: () => this.onImageTypeMenuTouched(NandImageID.HCPU,"HCPU") },
      { value: "LCPU", action: () => this.onImageTypeMenuTouched(NandImageID.LCPU,"LCPU") },
      { value: "PATCH", action: () => this.onImageTypeMenuTouched(NandImageID.PATCH,"PATCH") },
      { value: "FS_ROOT", action: () => this.onImageTypeMenuTouched(NandImageID.RES,"FS_ROOT") },
      { value: "LCPU_PATCH", action: () => this.onImageTypeMenuTouched(NandImageID.LCPU_PATCH,"LCPU_PATCH") },
      { value: "DYN", action: () => this.onImageTypeMenuTouched(NandImageID.DYN,"DYN") },
      { value: "MUSIC", action: () => this.onImageTypeMenuTouched(NandImageID.MUSIC,"MUSIC") },
      { value: "PIC", action: () => this.onImageTypeMenuTouched(NandImageID.PIC,"PIC") },
      { value: "FONT", action: () => this.onImageTypeMenuTouched(NandImageID.FONT,"FONT") },
      { value: "RING", action: () => this.onImageTypeMenuTouched(NandImageID.RING,"RING") },
      { value: "LANG", action: () => this.onImageTypeMenuTouched(NandImageID.LANG,"LANG") }
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

  private async onSelectResFileBtnTouch(): Promise<void> {
    SFLog.i(TAG, "onSelectResFileBtnTouch");
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker();

      const result = await documentPicker.select(documentSelectOptions);
      if (result && result.length > 0) {
        const selPath = result[0]; // 返回第一个选中文件的URI
        SFLog.i(TAG,"selpath=" + selPath);
        this.selectResFileName = SFFileUtil.getFileName(selPath);
        this.selectResFilePath = await SFTransmitFileUtil.transmitFile(selPath,this.getUIContext().getHostContext()!)

        SFLog.i(TAG,`selectFilePath=${this.selectResFilePath}`);
      }

    } catch (err) {
      SFLog.e(TAG, 'File picker error: ' + err.message);
    }
  }

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


      const  imageFiles = new ArrayList<OTAImageFileInfo>();
      for (const  item of this.imageFiles) {
        if(item.imageId < 0){
          this.toast("请选择Image File Type");
          return;
        }
        const  fileInfo = new OTAImageFileInfo(item.filePath,item.imageId);
        imageFiles.add(fileInfo);
      }
      this.addLog("启动ota nand...");
      this.manager.startOTANand(this.selectedMac,this.selectResFilePath,this.selectCtrlFilePath,imageFiles,false,this.imageRspFrq);
    }catch (ex){
      this.toast("异常:" + ex.message);
    }

  }

  private  onResumeBtnTouch():void{
    SFLog.i(TAG,"onStopBtnTouch");
    try{
      this.speedView.clear();


      const  imageFiles = new ArrayList<OTAImageFileInfo>();
      for (const  item of this.imageFiles) {
        if(item.imageId < 0){
          this.toast("请选择Image File Type");
          return;
        }
        const  fileInfo = new OTAImageFileInfo(item.filePath,item.imageId);
        imageFiles.add(fileInfo);
      }
      this.addLog("启动ota nand...");
      this.manager.startOTANand(this.selectedMac,this.selectResFilePath,this.selectCtrlFilePath,imageFiles,true,this.imageRspFrq);
    }catch (ex){
      this.toast("异常:" + ex.message);
    }
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

  public updateProgress(stage: SFOTAProgressStage,current: number, total: number): void {
    // this.progress = (current / total * 100).toFixed(2);
    SFLog.i(TAG, `progress ${current}/${total}}`);
    if(stage != this.progressStage){
      this.speedView.clear();
      this.progressStage = stage;
    }
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