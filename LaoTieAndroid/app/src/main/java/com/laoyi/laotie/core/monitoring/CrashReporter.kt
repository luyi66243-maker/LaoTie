package com.laoyi.laotie.core.monitoring

import android.util.Log
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CrashReporter @Inject constructor() {
    // 预留 Crashlytics/Bugly 接入点，默认 no-op。
    fun log(event: String) {
        Log.d("CrashReporter", event)
    }

    fun recordException(throwable: Throwable) {
        Log.e("CrashReporter", "captured", throwable)
    }
}
