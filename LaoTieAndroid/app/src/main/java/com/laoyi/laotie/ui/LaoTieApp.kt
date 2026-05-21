package com.laoyi.laotie.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.laoyi.laotie.feature.chat.ChatScreen
import com.laoyi.laotie.feature.checkin.CheckInScreen
import com.laoyi.laotie.feature.home.HomeScreen
import com.laoyi.laotie.feature.learning.DialogueScreen
import com.laoyi.laotie.feature.learning.MemeScreen
import com.laoyi.laotie.feature.learning.QuizScreen
import com.laoyi.laotie.feature.learning.TongueTwisterScreen
import com.laoyi.laotie.feature.learning.VocabularyScreen
import com.laoyi.laotie.feature.leaderboard.LeaderboardScreen
import com.laoyi.laotie.feature.speaking.SpeakingScreen

private data class Dest(val route: String, val title: String)

private val destinations = listOf(
    Dest("home", "首页"),
    Dest("vocabulary", "词汇"),
    Dest("dialogue", "对话"),
    Dest("meme", "段子"),
    Dest("quiz", "闯关"),
    Dest("speaking", "口语"),
    Dest("checkin", "打卡"),
    Dest("leaderboard", "排行"),
    Dest("chat", "AI")
)

@Composable
fun LaoTieApp(
    appViewModel: AppViewModel = hiltViewModel()
) {
    val appState by appViewModel.state.collectAsStateWithLifecycle()
    var nicknameInput by rememberSaveable { mutableStateOf("") }
    val navController = rememberNavController()

    if (!appState.privacyAccepted) {
        PrivacyGate(
            nicknameInput = nicknameInput,
            onNicknameInput = { nicknameInput = it },
            onAccept = {
                appViewModel.saveNickname(nicknameInput)
                appViewModel.acceptPrivacy()
            },
            onDecline = {}
        )
        return
    }

    Scaffold(
        bottomBar = {
            val navBackStackEntry by navController.currentBackStackEntryAsState()
            val currentRoute = navBackStackEntry?.destination?.route
            NavigationBar {
                destinations.forEach { dest ->
                    NavigationBarItem(
                        selected = currentRoute == dest.route,
                        onClick = {
                            navController.navigate(dest.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Text(dest.title.take(1)) },
                        label = { Text(dest.title) }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(innerPadding)
        ) {
            composable("home") { HomeScreen() }
            composable("vocabulary") { VocabularyScreen() }
            composable("dialogue") { DialogueScreen() }
            composable("meme") { MemeScreen() }
            composable("quiz") { QuizScreen() }
            composable("speaking") { SpeakingScreen() }
            composable("checkin") { CheckInScreen() }
            composable("leaderboard") { LeaderboardScreen() }
            composable("chat") { ChatScreen(nickname = appState.nickname.ifBlank { "老铁" }) }
            composable("tongue_twister") { TongueTwisterScreen() }
        }
    }
}

@Composable
private fun PrivacyGate(
    nicknameInput: String,
    onNicknameInput: (String) -> Unit,
    onAccept: () -> Unit,
    onDecline: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "隐私保护说明",
            style = MaterialTheme.typography.headlineSmall
        )
        Text("我们仅在需要时请求录音、定位、相机权限，用于口语练习与风景打卡。")
        OutlinedTextField(
            value = nicknameInput,
            onValueChange = onNicknameInput,
            label = { Text("你的昵称（可选）") },
            modifier = Modifier.fillMaxWidth()
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = onDecline) {
                Text("暂不同意")
            }
            Button(onClick = onAccept) {
                Text("同意并继续")
            }
        }
    }
}
