import { SFLog,SFError, SFFileUtil,SFTransmitFileUtil, StringUtil  } from '@sifli/siflicore'
import picker from '@ohos.file.picker';
import { OtaV3CallbackImpl } from "./OtaV3CallbackImpl"
import promptAction from '@ohos.promptAction';
import { ArrayList } from '@kit.ArkTS';
import { SpeedView } from '../utils/SpeedView/SpeedView';
import { SFOtaV3Manager,OtaV3ImageID,OtaV3ResourceFileInfo,OtaV3BinFileInfo } from '@sifli/sifliotasdk';

import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ImageFileItem } from '../nand/ImageFileItem';
import { OtaV3DfuFileType } from '@sifli/siflisol2model';


const TAG:string = "OtaV3Page"
@Entry
@Component
export  struct OtaV3Page {
  @State title: string = 'Ota V3';
  @State selectedMac: string = ''; // 新增状态变量存储MAC地址
  @State selectResFileName: string = ''; //差分包名称
  @State selectResFilePath: string | null = null; // 差分包路径
  @State selectCtrlFileName: string = ''; // 控制文件名称
  @State selectCtrlFilePath: string | null = null; // 控制文件路径
  @State imageFiles: ImageFileItem[] = []; // 控制文件路径
  @State imageRspFrq:number = 4;//回复频率
  @State otaV3Type:number = 0;
  @State withByteAlign: boolean = false; // 定义状态变量
  @State logs: string[] = []; // 使用 Array 替代 ArrayList
  @State progress:number = 0;
  @State speedText:string = "瞬时 0KB/s 平均 0KB/s";
  @State imageTypeItems:MenuElement[] =[];
  @State imageListVisible:boolean = true;
  private manager:SFOtaV3Manager = SFOtaV3Manager.getInstance();
  private speedView:SpeedView = new SpeedView();
  // 定义回调实现类
  private callbackImpl: OtaV3CallbackImpl | null = null;
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
        Text("固件")
          .fontSize(14)
          .margin({left:15})
          .fontColor("#666666")

        Button("Start")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onFirmwareStartBtnTouch()
          })
        Button("Resume")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onFirmwareResumeBtnTouch()
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

      Row(){
        Text("资源")
          .fontSize(14)
          .margin({left:15})
          .fontColor("#666666")

        Button("Start")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onResStartBtnTouch()
          })
        Button("Resume")

          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onResResumeBtnTouch()
          })
        TextInput({ placeholder: 'Ota Type',text:this.otaV3Type.toString()})
          .type(InputType.Number)  // 限制输入仅限数字
          .fontColor("#333333")
          .fontSize(14)
          .margin({left:10})
          .height(40)
          .width(60)
          .onChange((value:string) => {
            this.onOtaV3TypeChanged(value);
          })
        Text("Align")
          .fontSize(14)
          .fontColor("#333333")
          .margin({left:5})
        Checkbox()
          .width(30)
          .height(30)
          .margin({left:5})
          .select(this.withByteAlign)
          .onChange((isChecked:boolean) => {
            this.onWithByteAlignCheckChanged(isChecked)
          })
      }
      .margin({top:10})
      .width('100%').height(40)

    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear(): void {
    this.manager = SFOtaV3Manager.getInstance();
    this.manager.init(this.getUIContext().getHostContext()!);
    this.callbackImpl = new OtaV3CallbackImpl(this);
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
      { value: "HCPU 0", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.HCPU,"HCPU") },
      { value: "LCPU 1", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.LCPU,"LCPU") },
      { value: "LCPU_PATCH 2", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.LCPU_PATCH,"LCPU_PATCH") },
      { value: "NOR_RES 3", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_RES,"NOR_RES") },
      { value: "NOR_FONT 4", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_FONT,"NOR_FONT") },
      { value: "NOR_ROOT 5", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_ROOT,"NOR_ROOT") },
      { value: "NOR_OTA_MANAGER 6", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_OTA_MANAGER,"NOR_OTA_MANAGER") },
      { value: "NOR_TINY_FONT 7", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_TINY_FONT,"NOR_TINY_FONT") },
      { value: "NOR_FTAB 8", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_FTAB,"NOR_FTAB") },
      { value: "NOR_BOOTLOADER 9", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NOR_BOOTLOADER,"NOR_BOOTLOADER") },
      { value: "NAND_PIC 3", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_PIC,"NAND_PIC") },
      { value: "NAND_FONT 4", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_FONT,"NAND_FONT") },
      { value: "NAND_LANG 5", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_LANG,"NAND_LANG") },
      { value: "NAND_RING 6", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_RING,"NAND_RING") },
      { value: "NAND_ROOT 7", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_ROOT,"NAND_ROOT") },
      { value: "NAND_MUSIC 8", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_MUSIC,"NAND_MUSIC") },
      { value: "NAND_DYN 9", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_DYN,"NAND_DYN") },
      { value: "NAND_NYM 10", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_NYM,"NAND_NYM") },
      { value: "NAND_FTAB 11", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_FTAB,"NAND_FTAB") },
      { value: "NAND_IMG_UPDATE 12", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_IMG_UPDATE,"NAND_IMG_UPDATE") },
      { value: "NAND_BOOTLOADER 13", action: () => this.onImageTypeMenuTouched(OtaV3ImageID.NAND_BOOTLOADER,"NAND_BOOTLOADER") },
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

  private async  onFirmwareStartBtnTouch(): Promise<void>{
    // try{
    //   this.speedView.clear();
    //   const  imageFiles = new ArrayList<OTAImageFileInfo>();
    //   for (const  item of this.imageFiles) {
    //     if(item.imageId < 0){
    //       this.toast("请选择Image File Type");
    //       return;
    //     }
    //     const  fileInfo = new OTAImageFileInfo(item.filePath,item.imageId);
    //     imageFiles.add(fileInfo);
    //   }
    //   this.addLog("启动ota v3 firmware...");
    //   // this.manager.startOTANand(this.selectedMac,this.selectResFilePath,this.selectCtrlFilePath,imageFiles,false,this.imageRspFrq);
    // }catch (ex){
    //   this.toast("异常:" + ex.message);
    // }

    try{
      this.speedView.clear();
      this.addLog("启动ota onFirmwareStartBtnTouch...");
      let  resourceFileInfo :OtaV3ResourceFileInfo | null = null;
      if(!StringUtil.isNullOrEmpty(this.selectResFilePath)){
        resourceFileInfo = new OtaV3ResourceFileInfo(OtaV3DfuFileType.ZIP_RESOURCE,this.selectResFilePath!,true);
      }

      const  binFileInfos = new ArrayList<OtaV3BinFileInfo>();
      let ctrlFile:OtaV3BinFileInfo | null = null;
      if(!StringUtil.isNullOrEmpty(this.selectCtrlFilePath)){
        ctrlFile = new OtaV3BinFileInfo(OtaV3DfuFileType.OTA_CTRL_FILE,this.selectCtrlFilePath!,-1);
        binFileInfos.add(ctrlFile);
      }
      for (const  item of this.imageFiles) {
        if(item.imageId < 0){
          this.toast("请选择Image File Type");
          return;
        }
        // if(!this.isValidHexOffset(item.getHexOffset())){
        //   toast(item.getFileName() + "的偏移无效");
        //   return;
        // }
        const  binFileInfo = new OtaV3BinFileInfo(OtaV3DfuFileType.OTA_BIN_FILE,item.filePath,item.imageId, null);
        binFileInfos.add(binFileInfo);
      }

      this.manager.startOtaV3ForFirmware(this.selectedMac,resourceFileInfo,binFileInfos,false);
    }catch ( ex){

      this.toast("异常:" + ex.getMessage());
    }

  }

  private async  onResStartBtnTouch(): Promise<void>{
    try{
      this.speedView.clear();
      const  resourceFileInfo = new OtaV3ResourceFileInfo(OtaV3DfuFileType.ZIP_RESOURCE,this.selectResFilePath!,this.withByteAlign);
      this.addLog("启动ota v3 push res..." + this.otaV3Type);
      this.manager.startOtaV3ForResource(this.selectedMac, this.otaV3Type,resourceFileInfo,false);
    }catch ( ex){
      this.toast("异常:" + ex.getMessage());
    }
  }

  private  onFirmwareResumeBtnTouch():void{
    SFLog.i(TAG,"onFirmwareResumeBtnTouch");
    try{
      this.speedView.clear();
      this.addLog("启动ota onFirmwareStartBtnTouch...");
      let  resourceFileInfo :OtaV3ResourceFileInfo | null = null;
      if(!StringUtil.isNullOrEmpty(this.selectResFilePath)){
        resourceFileInfo = new OtaV3ResourceFileInfo(OtaV3DfuFileType.ZIP_RESOURCE,this.selectResFilePath!,true);
      }

      const  binFileInfos = new ArrayList<OtaV3BinFileInfo>();
      let ctrlFile:OtaV3BinFileInfo | null = null;
      if(!StringUtil.isNullOrEmpty(this.selectCtrlFilePath)){
        ctrlFile = new OtaV3BinFileInfo(OtaV3DfuFileType.OTA_CTRL_FILE,this.selectCtrlFilePath!,-1);
        binFileInfos.add(ctrlFile);
      }
      for (const  item of this.imageFiles) {
        if(item.imageId < 0){
          this.toast("请选择Image File Type");
          return;
        }
        // if(!this.isValidHexOffset(item.getHexOffset())){
        //   toast(item.getFileName() + "的偏移无效");
        //   return;
        // }
        const  binFileInfo = new OtaV3BinFileInfo(OtaV3DfuFileType.OTA_BIN_FILE,item.filePath,item.imageId, null);
        binFileInfos.add(binFileInfo);
      }
      this.manager.startOtaV3ForFirmware(this.selectedMac,resourceFileInfo,binFileInfos,true);
    }catch ( ex){
      this.toast("异常:" + ex.getMessage());
    }
  }

  private  onResResumeBtnTouch():void{
    SFLog.i(TAG,"onResResumeBtnTouch");
    try{
      this.speedView.clear();
      const  resourceFileInfo = new OtaV3ResourceFileInfo(OtaV3DfuFileType.ZIP_RESOURCE,this.selectResFilePath!,this.withByteAlign);
      this.addLog("启动ota v3 push res..." + this.otaV3Type);
      this.manager.startOtaV3ForResource(this.selectedMac, this.otaV3Type,resourceFileInfo,true);
    }catch ( ex){
      this.toast("异常:" + ex.getMessage());
    }
  }

  private  onStopBtnTouch():void{
    SFLog.i(TAG,"onStopBtnTouch");
    this.manager.stop();
  }

  private onOtaV3TypeChanged(value:string){
    // this.fileType = Number(value) || 0;
    this.otaV3Type = Number(value) || 0;
  }

  private onWithByteAlignCheckChanged(isChecked:boolean):void{
    this.withByteAlign = isChecked;
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