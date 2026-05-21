package com.laoyi.laotie.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.data.repository.LearningRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class HomeState(
    val vocabularyCount: Int = 0,
    val dialogueCount: Int = 0,
    val quizLevelCount: Int = 0,
    val memeCount: Int = 0,
    val loading: Boolean = true
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val learningRepository: LearningRepository
) : ViewModel() {
    private val _state = MutableStateFlow(HomeState())
    val state: StateFlow<HomeState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.value = _state.value.copy(loading = true)
            _state.value = HomeState(
                vocabularyCount = learningRepository.vocabularies().size,
                dialogueCount = learningRepository.dialogues().size,
                quizLevelCount = learningRepository.quizzes().size,
                memeCount = learningRepository.memes().size,
                loading = false
            )
        }
    }
}
