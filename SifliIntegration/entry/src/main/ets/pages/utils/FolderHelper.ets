/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/10/22
 * description
 */

import fs from '@ohos.file.fs';
import { SFLog } from '@sifli/siflicore';
import { common } from "@kit.AbilityKit";
const TAG = "FolderHelper";
export class FolderHelper{

  //创建ezip 解压后的临时目录
  public static getEZipPngDir(context:common.Context):string | null{

    const cacheDir = context.filesDir;
    const outputDir = `${cacheDir}/ezip_png`;

    try {
      if (!fs.accessSync(outputDir)) {
        fs.mkdirSync(outputDir);
      }

      SFLog.i(TAG, "init success cache dir=" + outputDir);
      return outputDir;
    } catch (error) {
      SFLog.e(TAG, `init cacheFileDir fail: ${error}`);
      return null;
    }
  }

  public static getEZipBinDir(context:common.Context):string | null{

    const cacheDir = context.filesDir;
    const outputDir = `${cacheDir}/ezip_bin`;

    try {
      if (!fs.accessSync(outputDir)) {
        fs.mkdirSync(outputDir);
      }

      SFLog.i(TAG, "init success cache dir=" + outputDir);
      return outputDir;
    } catch (error) {
      SFLog.e(TAG, `init cacheFileDir fail: ${error}`);
      return null;
    }
  }
}