/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

#ifndef AMBIENT_LIGHT_NAPI_H
#define AMBIENT_LIGHT_NAPI_H

#include <napi/native_api.h>

namespace AmbientLight {

// NAPI module initialization
napi_value InitAmbientLightNapi(napi_env env, napi_value exports);

// NAPI methods
napi_value NapiSetEnabled(napi_env env, napi_callback_info info);
napi_value NapiIsEnabled(napi_env env, napi_callback_info info);
napi_value NapiInitialize(napi_env env, napi_callback_info info);
napi_value NapiRelease(napi_env env, napi_callback_info info);
napi_value NapiGetColorData(napi_env env, napi_callback_info info);
napi_value NapiSetBrightness(napi_env env, napi_callback_info info);
napi_value NapiGetBrightness(napi_env env, napi_callback_info info);
napi_value NapiSetUpdateInterval(napi_env env, napi_callback_info info);
napi_value NapiSetSmoothFactor(napi_env env, napi_callback_info info);

} // namespace AmbientLight

#endif // AMBIENT_LIGHT_NAPI_H
