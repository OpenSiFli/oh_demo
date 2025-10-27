import { SFFileUtil, SFLog, SFLogLevel, SFLogManager, SFLogManagerCallback } from "@sifli/siflicore";
import { LogManager, Logger, AppenderTypeEnum, FileAppender, Level } from '@pie/log4a';
import hilog from '@ohos.hilog';

/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/10/16
 * description
 */
const TAG ="SFLogReceiver";
export class SFLogReceiver implements  SFLogManagerCallback{
  private static mInstance:SFLogReceiver | null = null;
  private logger: Logger = LogManager.getLogger("L");
  private logDirectory:string | null = null;
  private constructor() {

  }

  onLog(level: number, log: string): void {
    if(level == SFLogLevel.INFO){
      this.logger.info(log);
    }else if(level == SFLogLevel.DEBUG){
      this.logger.debug(log);
    }else if(level == SFLogLevel.WARNING){
      this.logger.warn(log);
    }else if(level == SFLogLevel.ERROR){
      this.logger.error(log);
    }else{
      this.logger.debug(log);
    }
  }

  public static getInstance(){
    if(SFLogReceiver.mInstance == null){
      SFLogReceiver.mInstance = new SFLogReceiver();
    }
    return SFLogReceiver.mInstance;
  }

  public startReceiveLog(context:Context):void{
    const isDebug = hilog.isLoggable(0x0000, 'testTag', hilog.LogLevel.DEBUG);
    SFLog.i(TAG,"startReceiveLog isDebug=" + isDebug);
    const fileDir = context.filesDir;
    const logDir = fileDir + '/log';
    if(!SFFileUtil.isDirectory(logDir)){
      if(!SFFileUtil.createDir(logDir)){
        SFLog.e(TAG,"❌创建日志目录失败，将不会输出日志到文件系统");
         return;
      }
    }else{
      SFLog.i(TAG,"日志目录已经存在")
    }
    this.logDirectory = logDir
    this.logger.removeAppenderByType(AppenderTypeEnum.CONSOLE);
    const dateStr = new Date().toISOString().split('T')[0];
    const logFilePath = logDir + `/log_${dateStr}.txt`;
    const fileAppender = new FileAppender(logFilePath, 'SiFli', Level.ALL);
    // const fileAppender = new FileAppender('/file/log.log',"SF",Level.ALL);
    this.logger.bindAppender<FileAppender>(fileAppender);
    // if (isDebug) {
    //   SFLogManager.getInstance().setLogEnable(true);
    // } else {
    //   SFLogManager.getInstance().setLogEnable(false);
    // }
    SFLog.i(TAG,"will write log to:" + logFilePath);
    SFLogManager.getInstance().setCallback(this);
  }

  public getLogDir():string | null{
    return this.logDirectory;
  }
}