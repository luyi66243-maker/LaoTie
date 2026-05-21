package com.laoyi.laotie.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = LaoTieRed,
    secondary = LaoTieGold,
    background = LaoTieBg
)

private val DarkColors = darkColorScheme(
    primary = LaoTieGold,
    secondary = LaoTieRed
)

@Composable
fun LaoTieTheme(content: @Composable () -> Unit) {
    val scheme = if (isSystemInDarkTheme()) DarkColors else LightColors
    MaterialTheme(
        colorScheme = scheme,
        typography = Typography,
        content = content
    )
}
