package com.laoyi.laotie.core.map

import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MapService @Inject constructor() {
    // 预留地图 SDK 适配层：
    // - cn flavor: 接入高德地图 Android SDK
    // - gp flavor: 接入 Google Maps SDK
    fun mapProviderName(useGmsMap: Boolean): String {
        return if (useGmsMap) "GoogleMaps" else "Amap"
    }
}
