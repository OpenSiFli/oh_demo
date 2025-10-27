import { SifliEzipUtil } from '@sifli/ezipsdk'
import { SFLog,SFError } from '@sifli/siflicore'
import picker from '@ohos.file.picker';
import  { SFFileUtil,SFTransmitFileUtil } from '@sifli/siflicore'
import { UIContext } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { ArrayList } from '@kit.ArkTS';
import { SpeedView } from '../utils/SpeedView/SpeedView';
import { FolderHelper } from '../utils/FolderHelper';
import { taskpool } from '@kit.ArkTS';


const TAG = "EzipTestPage";
@Entry
@Component
struct EzipTestPage {
  @State title: string = 'eZip Test';
  @State selectedMac: string = ''; // 新增状态变量存储MAC地址
  @State selectFileName: string = ''; // 新增状态变量存储MAC地址
  @State selectFilePath: string | null = null; // 新增状态变量存储MAC地址

  @State logs: string[] = []; // 使用 Array 替代 ArrayList
  @State progress:number = 0;
  @State speedText:string = "瞬时 0KB/s 平均 0KB/s";
  private speedView:SpeedView = new SpeedView();
  // 定义回调实现类

  @State ezipColor: string = 'RGB565';
  @State noAlpha: boolean = false;
  @State noRotation: boolean = true;
  @State boardType: number = 1;
  @State boardTypeText: string = '56x';

  @State ezipColorMenus:MenuElement[] =[];
  @State boardTypeMenus:MenuElement[] =[];
  private imageFiles:ArrayList<string> = new ArrayList<string>();
  private imageDirectory:string | null = null;
  private binDirectory:string | null = null;

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
        Button("eZip Color")
          .width(120)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .bindMenu(this.ezipColorMenus)
        Text(this.ezipColor)
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
        Text("No Alpha")
          .width(150)
          .margin({left:15})
          .fontSize(16)
          .fontColor('#999999')
          .textAlign(TextAlign.Start)
          .height('85%')
         Checkbox()
           .select(this.noAlpha)
           .margin({left:10})
           .width(50)
           .height(30)
           .backgroundColor('#f5f5f5')
      }
      .width('100%')
      .height(40)
      .margin({top:10})

      Row(){
        Text("No Rotation")
          .width(150)
          .margin({left:15})
          .fontSize(16)
          .fontColor('#999999')
          .textAlign(TextAlign.Start)
          .height('85%')
        Checkbox()
          .select(this.noRotation)
          .margin({left:10})
          .width(50)
          .height(30)
          .backgroundColor('#f5f5f5')
      }
      .width('100%')
      .height(40)
      .margin({top:10})

      Row(){
        Button("Board Type")
          .width(120)
          .height(40)
          .margin({left:15})
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .bindMenu(this.boardTypeMenus)
        Text(this.boardTypeText)
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

        Button("PngToEzip")
          .width(120)
          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onStartBtnTouch()
          })

        Button("SeqPngToEzip")
          .width(120)
          .height(40)
          .margin({left:10})
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .onClick(() =>{
            this.onSeqPngToEzipBtnTouch()
          })

      }
      .margin({top:10})
      .width('100%').height(40)

    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear(): void {
    this.initTypeMenus();
  }

  private initTypeMenus(): void {
    this.ezipColorMenus = [
      { value: "RGB565", action: () => this.onEzipColorSelect("RGB565") },
      { value: "RGB565A", action: () => this.onEzipColorSelect("RGB565A") },
      { value: "RGB888", action: () => this.onEzipColorSelect("RGB888") },
      { value: "RGB888A", action: () => this.onEzipColorSelect("RGB888A") },
    ];

    this.boardTypeMenus = [
      { value: "55x", action: () => this.onBoardTypeSelect(0,"55x") },
      { value: "56x", action: () => this.onBoardTypeSelect(1,"56x") },
      { value: "52x", action: () => this.onBoardTypeSelect(2,"52x") }
    ];
  }

  private onEzipColorSelect(ezipColor:string){
    this.ezipColor = ezipColor;
  }
  private onBoardTypeSelect(boardType:number,boardTypeName:string){
    this.boardType = boardType;
    this.boardTypeText = boardTypeName;
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
        await this.initPngFromZipFile();
      }

    } catch (err) {
      SFLog.e(TAG, 'File picker error: ' + JSON.stringify(err));
    }
  }

  private async  initPngFromZipFile(): Promise<void>{
    SFLog.i(TAG,"initPngFromZipFile");
    this.imageDirectory = FolderHelper.getEZipPngDir(this.getUIContext().getHostContext()!);
    if(this.imageDirectory == null)return;
    if(this.selectFilePath == null)return;
    const createDirSuc = SFFileUtil.reCreateDir(this.imageDirectory);
    if(createDirSuc){
      const unzipSuc = await SFFileUtil.unzipFileToDir(this.selectFilePath,this.imageDirectory);
      if(unzipSuc){
        const result = await SFFileUtil.listFilesInDir(this.imageDirectory);
        if(result != null){
          this.imageFiles = result;
          const msg = "图片解压成功,count=" + this.imageFiles.length;
          this.logs = [...this.logs, msg];
          SFLog.i(TAG,msg);
        }else{
          const msg = "获取图片文件失败";
          this.logs = [...this.logs, msg];
          SFLog.e(TAG,msg);
        }
      }else{
        const msg = "解压失败";
        this.logs = [...this.logs, msg];
        SFLog.e(TAG,msg);
      }
    }
  }

  private async  onStartBtnTouch(): Promise<void>{
    try{
      SFLog.i(TAG,"onStartBtnTouch");
      if(this.selectFilePath == null){
        this.toast("请先选择文件");
        return;
      }

      if(this.imageFiles.length == 0){
        this.toast(" image count is 0");
        return;
      }
      this.binDirectory = FolderHelper.getEZipBinDir(this.getUIContext().getHostContext()!);
      if(this.binDirectory == null){
        SFLog.e(TAG,"binDirectory is null");
        return;
      }
     if(SFFileUtil.reCreateDir(this.binDirectory)){
       await this.png2ezipProcess();
     }


    }catch (e) {
      this.toast("pngToEzip fail." + e.message);
    }
  }

  private async  onSeqPngToEzipBtnTouch(): Promise<void>{
    try{
      SFLog.i(TAG,"onSeqPngToEzipBtnTouch");
      if(this.selectFilePath == null){
        this.toast("请先选择文件");
        return;
      }

      if(this.imageFiles.length == 0){
        this.toast(" image count is 0");
        return;
      }
      this.binDirectory = FolderHelper.getEZipBinDir(this.getUIContext().getHostContext()!);
      if(this.binDirectory == null){
        SFLog.e(TAG,"binDirectory is null");
        return;
      }
      if(SFFileUtil.reCreateDir(this.binDirectory)){
        await this.seqEzipProcess();
      }
    }catch (e) {
      this.toast("pngToeEzipSequnce fail." + e.message);
    }
  }

  private async png2ezipProcess(): Promise<void> {
    let completeCount = 0;
    let successCount = 0;
    const noAlphaNum = this.noAlpha ? 1 : 0;
    const noRotationNum = this.noRotation ? 1 : 0;
    const paramMsg = `${this.ezipColor} ${noAlphaNum} ${noRotationNum} ${this.boardType}`;
    this.logs = [...this.logs, paramMsg];
    SFLog.i(TAG,paramMsg);

    for (const imagePath of this.imageFiles) {
      const imageData = await SFFileUtil.getFileData(imagePath);
      if (imageData == null) {
        continue;
      }
      SFLog.d(TAG, `${imagePath},len=${imageData.length}`);
      const filename = SFFileUtil.getFileNameWithoutExtension(imagePath);
      const binPath = this.binDirectory + "/" + filename + ".bin";
      // const result = await EzipTestPage.pngToEzipAsync(imageData, this.ezipColor, noAlphaNum, noRotationNum, this.boardType);
      const result = SifliEzipUtil.pngToEzip(imageData,this.ezipColor,noAlphaNum,noRotationNum,this.boardType);
      completeCount += 1;
      if (result != null) {
        successCount += 1;
        SFLog.d(TAG, "result len=" + result.length);
        const saveSuc = await SFFileUtil.saveData(result, binPath);
        if(saveSuc){
          SFLog.i(TAG,"save success.");
        }else{
          const msg = "save ezip bin fail.";
          SFLog.e(TAG,msg);
          this.logs = [...this.logs, msg];
          break;
        }
      }
      const msg = `complete ${completeCount},suc ${successCount},total ${this.imageFiles.length}`;
      this.speedText = msg;
      if(this.imageFiles.length > 0){
        this.progress = 100 * (completeCount / this.imageFiles.length);
      }
      SFLog.i(TAG, msg);
    }
  }

  private async   seqEzipProcess(): Promise<void> {
    const noAlphaNum = this.noAlpha ? 1 : 0;
    const noRotationNum = this.noRotation ? 1 : 0;
    const paramMsg = `${this.ezipColor} ${noAlphaNum} ${noRotationNum} ${this.boardType}`;
    this.logs = [...this.logs, paramMsg];
    SFLog.i(TAG, paramMsg);
    const seqPngDatas = new ArrayList<Uint8Array>();
    for (const imagePath of this.imageFiles) {
      const imageData = await SFFileUtil.getFileData(imagePath);
      if (imageData == null) {
        continue;
      }
      SFLog.d(TAG, `${imagePath},len=${imageData.length}`);
      seqPngDatas.add(imageData);
    }
    const  result = SifliEzipUtil.pngToEzipSequence(seqPngDatas,this.ezipColor,noAlphaNum,noRotationNum,this.boardType,100);
    const  msg = `pngToEzipSequence done.result len =${result.length}`;
    this.logs = [...this.logs, msg];
    SFLog.i(TAG, msg);
    const binPath = this.binDirectory + "/ezip_seq_result.bin";
    const saveSuc = await SFFileUtil.saveData(result, binPath);
    if(saveSuc){
      SFLog.i(TAG,"save success.");
    }else{
      const msg = "save ezip bin fail.";
      SFLog.e(TAG,msg);
      this.logs = [...this.logs, msg];
    }

  }


  // private static async pngToEzipAsync(imageData: Uint8Array, ezipColor: string, noAlphaNum: number, noRotationNum: number, boardType: number): Promise<Uint8Array | null> {
  //   return new Promise((resolve, reject) => {
  //     try {
  //       // 使用setTimeout将同步操作放入异步队列中执行
  //       setTimeout(() => {
  //         try {
  //           const result = SifliEzipUtil.pngToEzip(imageData, ezipColor, noAlphaNum, noRotationNum, boardType);
  //           resolve(result);
  //         } catch (error) {
  //           SFLog.e(TAG,"pngToEzipAsync error1." + error);
  //           resolve(null);
  //         }
  //       }, 0);
  //     } catch (error) {
  //       SFLog.e(TAG,"pngToEzipAsync error2." + error);
  //       resolve(null);
  //     }
  //   });
  // }

  // 使用鸿蒙的TaskPool实现真异步
  private static async pngToEzipAsync(imageData: Uint8Array, ezipColor: string, noAlphaNum: number, noRotationNum: number, boardType: number): Promise<Uint8Array | null> {
    // const  runner = new taskpool.SequenceRunner();
    // const task = new taskpool.Task()
    return new Promise((resolve) => {
      taskpool.execute(() => {
        try {
          const result = SifliEzipUtil.pngToEzip(imageData, ezipColor, noAlphaNum, noRotationNum, boardType);
          resolve(result);
        } catch (error) {
          SFLog.e(TAG, "pngToEzipAsync error1. " + error);
          resolve(null);
        }
      });
    });
  }


  private  onStopBtnTouch():void{
    SFLog.i(TAG,"onStopBtnTouch");

  }

  private toast(msg:string):void{
    promptAction.showToast({
      message: msg,
      duration: 2000, // 显示时长（毫秒）
      bottom: '50vp' // 距离屏幕底部距离
    });
  }
}