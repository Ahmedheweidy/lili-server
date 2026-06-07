import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final double? pendingPlay;
  final double? pendingPause;
  final double? pendingSeek;
  final String? notification;
  final void Function(double) onPlay;
  final void Function(double) onPause;
  final void Function(double) onSeek;
  final void Function(double, bool) onTimeUpdate;
  final VoidCallback onClearPendingPlay;
  final VoidCallback onClearPendingPause;
  final VoidCallback onClearPendingSeek;

  const VideoPlayerWidget({
    super.key,
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
    this.notification,
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
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  void _loadVideo() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    _ctrl?.dispose();
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    ctrl.initialize().then((_) {
      if (mounted) {
        setState(() {
          _ctrl = ctrl;
          _sliderValue = 0;
        });
        ctrl.addListener(_onControllerUpdate);
      }
    });
  }

  void _onControllerUpdate() {
    if (!mounted || _isRemoteEvent || _isSeeking) return;
    final isPlaying = _ctrl!.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      final pos = _ctrl!.value.position.inMilliseconds / 1000.0;
      if (isPlaying) widget.onPlay(pos); else widget.onPause(pos);
    }
    if (mounted && !_isSeeking) {
      final dur = _ctrl!.value.duration.inMilliseconds;
      if (dur > 0) {
        setState(() {
          _sliderValue = _ctrl!.value.position.inMilliseconds / dur;
        });
      }
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

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _ctrl?.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Video area ────────────────────────────────────
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.black),
              if (_ctrl != null && _ctrl!.value.isInitialized)
                VideoPlayer(_ctrl!),
              if (_ctrl == null || !(_ctrl?.value.isInitialized ?? false))
                const Icon(Icons.movie_outlined, size: 64, color: Color(0xFF3A2A4A)),

              // Notification overlay
              if (widget.notification != null)
                Positioned(
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xCC1A0F2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.notification!,
                      style: const TextStyle(color: AppTheme.warmWhite, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Controls ──────────────────────────────────────
        Container(
          color: AppTheme.nightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seek bar
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

              // Play/pause + time + URL input
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
                    '${_formatDuration(_ctrl?.value.position ?? Duration.zero)} / ${_formatDuration(_ctrl?.value.duration ?? Duration.zero)}',
                    style: const TextStyle(color: AppTheme.dimWhite, fontSize: 12),
                  ),
                  const Spacer(),
                  // URL field
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _urlCtrl,
                      style: const TextStyle(fontSize: 12, color: AppTheme.warmWhite),
                      decoration: InputDecoration(
                        hintText: 'رابط الفيديو / M3U8',
                        hintStyle: const TextStyle(fontSize: 11),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF3A2A4A)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.rosePink),
                        ),
                        fillColor: AppTheme.cardBg,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _loadVideo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppTheme.rosePink,
                      ),
                      child: const Text('تشغيل', style: TextStyle(fontSize: 12)),
                    ),
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
