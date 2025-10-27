/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/9/28
 * description
 */
import { SFError } from "@sifli/siflicore";
import { ISFOtaManagerCallback, SFOTAProgressStage } from "@sifli/sifliotasdk";
import { OtaNandPage } from "./OtaNandPage";

export class OtaNandCallbackImpl implements ISFOtaManagerCallback{
  private page:OtaNandPage;
  constructor(page:OtaNandPage) {
    this.page = page;
  }
  /**
   * 0 空闲；1 连接中；2 工作中
   * */
  onManagerStatusChanged(status: number): void{
    this.page.handleStatus(status);
  }

  /**
   * 读取进度
   * @param currentBytes
   * @param totalBytes
   * @param stage @see SFOTAProgressStage 进度阶段
   * */
  onProgress(stage: SFOTAProgressStage, currentBytes: number, totalBytes: number): void{
    this.page.updateProgress(currentBytes,totalBytes);
  }

  /**
   * 任务完成，响应结果
   * @param success 是否成功
   * @param error 如果success为false,则该字段为错误信息
   * */
  onComplete(success: boolean, error: SFError | null): void{
    this.page.onComplete(success,error);
  }
}