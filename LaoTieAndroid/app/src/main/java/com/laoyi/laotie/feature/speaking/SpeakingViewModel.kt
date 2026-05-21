package com.laoyi.laotie.feature.speaking

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.core.speaking.SpeechEvaluator
import com.laoyi.laotie.core.speaking.SpeechScore
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class SpeakingState(
    val evaluating: Boolean = false,
    val lastScore: SpeechScore? = null
)

@HiltViewModel
class SpeakingViewModel @Inject constructor(
    private val speechEvaluator: SpeechEvaluator
) : ViewModel() {
    private val _state = MutableStateFlow(SpeakingState())
    val state: StateFlow<SpeakingState> = _state.asStateFlow()

    fun evaluate(text: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(evaluating = true)
            val result = speechEvaluator.evaluate(text, "cache/recording.wav")
            _state.value = _state.value.copy(evaluating = false, lastScore = result)
        }
    }
}
