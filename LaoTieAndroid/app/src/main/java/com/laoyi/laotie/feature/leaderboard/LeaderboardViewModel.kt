package com.laoyi.laotie.feature.leaderboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.data.repository.CheckInRepository
import com.laoyi.laotie.data.repository.UserPreferenceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

data class LeaderboardItem(
    val nickname: String,
    val checkInCount: Int,
    val totalXp: Int
)

@HiltViewModel
class LeaderboardViewModel @Inject constructor(
    checkInRepository: CheckInRepository,
    userPreferenceRepository: UserPreferenceRepository
) : ViewModel() {
    private val _items = MutableStateFlow<List<LeaderboardItem>>(emptyList())
    val items: StateFlow<List<LeaderboardItem>> = _items.asStateFlow()

    init {
        viewModelScope.launch {
            combine(
                userPreferenceRepository.nickname,
                checkInRepository.observeAll()
            ) { nickname, records ->
                listOf(
                    LeaderboardItem(
                        nickname = nickname.ifBlank { "老铁用户" },
                        checkInCount = records.size,
                        totalXp = records.sumOf { it.rewardXp }
                    )
                )
            }.collect { _items.value = it }
        }
    }
}
