import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../theme/app_theme.dart';

/// Plays a YouTube video using the official IFrame player, broadcasting
/// play/pause/seek so both sides stay in sync.
class YoutubePlayerWidget extends StatefulWidget {
  final String url;
  final double? pendingPlay;
  final double? pendingPause;
  final double? pendingSeek;
  final void Function(double) onPlay;
  final void Function(double) onPause;
  final void Function(double) onSeek;
  final void Function(double, bool) onTimeUpdate;
  final VoidCallback onClearPendingPlay;
  final VoidCallback onClearPendingPause;
  final VoidCallback onClearPendingSeek;

  const YoutubePlayerWidget({
    super.key,
    required this.url,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    required this.onTimeUpdate,
    required this.onClearPendingPlay,
    required this.onClearPendingPause,
    required this.onClearPendingSeek,
    this.pendingPlay,
    this.pendingPause,
    this.pendingSeek,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _ctrl;
  bool _isRemoteEvent = false;
  bool _wasPlaying = false;
  Timer? _timeTimer;

  // seek-detection bookkeeping
  double _lastPos = 0;
  DateTime _lastTick = DateTime.now();
  DateTime _suppressSeekUntil = DateTime.now();

  @override
  void initState() {
    super.initState();
    final id = YoutubePlayer.convertUrlToId(widget.url) ?? widget.url;
    _ctrl = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
      ),
    )..addListener(_onControllerUpdate);

    _timeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_ctrl.value.isReady) return;
      final pos = _ctrl.value.position.inMilliseconds / 1000.0;
      widget.onTimeUpdate(pos, _ctrl.value.isPlaying);
      _detectSeek(pos);
    });
  }

  @override
  void didUpdateWidget(YoutubePlayerWidget old) {
    super.didUpdateWidget(old);

    if (widget.url != old.url) {
      final id = YoutubePlayer.convertUrlToId(widget.url) ?? widget.url;
      _ctrl.load(id);
      _wasPlaying = false;
      return;
    }

    if (widget.pendingPlay != null && old.pendingPlay == null) {
      _applyRemote(() {
        _ctrl.seekTo(Duration(milliseconds: (widget.pendingPlay! * 1000).round()));
        _ctrl.play();
        _wasPlaying = true;
        widget.onClearPendingPlay();
      });
    }
    if (widget.pendingPause != null && old.pendingPause == null) {
      _applyRemote(() {
        _ctrl.seekTo(Duration(milliseconds: (widget.pendingPause! * 1000).round()));
        _ctrl.pause();
        _wasPlaying = false;
        widget.onClearPendingPause();
      });
    }
    if (widget.pendingSeek != null && old.pendingSeek == null) {
      _applyRemote(() {
        _ctrl.seekTo(Duration(milliseconds: (widget.pendingSeek! * 1000).round()));
        widget.onClearPendingSeek();
      });
    }
  }

  void _applyRemote(void Function() action) {
    _isRemoteEvent = true;
    action();
    // ignore listener echo + avoid false seek detection right after
    _suppressSeekUntil = DateTime.now().add(const Duration(milliseconds: 1500));
    Future.delayed(const Duration(milliseconds: 600), () {
      _isRemoteEvent = false;
    });
  }

  void _onControllerUpdate() {
    if (!mounted || _isRemoteEvent) return;
    final isPlaying = _ctrl.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      final pos = _ctrl.value.position.inMilliseconds / 1000.0;
      if (isPlaying) {
        widget.onPlay(pos);
      } else {
        widget.onPause(pos);
      }
      _suppressSeekUntil = DateTime.now().add(const Duration(milliseconds: 1500));
    }
  }

  // Detects manual scrubbing while playing and broadcasts a seek.
  void _detectSeek(double pos) {
    final now = DateTime.now();
    if (_isRemoteEvent || now.isBefore(_suppressSeekUntil)) {
      _lastPos = pos;
      _lastTick = now;
      return;
    }
    if (_ctrl.value.isPlaying) {
      final elapsed = now.difference(_lastTick).inMilliseconds / 1000.0;
      final expected = _lastPos + elapsed;
      if ((pos - expected).abs() > 3.0) {
        widget.onSeek(pos);
      }
    }
    _lastPos = pos;
    _lastTick = now;
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _ctrl,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppTheme.rosePink,
      progressColors: const ProgressBarColors(
        playedColor: AppTheme.rosePink,
        handleColor: AppTheme.rosePink,
      ),
    );
  }
}
