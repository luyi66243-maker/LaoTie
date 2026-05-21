package com.laoyi.laotie.core.ai

import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

@Singleton
class AIService @Inject constructor(
    private val httpClient: OkHttpClient
) {
    suspend fun sendChat(
        endpoint: String,
        userInput: String,
        nickname: String
    ): String = withContext(Dispatchers.IO) {
        val payload = JSONObject()
            .put("nickname", nickname)
            .put("message", userInput)
            .toString()

        val request = Request.Builder()
            .url(endpoint)
            .post(payload.toRequestBody("application/json".toMediaType()))
            .build()

        httpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) return@withContext "网络繁忙，请稍后再试"
            response.body?.string().orEmpty().ifBlank { "没听清，再唠一句？" }
        }
    }
}
