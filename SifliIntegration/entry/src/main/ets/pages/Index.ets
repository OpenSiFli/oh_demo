import { ButtonItem } from './ButtonItem';
import { Permissions } from '@ohos.abilityAccessCtrl';
import { ArrayHelper, PermissionHelper } from './Utils'
import prompt from '@system.prompt';
import access from '@ohos.bluetooth.access';
import  { SFLog } from '@sifli/siflicore'
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const  TAG: string = "Index";

@Entry
@Component
struct Index {
  @State title: string = 'SFIntegration'
  @State version: string = '1.0.0'
  @State selectedMac: string = '' // 新增状态变量存储MAC地址

  @State buttonList: Array<ButtonItem> = [
  {
    id: 'SearchDevice',
    text: 'Search Device ',
    onClick: this.onSearchDeviceTouch.bind(this)
  },
  {
    id: 'pushWatchface',
    text: 'Push Watchface',
    onClick: this.pushWatchface.bind(this)
  },
  {
    id: 'otaNand',
    text: 'OTA Nand',
    onClick: this.otaNand.bind(this)
  },
  {
    id: 'otaNorV2',
    text: 'OTA Nor V2',
    onClick: this.otaNorV2.bind(this)
  },
  {
    id: 'otaNorV1',
    text: 'OTA Nor V1',
    onClick: this.otaNorV1.bind(this)
  },
  {
    id: 'eZipTest',
    text: 'eZipTest',
    onClick: this.ezipTest.bind(this)
  },
  {
    id: 'logManage',
    text: '日志管理',
    onClick: this.goLogManage.bind(this)
  }
]

  build() {
    Column() {
      Text(this.title + this.version)
        .width('90%')
        .margin({ top: 20, bottom: 10 })
        .fontSize(18)
        .fontColor('#000000')
        .textAlign(TextAlign.Center)
      // 新增的MAC地址显示区域
      Text(this.selectedMac ? `设备: ${this.selectedMac}` : '未选择设备')
        .width('90%')
        .margin({ top: 20, bottom: 10 })
        .fontSize(16)
        .fontColor(this.selectedMac ? '#000000' : '#999999')
        .textAlign(TextAlign.Center)

      Scroll() {
        Column({ space: 20 }) {
          ForEach(this.buttonList, (item: ButtonItem) => {
            Button(item.text)
              .id(item.id)
              .width('80%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .onClick(item.onClick)
          }, (item: ButtonItem) => item.id)
        }
        .width('100%')
      }
      .width('100%')
      .height('85%')
    }
    .width('100%')
    .height('100%')
  }


  private onSearchDeviceTouch(): void {
    console.log('Push Watchface button clicked')
    this.checkPermissions();
    // 可结合之前BLE写入逻辑实现设备通信
    this.getUIContext()?.getRouter()?.pushUrl({
      url: 'pages/searchdevice/SearchDevicePage',
      params: { fromPage: 'index' }
    });
  }

  onPageShow(): void {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>; // 获取传递过来的参数对象
    if (params) {
      const info: string = params.device as string; // 获取info属性的值
      SFLog.i(TAG,"select device:" + info);
      this.selectedMac = info;
    }
    this.getVersionInfo()
    // SFLogReceiver.getInstance().startReceiveLog(this.getUIContext().getHostContext()!);
  }

  private async  getVersionInfo(): Promise<void> {
    await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .then((bundleInfo) => {
        this.version = `(${bundleInfo.versionName})`;
      }).catch((error: BusinessError) => {
      SFLog.e(TAG,"获取失败: " + error);
    });
  }

  private checkPermissions(): void {
    let permissions: Permissions[] = [
      "ohos.permission.USE_BLUETOOTH",
      "ohos.permission.DISCOVER_BLUETOOTH",
      "ohos.permission.APPROXIMATELY_LOCATION",
      "ohos.permission.LOCATION",
      "ohos.permission.ACCESS_BLUETOOTH",
      "ohos.permission.READ_MEDIA"
    ];
    PermissionHelper.requestPermissions(permissions, results => {
      for (let i = 0; i < permissions.length; i++) {
        if (results[i] != 0) {
          let msg = "permission " + permissions[i] + " not granted!";
          prompt.showToast({ message: msg, duration: 2000 })
          return;
        }
      }

      let result = access.getState();
      console.info("checkPermissions bluetooth.state: " + result);
      if (result == access.BluetoothState.STATE_OFF) {
        prompt.showToast({ message: "please open bluetooth", duration: 300, })
        return;
      }

      // this.onPermissionGranted();
    });
  }

private pushWatchface(): void {
  SFLog.i(TAG,'Push Watchface button clicked')
  // 可结合之前BLE写入逻辑实现设备通信
  this.getUIContext()?.getRouter()?.pushUrl({
    url: 'pages/watchface/PushWatchfacePage',
    params: { fromPage: 'index',mac:this.selectedMac }
  });
}

private otaNand(): void {
  SFLog.i(TAG,'OTA Nand button clicked')
  // 固件升级业务逻辑
  this.getUIContext()?.getRouter()?.pushUrl({
    url: 'pages/nand/OtaNandPage',
    params: { fromPage: 'index',mac:this.selectedMac }
  });
}

private otaNorV2(): void {
  SFLog.i(TAG,'otaNorV2 button clicked')
  // 固件升级业务逻辑
  this.getUIContext()?.getRouter()?.pushUrl({
    url: 'pages/norv2/OtaNorV2Page',
    params: { fromPage: 'index',mac:this.selectedMac }
  });
}

  private otaNorV1(): void {
    SFLog.i(TAG,'otaNorV1  button clicked')
    // 第二版固件升级逻辑
    this.getUIContext()?.getRouter()?.pushUrl({
      url: 'pages/norv1/OtaNorV1Page',
      params: { fromPage: 'index',mac:this.selectedMac }
    });
  }

  private ezipTest(): void {
    SFLog.i(TAG,'ezipTest  button clicked')
    // 第二版固件升级逻辑
    this.getUIContext()?.getRouter()?.pushUrl({
      url: 'pages/ezip/EzipTestPage',
      params: { fromPage: 'index',mac:this.selectedMac }
    });
  }

  private goLogManage(): void {
    SFLog.i(TAG,'goLogManage  button clicked')
    // 第二版固件升级逻辑
    this.getUIContext()?.getRouter()?.pushUrl({
      url: 'pages/log/LogManagePage',
      params: { fromPage: 'index',mac:this.selectedMac }
    });
  }
}