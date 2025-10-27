/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/9/23
 * description
 */
class SpeedPoint {
  private timestamp: number;
  private completeBytes: number;

  constructor(timestamp: number, completeBytes: number) {
    this.timestamp = timestamp;
    this.completeBytes = completeBytes;
  }

  public getTimestamp(): number {
    return this.timestamp;
  }

  public getCompleteBytes(): number {
    return this.completeBytes;
  }
}

export class SpeedView {
  private static readonly CURRENT_WINDOW_MS: number = 3000; // 3秒窗口
  private static readonly AVERAGE_WINDOW_MS: number = 60000; // 60秒窗口

  private currentWindow: SpeedPoint[] = [];
  private averageWindow: SpeedPoint[] = [];

  private currentSpeed: number = 0;
  private averageSpeed: number = 0;

  public viewSpeedByCompleteBytes(completeBytes: number): void {
    const now: number = this.timeNow();
    if(completeBytes <= 0){
      return;
    }
    const newPoint: SpeedPoint = new SpeedPoint(now, completeBytes);

    // 更新3秒窗口(瞬时速度)
    this.updateWindow(this.currentWindow, newPoint, SpeedView.CURRENT_WINDOW_MS);
    this.currentSpeed = this.calculateSpeed(this.currentWindow);

    // 更新60秒窗口(平均速度)
    this.updateWindow(this.averageWindow, newPoint, SpeedView.AVERAGE_WINDOW_MS);
    this.averageSpeed = this.calculateSpeed(this.averageWindow);
  }

  private updateWindow(window: SpeedPoint[], newPoint: SpeedPoint, windowSize: number): void {
    window.push(newPoint);

    // 移除超出时间窗口的点
    while (window.length > 0 &&
      (newPoint.getTimestamp() - window[0].getTimestamp()) > windowSize) {
      window.shift();
    }
  }

  private calculateSpeed(window: SpeedPoint[]): number {
    if (window.length < 2) return 0;

    const first: SpeedPoint = window[0];
    const last: SpeedPoint = window[window.length - 1];

    if (!first || !last || first === last) return 0;

    const timeDiff: number = last.getTimestamp() - first.getTimestamp();
    const bytesDiff: number = last.getCompleteBytes() - first.getCompleteBytes();

    return this.getKbPerSec(bytesDiff, timeDiff);
  }

  public clear(): void {
    this.currentWindow = [];
    this.averageWindow = [];
    this.currentSpeed = 0;
    this.averageSpeed = 0;
  }

  public getSpeedText(): string {
    return `瞬时 ${this.currentSpeed.toFixed(1)} KB/s 平均 ${this.averageSpeed.toFixed(1)} KB/s`;
  }

  public getSpeedTextWithBytes(currentBytes: number, totalBytes: number): string {
    const currentM: number = currentBytes / (1024 * 1024);
    const totalM: number = totalBytes / (1024 * 1024);
    return `瞬时 ${this.currentSpeed.toFixed(1)} KB/s 平均 ${this.averageSpeed.toFixed(1)} KB/s ${currentM.toFixed(1)}/${totalM.toFixed(1)}Mb`;
  }

  private getKbPerSec(bytes: number, ms: number): number {
    if (ms === 0) return 0;
    return (bytes / 1024) / (ms / 1000);
  }

  private timeNow(): number {
    return new Date().getTime();
  }

  public getCurrentSpeed(): number {
    return this.currentSpeed;
  }

  public getAverageSpeed(): number {
    return this.averageSpeed;
  }
}
