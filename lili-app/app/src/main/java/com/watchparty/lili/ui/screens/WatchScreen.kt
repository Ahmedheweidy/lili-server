package com.watchparty.lili.ui.screens

import android.view.ViewGroup
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.watchparty.lili.ui.theme.*
import com.watchparty.lili.viewmodel.WatchState
import kotlinx.coroutines.delay
import java.util.concurrent.atomic.AtomicBoolean

@Composable
fun WatchScreen(
    state: WatchState,
    onPlay: (Double) -> Unit,
    onPause: (Double) -> Unit,
    onSeek: (Double) -> Unit,
    onTimeUpdate: (Double, Boolean) -> Unit,
    onClearPendingPlay: () -> Unit,
    onClearPendingPause: () -> Unit,
    onClearPendingSeek: () -> Unit,
    onClearNotification: () -> Unit,
    onDisconnect: () -> Unit,
) {
    val context = LocalContext.current
    var videoUrl by remember { mutableStateOf("") }

    // AtomicBoolean for thread-safe flag between coroutine and ExoPlayer listener thread
    val isRemoteEvent = remember { AtomicBoolean(false) }

    val exoPlayer = remember {
        ExoPlayer.Builder(context).build().apply {
            addListener(object : Player.Listener {
                // Only fires for user-initiated play/pause, not buffering
                override fun onPlayWhenReadyChanged(playWhenReady: Boolean, reason: Int) {
                    if (isRemoteEvent.get()) return
                    if (reason != Player.PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST) return
                    val pos = currentPosition / 1000.0
                    if (playWhenReady) onPlay(pos) else onPause(pos)
                }

                override fun onPositionDiscontinuity(
                    oldPos: Player.PositionInfo,
                    newPos: Player.PositionInfo,
                    reason: Int,
                ) {
                    if (isRemoteEvent.get()) return
                    if (reason == Player.DISCONTINUITY_REASON_SEEK) {
                        onSeek(newPos.positionMs / 1000.0)
                    }
                }
            })
        }
    }

    // Periodic time update every 5 seconds
    LaunchedEffect(exoPlayer) {
        while (true) {
            delay(5_000)
            onTimeUpdate(exoPlayer.currentPosition / 1000.0, exoPlayer.isPlaying)
        }
    }

    // Apply remote play command
    LaunchedEffect(state.pendingPlay) {
        state.pendingPlay?.let { time ->
            isRemoteEvent.set(true)
            exoPlayer.seekTo((time * 1000).toLong())
            exoPlayer.play()
            onClearPendingPlay()
            delay(300)
            isRemoteEvent.set(false)
        }
    }

    // Apply remote pause command
    LaunchedEffect(state.pendingPause) {
        state.pendingPause?.let { time ->
            isRemoteEvent.set(true)
            exoPlayer.seekTo((time * 1000).toLong())
            exoPlayer.pause()
            onClearPendingPause()
            delay(300)
            isRemoteEvent.set(false)
        }
    }

    // Apply remote seek command
    LaunchedEffect(state.pendingSeek) {
        state.pendingSeek?.let { time ->
            isRemoteEvent.set(true)
            exoPlayer.seekTo((time * 1000).toLong())
            onClearPendingSeek()
            delay(300)
            isRemoteEvent.set(false)
        }
    }

    // Auto-dismiss notification after 3 seconds
    LaunchedEffect(state.notification) {
        if (state.notification != null) {
            delay(3_000)
            onClearNotification()
        }
    }

    DisposableEffect(Unit) {
        onDispose { exoPlayer.release() }
    }

    Column(
        modifier = Modifier.fillMaxSize().background(DeepNight),
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "💕 Lili Watch",
                color = RosePink,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                modifier = Modifier.weight(1f),
            )
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box(
                    Modifier
                        .size(8.dp)
                        .background(Color(0xFF4CAF50), CircleShape)
                )
                Text("متصل", color = DimWhite, fontSize = 13.sp)
            }
        }

        // Video player
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .background(Color.Black),
        ) {
            AndroidView(
                factory = { ctx ->
                    PlayerView(ctx).apply {
                        player = exoPlayer
                        layoutParams = ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT,
                        )
                        useController = true
                    }
                },
                modifier = Modifier.fillMaxSize(),
            )

            // Sync notification toast
            AnimatedVisibility(
                visible = state.notification != null,
                enter = fadeIn() + slideInVertically(),
                exit = fadeOut() + slideOutVertically(),
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 8.dp),
            ) {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = Color(0xCC1A0F2E),
                ) {
                    Text(
                        text = state.notification ?: "",
                        color = WarmWhite,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        fontSize = 14.sp,
                    )
                }
            }
        }

        // Controls below the player
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Video URL input
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = videoUrl,
                    onValueChange = { videoUrl = it },
                    label = { Text("رابط الفيديو أو M3U8") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = RosePink,
                        unfocusedBorderColor = Color(0xFF3A2A4A),
                        focusedLabelColor = RosePink,
                        cursorColor = RosePink,
                        focusedTextColor = WarmWhite,
                        unfocusedTextColor = WarmWhite,
                    ),
                )
                Button(
                    onClick = {
                        if (videoUrl.isNotBlank()) {
                            exoPlayer.apply {
                                setMediaItem(MediaItem.fromUri(videoUrl))
                                prepare()
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = RosePink),
                    shape = RoundedCornerShape(12.dp),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 14.dp),
                ) {
                    Text("تشغيل", color = Color.White, fontWeight = FontWeight.Bold)
                }
            }

            // Connected users chip
            if (state.connectedUsers.isNotEmpty()) {
                Card(
                    colors = CardDefaults.cardColors(containerColor = CardBg),
                    shape = RoundedCornerShape(14.dp),
                ) {
                    Row(
                        modifier = Modifier.padding(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text("👥", fontSize = 16.sp)
                        Text(
                            text = state.connectedUsers.joinToString(" • "),
                            color = SoftLavender,
                            fontSize = 14.sp,
                        )
                    }
                }
            }

            // Disconnect
            TextButton(
                onClick = onDisconnect,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            ) {
                Text("قطع الاتصال", color = Color(0xFFFF6B6B))
            }
        }
    }
}
