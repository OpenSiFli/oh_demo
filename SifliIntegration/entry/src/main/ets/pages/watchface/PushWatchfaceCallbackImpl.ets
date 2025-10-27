/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/9/16
 * description
 */
import { SFError } from '@sifli/siflicore'
import { SFWatchfaceFilePushManagerCallback } from '@sifli/sfwatchfacesdk'
import { PushWatchfacePage } from "./PushWatchfacePage"
export class PushWatchfaceCallbackImpl implements SFWatchfaceFilePushManagerCallback{
  private page:PushWatchfacePage;
  constructor(page:PushWatchfacePage) {
    this.page = page;
  }
  /**
   * @param status 0 空闲，1 连接中,2工作中
   * */
  onManagerStatusChanged(status:number):void{
    this.page.handleStatus(status);
  }


  /**
   * 读取进度
   * @param currentBytes
   * @param totalBytes
   * */
  onProgress(currentBytes:number,totalBytes:number):void{
    this.page.updateProgress(currentBytes,totalBytes);
  }

  /**
   * 任务完成，响应结果
   * @param success 是否成功
   * @param error 如果success为false,则该字段为错误信息
   * */
  onComplete(success:boolean,error:SFError | null):void{
    this.page.onComplete(success,error);
  }
}