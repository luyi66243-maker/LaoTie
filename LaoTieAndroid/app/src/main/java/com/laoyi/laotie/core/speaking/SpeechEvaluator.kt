package com.laoyi.laotie.core.speaking

import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.delay

data class SpeechScore(
    val overall: Int,
    val fluency: Int,
    val accuracy: Int,
    val feedback: String
)

@Singleton
class SpeechEvaluator @Inject constructor() {
    // 预留讯飞 SDK 接入点；当前先提供可运行的本地评测占位实现。
    suspend fun evaluate(referenceText: String, audioFilePath: String): SpeechScore {
        delay(400)
        val baseline = if (referenceText.isBlank() || audioFilePath.isBlank()) 60 else 82
        return SpeechScore(
            overall = baseline,
            fluency = (baseline - 3).coerceAtLeast(0),
            accuracy = (baseline + 2).coerceAtMost(100),
            feedback = "语速自然，建议把儿化音和卷舌音再加强一点。"
        )
    }
}
