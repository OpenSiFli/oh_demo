/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/9/28
 * description
 */
import { SFError } from "@sifli/siflicore";
import { ISFOtaV3ManagerCallback } from "@sifli/sifliotasdk";
import { OtaV3Page } from "./OtaV3Page";

export class OtaV3CallbackImpl implements ISFOtaV3ManagerCallback{
  private page:OtaV3Page;
  constructor(page:OtaV3Page) {
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
  onProgress(currentBytes: number, totalBytes: number): void{
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