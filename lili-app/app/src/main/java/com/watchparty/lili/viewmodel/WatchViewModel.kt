package com.watchparty.lili.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.watchparty.lili.network.SocketManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class WatchState(
    val screen: Screen = Screen.Join,
    val username: String = "",
    val serverUrl: String = "http://192.168.1.1:3000",
    val roomId: String = "lili-room",
    val connectedUsers: List<String> = emptyList(),
    val isPlaying: Boolean = false,
    val notification: String? = null,
    val connectionError: Boolean = false,
    // Pending remote commands for the player
    val pendingPlay: Double? = null,
    val pendingPause: Double? = null,
    val pendingSeek: Double? = null,
)

enum class Screen { Join, Connecting, Watch }

class WatchViewModel(application: Application) : AndroidViewModel(application) {
    private val socket = SocketManager()

    private val _state = MutableStateFlow(WatchState())
    val state: StateFlow<WatchState> = _state.asStateFlow()

    fun setUsername(name: String) = _state.update { it.copy(username = name) }
    fun setServerUrl(url: String)  = _state.update { it.copy(serverUrl = url) }

    fun connect() {
        val s = _state.value
        val ok = socket.init(s.serverUrl)
        if (!ok) {
            _state.update { it.copy(connectionError = true) }
            return
        }

        // Register all listeners BEFORE connecting to avoid race conditions
        socket.onConnect {
            viewModelScope.launch {
                _state.update { it.copy(screen = Screen.Watch, connectionError = false) }
                socket.join(s.username, s.roomId)
            }
        }

        socket.onConnectError {
            viewModelScope.launch {
                _state.update { it.copy(screen = Screen.Join, connectionError = true) }
            }
        }

        socket.onDisconnect {
            viewModelScope.launch {
                _state.update { it.copy(screen = Screen.Join, connectedUsers = emptyList()) }
            }
        }

        socket.onSyncState { isPlaying, currentTime, users ->
            viewModelScope.launch {
                _state.update { it.copy(connectedUsers = users, isPlaying = isPlaying, pendingSeek = currentTime) }
            }
        }

        socket.onRemotePlay { time, by ->
            viewModelScope.launch {
                _state.update { it.copy(isPlaying = true, pendingPlay = time, notification = "$by شغّل ▶️") }
            }
        }

        socket.onRemotePause { time, by ->
            viewModelScope.launch {
                _state.update { it.copy(isPlaying = false, pendingPause = time, notification = "$by وقّف ⏸️") }
            }
        }

        socket.onRemoteSeek { time, by ->
            viewModelScope.launch {
                _state.update { it.copy(pendingSeek = time, notification = "$by قدّم ⏩") }
            }
        }

        socket.onUserJoined { username ->
            viewModelScope.launch {
                _state.update { it.copy(notification = "$username انضم ✨") }
                socket.requestSync()
            }
        }

        socket.onUserLeft { username ->
            viewModelScope.launch {
                _state.update { it.copy(notification = "$username خرج 👋") }
            }
        }

        _state.update { it.copy(screen = Screen.Connecting) }
        socket.connect()
    }

    fun disconnect() {
        socket.disconnect()
        _state.update { it.copy(screen = Screen.Join, connectedUsers = emptyList()) }
    }

    // Called from the player when the user presses play
    fun onPlay(currentTime: Double) {
        _state.update { it.copy(isPlaying = true) }
        socket.play(currentTime)
    }

    // Called from the player when the user presses pause
    fun onPause(currentTime: Double) {
        _state.update { it.copy(isPlaying = false) }
        socket.pause(currentTime)
    }

    // Called from the player when the user seeks
    fun onSeek(currentTime: Double) = socket.seek(currentTime)

    // Called periodically to keep the server's time updated
    fun onTimeUpdate(currentTime: Double, isPlaying: Boolean) =
        socket.sendTimeUpdate(currentTime, isPlaying)

    fun clearPendingPlay()   = _state.update { it.copy(pendingPlay = null) }
    fun clearPendingPause()  = _state.update { it.copy(pendingPause = null) }
    fun clearPendingSeek()   = _state.update { it.copy(pendingSeek = null) }
    fun clearNotification()  = _state.update { it.copy(notification = null) }
    fun clearError()         = _state.update { it.copy(connectionError = false) }

    override fun onCleared() {
        super.onCleared()
        socket.disconnect()
    }
}
