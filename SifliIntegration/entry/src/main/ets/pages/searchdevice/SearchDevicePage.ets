import { BluetoothDevice } from './BluetoothDevice';
import ble from '@ohos.bluetooth.ble';
import { SFLog } from '@sifli/siflicore';

const  TAG: string = "SearchDevicePage";
@Entry
@Component
struct SearchDevicePage {
  @State devices: Array<BluetoothDevice> = []
  @State isScanning: boolean = false
  @State selectedDevice: string = ''

  // 模拟BLE扫描结果
  private mockDevices:Array<BluetoothDevice> = [
    { mac: 'AA:BB:CC:11:22:33', rssi: -45,name:''},
    { mac: 'DD:EE:FF:44:55:66', rssi: -62,name:'' },
    { mac: '11:22:33:AA:BB:CC', rssi: -78,name:'' }
  ]

  build() {
    Column() {
      // 顶部控制按钮
      Row({ space: 10 }) {
        Button('Scan')
          .width('30%')
          .backgroundColor('#409EFF')
          .onClick(() => this.startScan())

        Button('Sort')
          .width('30%')
          .backgroundColor('#67C23A')
          .onClick(() => this.sortDevices())

        Button('Stop')
          .width('30%')
          .backgroundColor('#F56C6C')
          .onClick(() => this.stopScan())
      }
      .width('100%')
      .padding(10)

      // 设备列表
      List({ space: 10 }) {
        ForEach(this.devices, (item:BluetoothDevice) => {
          ListItem() {
            Column() {
              Text(`Name:${item.name}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
              Text(`MAC: ${item.mac} RSSI: ${item.rssi} dBm`)
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .padding(10)
            .borderRadius(8)
            .backgroundColor(this.selectedDevice === item.mac ? '#EBEEF5' : '#FFFFFF')
            .onClick(() =>{
                this.onSelectedItem(item.mac);
            })
          }
          .onClick(() => {
            this.selectedDevice = item.mac
             this.stopScan()
            // router.back({ data: { deviceMac: item.mac } })
          })
        })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }

  private async startScan(): Promise<void> {
    SFLog.i(TAG,"startScan");
    // this.isScanning = true
    // this.devices = []
    // // 模拟扫描过程
    // setTimeout(() => {
    //   this.devices = this.mockDevices
    // }, 1000)

    if (!this.isScanning) {
      this.isScanning = true;
      this.devices = [];

      ble.on('BLEDeviceFind', (devices: Array<ble.ScanResult>) => {
        devices.forEach(device => {
          if(!this.isExistDevById(device.deviceId)){
            const dev:BluetoothDevice =  {mac:device.deviceId,rssi:device.rssi,name:device.deviceName};
            this.devices = this.devices.concat(dev);
          }
          console.log(`发现设备:ID: ${device.deviceId} 名称: ${device.deviceName || '未知'} RSSI信号强度: ${device.rssi}`);
        });

      });

      let scanOption: ble.ScanOptions = {
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE,
        interval: 0
      };

      try{
        ble.startBLEScan(null, scanOption);
        console.log('扫描启动成功');
      }catch (e){
        console.error("startBLEScan error." + e);
      }
      // 启动BLE扫描
    }
  }


  private stopScan(): void {
    SFLog.i(TAG,"stopScan")
    this.isScanning = false
    ble.stopBLEScan()
  }

  private onSelectedItem(mac:string):void{
    this.selectedDevice = mac
    this.stopScan()
    this.getUIContext()?.getRouter()?.back({
      url:'pages/Index',
      params:{
        device:mac
      }
    });
  }

  private sortDevices(): void {
    this.devices.sort((a, b) => b.rssi - a.rssi)
  }

  private isExistDevById(id: string): boolean {
    return this.devices.some((device: BluetoothDevice) =>
    device.mac === id
    )
  }
}