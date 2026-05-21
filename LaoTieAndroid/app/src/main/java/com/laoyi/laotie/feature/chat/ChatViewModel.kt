package com.laoyi.laotie.feature.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.core.ai.AIService
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ChatMessage(
    val role: String,
    val text: String
)

data class ChatState(
    val messages: List<ChatMessage> = emptyList(),
    val sending: Boolean = false
)

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val aiService: AIService
) : ViewModel() {
    private val _state = MutableStateFlow(ChatState())
    val state: StateFlow<ChatState> = _state.asStateFlow()

    fun send(input: String, nickname: String) {
        if (input.isBlank()) return
        viewModelScope.launch {
            _state.value = _state.value.copy(
                sending = true,
                messages = _state.value.messages + ChatMessage("user", input)
            )
            val reply = aiService.sendChat(
                endpoint = "https://example.com/chat",
                userInput = input,
                nickname = nickname.ifBlank { "老铁" }
            )
            _state.value = _state.value.copy(
                sending = false,
                messages = _state.value.messages + ChatMessage("assistant", reply)
            )
        }
    }
}
