package com.laoyi.laotie.data.repository

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.userPrefs by preferencesDataStore(name = "user_prefs")

@Singleton
class UserPreferenceRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val nickname: Preferences.Key<String> = stringPreferencesKey("nickname")
        val privacyAccepted: Preferences.Key<Boolean> = booleanPreferencesKey("privacy_accepted")
    }

    val nickname: Flow<String> = context.userPrefs.data.map { prefs ->
        prefs[Keys.nickname].orEmpty()
    }

    val privacyAccepted: Flow<Boolean> = context.userPrefs.data.map { prefs ->
        prefs[Keys.privacyAccepted] ?: false
    }

    suspend fun saveNickname(value: String) {
        context.userPrefs.edit { prefs ->
            prefs[Keys.nickname] = value
        }
    }

    suspend fun acceptPrivacy() {
        context.userPrefs.edit { prefs ->
            prefs[Keys.privacyAccepted] = true
        }
    }
}
