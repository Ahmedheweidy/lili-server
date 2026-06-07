import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/chat_message.dart';
import '../models/media_source.dart';

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  bool init(String serverUrl) {
    try {
      _socket = io.io(serverUrl, io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build());
      return true;
    } catch (_) {
      return false;
    }
  }

  void connect()    => _socket?.connect();
  void disconnect() { _socket?.disconnect(); _socket?.dispose(); _socket = null; }

  void join(String username, String roomId) =>
      _socket?.emit('join', {'username': username, 'roomId': roomId});

  void play(double t)  => _socket?.emit('play',  {'currentTime': t});
  void pause(double t) => _socket?.emit('pause', {'currentTime': t});
  void seek(double t)  => _socket?.emit('seek',  {'currentTime': t});
  void requestSync()   => _socket?.emit('request-sync');

  void sendChatMessage(String text) =>
      _socket?.emit('chat-message', {'text': text});

  void setSource(MediaSource source) =>
      _socket?.emit('set-source', source.toJson());

  // ── Listeners ─────────────────────────────────────────

  void onConnect(void Function() cb) =>
      _socket?.onConnect((_) => cb());

  void onDisconnect(void Function() cb) =>
      _socket?.onDisconnect((_) => cb());

  void onConnectError(void Function() cb) =>
      _socket?.onConnectError((_) => cb());

  void onSyncState(
    void Function(bool isPlaying, double currentTime, List<String> users,
            List<ChatMessage> messages, MediaSource? source)
        cb,
  ) {
    _socket?.on('sync-state', (raw) {
      final d = Map<String, dynamic>.from(raw as Map);
      final users = (d['users'] as List? ?? [])
          .map((u) => (u as Map)['name'] as String)
          .toList();
      final msgs = (d['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList();
      final src = d['source'] == null
          ? null
          : MediaSource.fromJson(Map<String, dynamic>.from(d['source'] as Map));
      cb(d['isPlaying'] as bool, (d['currentTime'] as num).toDouble(), users, msgs, src);
    });
  }

  void onSourceChanged(void Function(MediaSource source) cb) {
    _socket?.on('source-changed', (raw) {
      cb(MediaSource.fromJson(Map<String, dynamic>.from(raw as Map)));
    });
  }

  void onRemotePlay(void Function(double time, String by) cb) {
    _socket?.on('remote-play', (raw) {
      final d = Map<String, dynamic>.from(raw as Map);
      cb((d['currentTime'] as num).toDouble(), d['triggeredBy'] as String? ?? '');
    });
  }

  void onRemotePause(void Function(double time, String by) cb) {
    _socket?.on('remote-pause', (raw) {
      final d = Map<String, dynamic>.from(raw as Map);
      cb((d['currentTime'] as num).toDouble(), d['triggeredBy'] as String? ?? '');
    });
  }

  void onRemoteSeek(void Function(double time, String by) cb) {
    _socket?.on('remote-seek', (raw) {
      final d = Map<String, dynamic>.from(raw as Map);
      cb((d['currentTime'] as num).toDouble(), d['triggeredBy'] as String? ?? '');
    });
  }

  void onUserJoined(void Function(String username) cb) {
    _socket?.on('user-joined', (raw) {
      cb((Map<String, dynamic>.from(raw as Map))['username'] as String? ?? '');
    });
  }

  void onUserLeft(void Function(String username) cb) {
    _socket?.on('user-left', (raw) {
      cb((Map<String, dynamic>.from(raw as Map))['username'] as String? ?? '');
    });
  }

  void onChatMessage(void Function(ChatMessage msg) cb) {
    _socket?.on('chat-message', (raw) {
      cb(ChatMessage.fromJson(Map<String, dynamic>.from(raw as Map)));
    });
  }
}
