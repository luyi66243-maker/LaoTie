package com.laoyi.laotie.feature.learning

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun VocabularyScreen(
    viewModel: LearningContentViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(state.vocabularies.take(120)) { vocab ->
            Card {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text("${vocab.dongbeiWord}  /  ${vocab.standardWord}")
                    Text(vocab.meaning)
                    Text("例句：${vocab.exampleSentence}")
                }
            }
        }
    }
}

@Composable
fun DialogueScreen(
    viewModel: LearningContentViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(state.dialogues) { dialogue ->
            Card {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(dialogue.scenarioTitle)
                    Text(dialogue.scenarioDescription)
                    Text("对话句数：${dialogue.lines.size}")
                }
            }
        }
    }
}

@Composable
fun QuizScreen(
    viewModel: LearningContentViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(state.quizzes) { level ->
            Card {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text("第${level.levelNumber}关：${level.title}")
                    Text(level.subtitle)
                    Text("题数：${level.questions.size}，及格：${level.passingScore}")
                }
            }
        }
    }
}

@Composable
fun TongueTwisterScreen(
    viewModel: LearningContentViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(state.tongueTwisters) { item ->
            Card {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(item.title)
                    Text(item.content)
                }
            }
        }
    }
}

@Composable
fun MemeScreen(
    viewModel: LearningContentViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(state.memes) { item ->
            Card {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(item.phrase)
                    Text(item.meaning)
                    Text("用法：${item.usage}")
                }
            }
        }
    }
}
