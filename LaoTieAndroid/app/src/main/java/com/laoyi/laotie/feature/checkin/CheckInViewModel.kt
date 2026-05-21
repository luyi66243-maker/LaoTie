package com.laoyi.laotie.feature.checkin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.core.location.LocationService
import com.laoyi.laotie.core.services.AchievementService
import com.laoyi.laotie.core.services.StreakService
import com.laoyi.laotie.data.model.Scenic
import com.laoyi.laotie.data.repository.CheckInRepository
import com.laoyi.laotie.data.repository.LearningRepository
import com.laoyi.laotie.domain.checkin.Achievement
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

data class CheckInState(
    val scenics: List<Scenic> = emptyList(),
    val checkInCount: Int = 0,
    val streakDays: Int = 0,
    val achievements: List<Achievement> = emptyList(),
    val lastMessage: String = ""
)

@HiltViewModel
class CheckInViewModel @Inject constructor(
    private val learningRepository: LearningRepository,
    private val checkInRepository: CheckInRepository,
    private val locationService: LocationService,
    private val streakService: StreakService,
    private val achievementService: AchievementService
) : ViewModel() {
    private val _state = MutableStateFlow(CheckInState())
    val state: StateFlow<CheckInState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            val scenics = learningRepository.scenics()
            val records = checkInRepository.observeAll().first()
            val count = records.size
            val streak = streakService.calculateStreak(records.map { it.submittedAt })
            _state.value = CheckInState(
                scenics = scenics,
                checkInCount = count,
                streakDays = streak,
                achievements = achievementService.evaluate(count),
                lastMessage = "已加载 ${scenics.size} 个景点"
            )
        }
    }

    fun submitCheckIn(scenic: Scenic) {
        viewModelScope.launch {
            val location = locationService.currentLocation()
            val distance = if (
                scenic.latitude != null &&
                scenic.longitude != null &&
                location != null
            ) {
                locationService.distanceMeters(
                    location.latitude,
                    location.longitude,
                    scenic.latitude,
                    scenic.longitude
                ).toDouble()
            } else {
                null
            }

            checkInRepository.addCheckIn(
                scenicId = scenic.id,
                scenicName = scenic.name,
                province = scenic.province,
                latitude = location?.latitude,
                longitude = location?.longitude,
                distanceMeters = distance
            )
            refresh()
            _state.value = _state.value.copy(
                lastMessage = "打卡成功：${scenic.name}"
            )
        }
    }
}
