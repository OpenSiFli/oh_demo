/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { GlobalContext } from './GlobalContext';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';

export class ArrayHelper {
  public static add<T>(array: Array<T>, elem: T) {
    array.push(elem);
  }

  public static contains<T>(array: Array<T>, elem: T): boolean {
    return array.indexOf(elem) >= 0;
  }

  public static remove<T>(array: Array<T>, elem: T) {
    let index = array.indexOf(elem);
    if (index >= 0) {
      array.splice(index)
    }
  }

  public static removeIndex<T>(array: Array<T>, index: number) {
    if (index >= 0 && index < array.length) {
      array.splice(index, 1);
    }
  }
}


export class PermissionHelper {
  public static checkPermissions(permissions: Permissions[], callback: (results: number[]) => void) {
    let context: ESObject = GlobalContext.getContext().getValue('context');
    abilityAccessCtrl.createAtManager()
      .requestPermissionsFromUser(context, permissions, (err: BusinessError, results: PermissionRequestResult) => {
        callback(results.authResults)
      });
  }

  public static requestPermissions(permissions: Permissions[], callback: (results: number[]) => void) {
    let context = GlobalContext.getContext().getValue('context') as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, permissions, (err: BusinessError, results: PermissionRequestResult) => {
      console.info("requestPermissionsFromUser result: " + JSON.stringify(results))
      callback(results.authResults);
    });
  }
}

export class TextUtils {
  public static isEmpty(text: string) {
    return text == null || text == undefined || text.length == 0;
  }
}
