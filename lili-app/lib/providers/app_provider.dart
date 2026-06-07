import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/media_source.dart';
import '../services/socket_service.dart';

enum AppScreen { join, connecting, watch }

class AppProvider extends ChangeNotifier {
  final _socket = SocketService();

  AppScreen _screen = AppScreen.join;
  String _username = '';
  String _serverUrl = 'https://lili-server-tnjj.onrender.com';
  final String _roomId = 'lili-room';
  List<String> _connectedUsers = [];
  List<ChatMessage> _messages = [];
  MediaSource? _source;
  String? _notification;
  bool _connectionError = false;
  bool _isReconnecting = false;

  double? _pendingPlay;
  double? _pendingPause;
  double? _pendingSeek;

  AppScreen get screen           => _screen;
  String    get username         => _username;
  String    get serverUrl        => _serverUrl;
  String    get roomId           => _roomId;
  List<String> get connectedUsers  => List.unmodifiable(_connectedUsers);
  List<ChatMessage> get messages   => List.unmodifiable(_messages);
  MediaSource? get source        => _source;
  String?   get notification     => _notification;
  bool      get connectionError  => _connectionError;
  bool      get isReconnecting   => _isReconnecting;
  double?   get pendingPlay      => _pendingPlay;
  double?   get pendingPause     => _pendingPause;
  double?   get pendingSeek      => _pendingSeek;

  void setUsername(String v) { _username = v; notifyListeners(); }
  void setServerUrl(String v) { _serverUrl = v; notifyListeners(); }

  void connect() {
    if (!_socket.init(_serverUrl)) {
      _connectionError = true;
      notifyListeners();
      return;
    }

    _socket.onConnect(() {
      _isReconnecting = false;
      _connectionError = false;
      _screen = AppScreen.watch;
      notifyListeners();
      _socket.join(_username, _roomId);
    });

    _socket.onConnectError(() {
      if (_screen != AppScreen.watch) {
        _screen = AppScreen.join;
        _connectionError = true;
        notifyListeners();
      }
    });

    // Unexpected disconnect → show reconnecting banner, stay on watch screen
    // Socket.io will auto-reconnect, and onConnect will restore state
    _socket.onDisconnect(() {
      if (_screen == AppScreen.join) return; // manual disconnect, ignore
      _isReconnecting = true;
      _connectedUsers = [];
      notifyListeners();
    });

    _socket.onSyncState((isPlaying, currentTime, users, messages, source) {
      _connectedUsers = users;
      _messages = messages;
      if (source != null) _source = source;
      _pendingSeek = currentTime;
      notifyListeners();
    });

    _socket.onSourceChanged((source) {
      _source = source;
      _pendingPlay = null;
      _pendingPause = null;
      _pendingSeek = null;
      _showNotif('بتتفرجوا على: ${source.title.isNotEmpty ? source.title : 'فيديو جديد'} 🎬');
    });

    _socket.onRemotePlay((time, by) {
      _pendingPlay = time;
      _showNotif('$by شغّل ▶️');
    });

    _socket.onRemotePause((time, by) {
      _pendingPause = time;
      _showNotif('$by وقّف ⏸️');
    });

    _socket.onRemoteSeek((time, by) {
      _pendingSeek = time;
      _showNotif('$by قدّم ⏩');
    });

    _socket.onUserJoined((u) {
      _showNotif('$u انضم ✨');
      _socket.requestSync();
    });

    _socket.onUserLeft((u) => _showNotif('$u خرج 👋'));

    _socket.onChatMessage((msg) {
      _messages = [..._messages, msg];
      notifyListeners();
    });

    _screen = AppScreen.connecting;
    notifyListeners();
    _socket.connect();
  }

  void disconnect() {
    // Set join screen BEFORE disconnecting so onDisconnect sees it and skips reconnect
    _screen = AppScreen.join;
    _isReconnecting = false;
    _connectedUsers = [];
    _messages = [];
    _source = null;
    notifyListeners();
    _socket.disconnect();
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _socket.sendChatMessage(text.trim());
  }

  void setSource(MediaSource source) {
    _source = source;
    _pendingPlay = null;
    _pendingPause = null;
    _pendingSeek = null;
    notifyListeners();
    _socket.setSource(source);
  }

  void onPlay(double t)  => _socket.play(t);
  void onPause(double t) => _socket.pause(t);
  void onSeek(double t)  => _socket.seek(t);

  void clearPendingPlay()  { _pendingPlay  = null; notifyListeners(); }
  void clearPendingPause() { _pendingPause = null; notifyListeners(); }
  void clearPendingSeek()  { _pendingSeek  = null; notifyListeners(); }
  void clearError()        { _connectionError = false; notifyListeners(); }

  Timer? _notifTimer;
  void _showNotif(String msg) {
    _notification = msg;
    notifyListeners();
    _notifTimer?.cancel();
    _notifTimer = Timer(const Duration(seconds: 3), () {
      _notification = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }
}
