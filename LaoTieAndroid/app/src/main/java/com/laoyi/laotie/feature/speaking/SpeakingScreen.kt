package com.laoyi.laotie.feature.speaking

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun SpeakingScreen(
    viewModel: SpeakingViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var targetText by rememberSaveable { mutableStateOf("你嘎哈去啊？") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("口语练习")
        OutlinedTextField(
            value = targetText,
            onValueChange = { targetText = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("练习句子") }
        )
        Button(
            onClick = { viewModel.evaluate(targetText) },
            enabled = !state.evaluating
        ) {
            Text(if (state.evaluating) "评测中..." else "开始评测")
        }
        state.lastScore?.let { score ->
            Text("总分：${score.overall}")
            Text("流畅度：${score.fluency}")
            Text("准确度：${score.accuracy}")
            Text("建议：${score.feedback}")
        }
    }
}
