package com.laoyi.laotie.feature.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun HomeScreen(
    viewModel: HomeViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("唠嗑小馆", style = MaterialTheme.typography.headlineMedium)
        SummaryCard("词汇", state.vocabularyCount)
        SummaryCard("场景对话", state.dialogueCount)
        SummaryCard("闯关关卡", state.quizLevelCount)
        SummaryCard("东北段子", state.memeCount)
        Text(if (state.loading) "加载中..." else "数据已就绪")
    }
}

@Composable
private fun SummaryCard(title: String, value: Int) {
    Card {
        Text(
            text = "$title：$value",
            modifier = Modifier.padding(16.dp)
        )
    }
}
