package com.watchparty.lili.network

import io.socket.client.IO
import io.socket.client.Socket
import org.json.JSONObject
import java.net.URI

class SocketManager {
    private var socket: Socket? = null

    fun init(serverUrl: String): Boolean {
        return try {
            socket = IO.socket(URI.create(serverUrl))
            true
        } catch (e: Exception) {
            false
        }
    }

    fun connect() = socket?.connect()

    fun disconnect() {
        socket?.disconnect()
        socket?.off()
        socket = null
    }

    fun join(username: String, roomId: String) {
        socket?.emit("join", JSONObject().apply {
            put("username", username)
            put("roomId", roomId)
        })
    }

    fun play(currentTime: Double) =
        socket?.emit("play", JSONObject().put("currentTime", currentTime))

    fun pause(currentTime: Double) =
        socket?.emit("pause", JSONObject().put("currentTime", currentTime))

    fun seek(currentTime: Double) =
        socket?.emit("seek", JSONObject().put("currentTime", currentTime))

    fun requestSync() = socket?.emit("request-sync")

    fun sendTimeUpdate(currentTime: Double, isPlaying: Boolean) {
        socket?.emit("time-update", JSONObject().apply {
            put("currentTime", currentTime)
            put("isPlaying", isPlaying)
        })
    }

    // ── Event listeners ───────────────────────────────

    fun onConnect(cb: () -> Unit) =
        socket?.on(Socket.EVENT_CONNECT) { cb() }

    fun onDisconnect(cb: () -> Unit) =
        socket?.on(Socket.EVENT_DISCONNECT) { cb() }

    fun onConnectError(cb: () -> Unit) =
        socket?.on(Socket.EVENT_CONNECT_ERROR) { cb() }

    fun onSyncState(cb: (isPlaying: Boolean, currentTime: Double, users: List<String>) -> Unit) {
        socket?.on("sync-state") { args ->
            val d = args[0] as JSONObject
            val arr = d.optJSONArray("users")
            val users = buildList {
                arr?.let { for (i in 0 until it.length()) add(it.getJSONObject(i).getString("name")) }
            }
            cb(d.getBoolean("isPlaying"), d.getDouble("currentTime"), users)
        }
    }

    fun onRemotePlay(cb: (time: Double, by: String) -> Unit) {
        socket?.on("remote-play") { args ->
            val d = args[0] as JSONObject
            cb(d.getDouble("currentTime"), d.optString("triggeredBy", ""))
        }
    }

    fun onRemotePause(cb: (time: Double, by: String) -> Unit) {
        socket?.on("remote-pause") { args ->
            val d = args[0] as JSONObject
            cb(d.getDouble("currentTime"), d.optString("triggeredBy", ""))
        }
    }

    fun onRemoteSeek(cb: (time: Double, by: String) -> Unit) {
        socket?.on("remote-seek") { args ->
            val d = args[0] as JSONObject
            cb(d.getDouble("currentTime"), d.optString("triggeredBy", ""))
        }
    }

    fun onUserJoined(cb: (username: String) -> Unit) {
        socket?.on("user-joined") { args ->
            cb((args[0] as JSONObject).optString("username", ""))
        }
    }

    fun onUserLeft(cb: (username: String) -> Unit) {
        socket?.on("user-left") { args ->
            cb((args[0] as JSONObject).optString("username", ""))
        }
    }
}
