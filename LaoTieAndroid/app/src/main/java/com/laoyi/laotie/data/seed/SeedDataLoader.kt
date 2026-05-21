package com.laoyi.laotie.data.seed

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.serialization.json.Json

@Singleton
class SeedDataLoader @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val json = Json {
        ignoreUnknownKeys = true
    }

    internal inline fun <reified T> loadArray(fileName: String): List<T> {
        return try {
            val path = "seed/$fileName"
            val raw = context.assets.open(path).bufferedReader().use { it.readText() }
            json.decodeFromString(raw)
        } catch (_: Exception) {
            emptyList()
        }
    }
}
