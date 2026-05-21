package com.laoyi.laotie.core.audio

import android.content.Context
import android.net.Uri
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AudioPlayer @Inject constructor(
    @ApplicationContext context: Context
) {
    private val player: ExoPlayer = ExoPlayer.Builder(context).build()

    fun playAsset(path: String) {
        val mediaItem = MediaItem.fromUri(Uri.parse("asset:///$path"))
        player.setMediaItem(mediaItem)
        player.prepare()
        player.playWhenReady = true
    }

    fun stop() {
        player.stop()
    }
}
