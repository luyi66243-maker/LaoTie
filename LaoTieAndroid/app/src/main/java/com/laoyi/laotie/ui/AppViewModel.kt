package com.laoyi.laotie.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.data.repository.UserPreferenceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

data class AppState(
    val privacyAccepted: Boolean = false,
    val nickname: String = ""
)

@HiltViewModel
class AppViewModel @Inject constructor(
    private val userPreferenceRepository: UserPreferenceRepository
) : ViewModel() {
    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            combine(
                userPreferenceRepository.privacyAccepted,
                userPreferenceRepository.nickname
            ) { accepted, nickname ->
                AppState(
                    privacyAccepted = accepted,
                    nickname = nickname
                )
            }.collect { _state.value = it }
        }
    }

    fun acceptPrivacy() {
        viewModelScope.launch {
            userPreferenceRepository.acceptPrivacy()
        }
    }

    fun saveNickname(value: String) {
        viewModelScope.launch {
            userPreferenceRepository.saveNickname(value.trim())
        }
    }
}
