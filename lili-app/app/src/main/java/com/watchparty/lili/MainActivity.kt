package com.watchparty.lili

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.watchparty.lili.ui.screens.JoinScreen
import com.watchparty.lili.ui.screens.WatchScreen
import com.watchparty.lili.ui.theme.DeepNight
import com.watchparty.lili.ui.theme.LiliTheme
import com.watchparty.lili.ui.theme.RosePink
import com.watchparty.lili.ui.theme.WarmWhite
import com.watchparty.lili.viewmodel.Screen
import com.watchparty.lili.viewmodel.WatchViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LiliTheme {
                LiliApp()
            }
        }
    }
}

@Composable
fun LiliApp() {
    val vm: WatchViewModel = viewModel()
    val state by vm.state.collectAsStateWithLifecycle()

    when (state.screen) {
        Screen.Join -> JoinScreen(
            serverUrl = state.serverUrl,
            connectionError = state.connectionError,
            onJoin = { username, url ->
                vm.setUsername(username)
                vm.setServerUrl(url)
                vm.connect()
            },
            onClearError = vm::clearError,
        )

        Screen.Connecting -> ConnectingScreen()

        Screen.Watch -> WatchScreen(
            state = state,
            onPlay = vm::onPlay,
            onPause = vm::onPause,
            onSeek = vm::onSeek,
            onTimeUpdate = vm::onTimeUpdate,
            onClearPendingPlay = vm::clearPendingPlay,
            onClearPendingPause = vm::clearPendingPause,
            onClearPendingSeek = vm::clearPendingSeek,
            onClearNotification = vm::clearNotification,
            onDisconnect = vm::disconnect,
        )
    }
}

@Composable
private fun ConnectingScreen() {
    val bg = Brush.verticalGradient(listOf(Color(0xFF0D0D1A), Color(0xFF1A0F2E)))
    Box(
        modifier = Modifier.fillMaxSize().background(bg),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("💕", fontSize = 48.sp)
            Spacer(Modifier.height(24.dp))
            CircularProgressIndicator(color = RosePink)
            Spacer(Modifier.height(16.dp))
            Text(
                text = "بنوصّل...",
                color = WarmWhite,
                fontSize = 18.sp,
                textAlign = TextAlign.Center,
            )
        }
    }
}
