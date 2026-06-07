import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
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
  String? _notification;
  bool _connectionError = false;

  double? _pendingPlay;
  double? _pendingPause;
  double? _pendingSeek;

  AppScreen get screen          => _screen;
  String    get username        => _username;
  String    get serverUrl       => _serverUrl;
  String    get roomId          => _roomId;
  List<String> get connectedUsers => List.unmodifiable(_connectedUsers);
  List<ChatMessage> get messages  => List.unmodifiable(_messages);
  String?   get notification    => _notification;
  bool      get connectionError => _connectionError;
  double?   get pendingPlay     => _pendingPlay;
  double?   get pendingPause    => _pendingPause;
  double?   get pendingSeek     => _pendingSeek;

  void setUsername(String v) { _username = v; notifyListeners(); }
  void setServerUrl(String v) { _serverUrl = v; notifyListeners(); }

  void connect() {
    if (!_socket.init(_serverUrl)) {
      _connectionError = true;
      notifyListeners();
      return;
    }

    _socket.onConnect(() {
      _screen = AppScreen.watch;
      _connectionError = false;
      notifyListeners();
      _socket.join(_username, _roomId);
    });

    _socket.onConnectError(() {
      _screen = AppScreen.join;
      _connectionError = true;
      notifyListeners();
    });

    _socket.onDisconnect(() {
      _screen = AppScreen.join;
      _connectedUsers = [];
      notifyListeners();
    });

    _socket.onSyncState((isPlaying, currentTime, users, messages) {
      _connectedUsers = users;
      _messages = messages;
      _pendingSeek = currentTime;
      notifyListeners();
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
    _socket.disconnect();
    _screen = AppScreen.join;
    _connectedUsers = [];
    _messages = [];
    notifyListeners();
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _socket.sendChatMessage(text.trim());
  }

  void onPlay(double t)                      => _socket.play(t);
  void onPause(double t)                     => _socket.pause(t);
  void onSeek(double t)                      => _socket.seek(t);
  void onTimeUpdate(double t, bool playing)  => _socket.sendTimeUpdate(t, playing);

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
