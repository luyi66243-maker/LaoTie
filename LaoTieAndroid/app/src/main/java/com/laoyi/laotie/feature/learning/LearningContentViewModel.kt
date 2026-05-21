package com.laoyi.laotie.feature.learning

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.laoyi.laotie.data.model.Dialogue
import com.laoyi.laotie.data.model.Meme
import com.laoyi.laotie.data.model.QuizLevel
import com.laoyi.laotie.data.model.TongueTwister
import com.laoyi.laotie.data.model.Vocabulary
import com.laoyi.laotie.data.repository.LearningRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class LearningContentState(
    val vocabularies: List<Vocabulary> = emptyList(),
    val dialogues: List<Dialogue> = emptyList(),
    val quizzes: List<QuizLevel> = emptyList(),
    val tongueTwisters: List<TongueTwister> = emptyList(),
    val memes: List<Meme> = emptyList(),
    val loading: Boolean = true
)

@HiltViewModel
class LearningContentViewModel @Inject constructor(
    private val learningRepository: LearningRepository
) : ViewModel() {
    private val _state = MutableStateFlow(LearningContentState())
    val state: StateFlow<LearningContentState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            _state.value = LearningContentState(
                vocabularies = learningRepository.vocabularies(),
                dialogues = learningRepository.dialogues(),
                quizzes = learningRepository.quizzes(),
                tongueTwisters = learningRepository.tongueTwisters(),
                memes = learningRepository.memes(),
                loading = false
            )
        }
    }
}
