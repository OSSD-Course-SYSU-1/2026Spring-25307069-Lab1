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

#include "AmbientLightNapi.h"
#include "AmbientLightExtractor.h"
#include <hilog/log.h>

#undef LOG_TAG
#define LOG_TAG "AmbientLightNapi"

constexpr uint32_t LOG_PRINT_DOMAIN = 0xFF00;

namespace AmbientLight {

napi_value InitAmbientLightNapi(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "setEnabled", nullptr, NapiSetEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isEnabled", nullptr, NapiIsEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "initialize", nullptr, NapiInitialize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "release", nullptr, NapiRelease, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getColorData", nullptr, NapiGetColorData, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBrightness", nullptr, NapiSetBrightness, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getBrightness", nullptr, NapiGetBrightness, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setUpdateInterval", nullptr, NapiSetUpdateInterval, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSmoothFactor", nullptr, NapiSetSmoothFactor, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

napi_value NapiSetEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = { nullptr };
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    bool enabled = false;
    napi_get_value_bool(env, args[0], &enabled);
    
    AmbientLightExtractor::GetInstance().SetEnabled(enabled);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value NapiIsEnabled(napi_env env, napi_callback_info info) {
    bool enabled = AmbientLightExtractor::GetInstance().IsEnabled();
    
    napi_value result;
    napi_get_boolean(env, enabled, &result);
    return result;
}

napi_value NapiInitialize(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = { nullptr, nullptr };
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t width = 0, height = 0;
    napi_get_value_int32(env, args[0], &width);
    napi_get_value_int32(env, args[1], &height);
    
    AmbientLightExtractor::GetInstance().Initialize(width, height);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value NapiRelease(napi_env env, napi_callback_info info) {
    AmbientLightExtractor::GetInstance().Release();
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value NapiGetColorData(napi_env env, napi_callback_info info) {
    ColorData colorData = AmbientLightExtractor::GetInstance().GetLatestColorData();
    
    napi_value result;
    napi_create_object(env, &result);
    
    // Helper lambda to create color object
    auto createColorObject = [&](const ColorRGB& color) -> napi_value {
        napi_value colorObj;
        napi_create_object(env, &colorObj);
        
        napi_value r, g, b;
        napi_create_int32(env, color.r, &r);
        napi_create_int32(env, color.g, &g);
        napi_create_int32(env, color.b, &b);
        
        napi_set_named_property(env, colorObj, "r", r);
        napi_set_named_property(env, colorObj, "g", g);
        napi_set_named_property(env, colorObj, "b", b);
        
        return colorObj;
    };
    
    napi_set_named_property(env, result, "dominantColor", createColorObject(colorData.dominantColor));
    napi_set_named_property(env, result, "averageColor", createColorObject(colorData.averageColor));
    napi_set_named_property(env, result, "topColor", createColorObject(colorData.topColor));
    napi_set_named_property(env, result, "bottomColor", createColorObject(colorData.bottomColor));
    napi_set_named_property(env, result, "leftColor", createColorObject(colorData.leftColor));
    napi_set_named_property(env, result, "rightColor", createColorObject(colorData.rightColor));
    
    napi_value timestamp;
    napi_create_int64(env, colorData.timestamp, &timestamp);
    napi_set_named_property(env, result, "timestamp", timestamp);
    
    return result;
}

napi_value NapiSetBrightness(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = { nullptr };
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    double brightness = 0.8;
    napi_get_value_double(env, args[0], &brightness);
    
    AmbientLightExtractor::GetInstance().SetBrightness(static_cast<float>(brightness));
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value NapiGetBrightness(napi_env env, napi_callback_info info) {
    float brightness = AmbientLightExtractor::GetInstance().GetBrightness();
    
    napi_value result;
    napi_create_double(env, brightness, &result);
    return result;
}

napi_value NapiSetUpdateInterval(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = { nullptr };
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t interval = 100;
    napi_get_value_int32(env, args[0], &interval);
    
    AmbientLightExtractor::GetInstance().SetUpdateInterval(interval);
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

napi_value NapiSetSmoothFactor(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = { nullptr };
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    double factor = 0.3;
    napi_get_value_double(env, args[0], &factor);
    
    AmbientLightExtractor::GetInstance().SetSmoothFactor(static_cast<float>(factor));
    
    napi_value result;
    napi_get_undefined(env, &result);
    return result;
}

} // namespace AmbientLight
