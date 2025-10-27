/**
 * @author hecq
 * @email 33912760@qq.com
 * create at 2025/9/28
 * description
 */
@Observed
export class ImageFileItem {
  //文件类型
  imageId: number;
  //文件名称
  fileName: string;
  //文件路径
  filePath: string;
  //文件类型
  imageType: string;

  constructor(imageId: number, fileName: string, filePath: string, imageType: string) {
    this.imageId = imageId;
    this.fileName = fileName;
    this.filePath = filePath;
    this.imageType = imageType;
  }
}