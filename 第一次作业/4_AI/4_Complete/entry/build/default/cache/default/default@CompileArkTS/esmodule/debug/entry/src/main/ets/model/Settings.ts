/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
// 定义一个类，包含所有需要传递的设置项
export class Settings {
    content: string = ''; // 弹幕内容
    fontSize: number = 0; // 字体大小
    fontWeight: FontWeight = FontWeight.Regular; // 字体粗细
    // 构造函数：初始化所有参数
    constructor(content: string, fontSize: number, fontWeight: FontWeight) {
        this.content = content;
        this.fontSize = fontSize;
        this.fontWeight = fontWeight;
    }
}
