package com.laoyi.laotie.feature.checkin

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun CheckInScreen(
    viewModel: CheckInViewModel = hiltViewModel()
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("风景打卡")
        Text("已打卡：${state.checkInCount}  连续：${state.streakDays} 天")
        Text(state.lastMessage)
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(state.scenics.take(20)) { scenic ->
                Card {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text("${scenic.name}（${scenic.province}-${scenic.city}）")
                        Text(scenic.highlight)
                        Button(onClick = { viewModel.submitCheckIn(scenic) }) {
                            Text("立即打卡")
                        }
                    }
                }
            }
        }
    }
}
