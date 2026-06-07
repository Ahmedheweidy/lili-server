import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

/// Plays a direct video URL (mp4) or an HLS (m3u8) stream, with custom
/// controls whose play/pause/seek actions are broadcast for sync.
class VideoPlayerWidget extends StatefulWidget {
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

  const VideoPlayerWidget({
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
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _ctrl;
  bool _isRemoteEvent = false;
  bool _wasPlaying = false;
  bool _isSeeking = false;
  double _sliderValue = 0;
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();
    _load(widget.url);
    _timeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_ctrl?.value.isInitialized ?? false) {
        widget.onTimeUpdate(
          _ctrl!.value.position.inMilliseconds / 1000.0,
          _ctrl!.value.isPlaying,
        );
      }
    });
  }

  @override
  void didUpdateWidget(VideoPlayerWidget old) {
    super.didUpdateWidget(old);

    if (widget.url != old.url) {
      _load(widget.url);
      return;
    }

    if (widget.pendingPlay != null && old.pendingPlay == null) {
      _applyRemote(() async {
        await _ctrl?.seekTo(Duration(milliseconds: (widget.pendingPlay! * 1000).round()));
        await _ctrl?.play();
        _wasPlaying = true;
        widget.onClearPendingPlay();
      });
    }
    if (widget.pendingPause != null && old.pendingPause == null) {
      _applyRemote(() async {
        await _ctrl?.seekTo(Duration(milliseconds: (widget.pendingPause! * 1000).round()));
        await _ctrl?.pause();
        _wasPlaying = false;
        widget.onClearPendingPause();
      });
    }
    if (widget.pendingSeek != null && old.pendingSeek == null) {
      _applyRemote(() async {
        await _ctrl?.seekTo(Duration(milliseconds: (widget.pendingSeek! * 1000).round()));
        widget.onClearPendingSeek();
      });
    }
  }

  Future<void> _applyRemote(Future<void> Function() action) async {
    _isRemoteEvent = true;
    await action();
    await Future.delayed(const Duration(milliseconds: 300));
    _isRemoteEvent = false;
  }

  void _load(String url) {
    if (url.isEmpty) return;
    _ctrl?.removeListener(_onControllerUpdate);
    _ctrl?.dispose();
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    ctrl.initialize().then((_) {
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _ctrl = ctrl;
        _sliderValue = 0;
        _wasPlaying = false;
      });
      ctrl.addListener(_onControllerUpdate);
    }).catchError((_) {
      // ignore load errors; UI shows placeholder
    });
  }

  void _onControllerUpdate() {
    if (!mounted || _isRemoteEvent || _isSeeking) return;
    final isPlaying = _ctrl!.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      final pos = _ctrl!.value.position.inMilliseconds / 1000.0;
      if (isPlaying) {
        widget.onPlay(pos);
      } else {
        widget.onPause(pos);
      }
    }
    final dur = _ctrl!.value.duration.inMilliseconds;
    if (dur > 0 && !_isSeeking) {
      setState(() {
        _sliderValue = _ctrl!.value.position.inMilliseconds / dur;
      });
    }
  }

  void _togglePlayPause() {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (_ctrl!.value.isPlaying) {
      _ctrl!.pause();
    } else {
      _ctrl!.play();
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _ctrl?.removeListener(_onControllerUpdate);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ctrl != null && _ctrl!.value.isInitialized;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.black),
              if (ready) VideoPlayer(_ctrl!),
              if (!ready)
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.rosePink),
                    SizedBox(height: 12),
                    Text('بنحمّل الفيديو...', style: TextStyle(color: AppTheme.dimWhite)),
                  ],
                ),
            ],
          ),
        ),
        Container(
          color: AppTheme.nightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  thumbColor: AppTheme.rosePink,
                  activeTrackColor: AppTheme.rosePink,
                  inactiveTrackColor: const Color(0xFF3A2A4A),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: _sliderValue.clamp(0, 1),
                  onChangeStart: (_) => _isSeeking = true,
                  onChanged: (v) => setState(() => _sliderValue = v),
                  onChangeEnd: (v) {
                    _isSeeking = false;
                    final dur = _ctrl?.value.duration ?? Duration.zero;
                    final seekTo = Duration(milliseconds: (v * dur.inMilliseconds).round());
                    _ctrl?.seekTo(seekTo);
                    widget.onSeek(seekTo.inMilliseconds / 1000.0);
                  },
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      (_ctrl?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow,
                      color: AppTheme.rosePink,
                      size: 28,
                    ),
                  ),
                  Text(
                    '${_fmt(_ctrl?.value.position ?? Duration.zero)} / ${_fmt(_ctrl?.value.duration ?? Duration.zero)}',
                    style: const TextStyle(color: AppTheme.dimWhite, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
