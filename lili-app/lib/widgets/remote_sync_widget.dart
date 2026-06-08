import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// For DRM services (Netflix / Shahid / WatchiT) that can't play inside a
/// custom app. Each person plays the title in the official app, and this
/// shared remote keeps a synchronized play/pause + stopwatch so you stay
/// aligned. Controls are broadcast just like the real players.
class RemoteSyncWidget extends StatefulWidget {
  final String title;
  final double? pendingPlay;
  final double? pendingPause;
  final double? pendingSeek;
  final void Function(double) onPlay;
  final void Function(double) onPause;
  final void Function(double) onSeek;
  final VoidCallback onClearPendingPlay;
  final VoidCallback onClearPendingPause;
  final VoidCallback onClearPendingSeek;

  const RemoteSyncWidget({
    super.key,
    required this.title,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    required this.onClearPendingPlay,
    required this.onClearPendingPause,
    required this.onClearPendingSeek,
    this.pendingPlay,
    this.pendingPause,
    this.pendingSeek,
  });

  @override
  State<RemoteSyncWidget> createState() => _RemoteSyncWidgetState();
}

class _RemoteSyncWidgetState extends State<RemoteSyncWidget> {
  double _elapsed = 0;
  bool _isPlaying = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPlaying && mounted) setState(() => _elapsed += 1);
    });
  }

  @override
  void didUpdateWidget(RemoteSyncWidget old) {
    super.didUpdateWidget(old);
    if (widget.pendingPlay != null && old.pendingPlay == null) {
      setState(() {
        _elapsed = widget.pendingPlay!;
        _isPlaying = true;
      });
      widget.onClearPendingPlay();
    }
    if (widget.pendingPause != null && old.pendingPause == null) {
      setState(() {
        _elapsed = widget.pendingPause!;
        _isPlaying = false;
      });
      widget.onClearPendingPause();
    }
    if (widget.pendingSeek != null && old.pendingSeek == null) {
      setState(() => _elapsed = widget.pendingSeek!);
      widget.onClearPendingSeek();
    }
  }

  void _toggle() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      widget.onPlay(_elapsed);
    } else {
      widget.onPause(_elapsed);
    }
  }

  void _reset() {
    setState(() {
      _elapsed = 0;
      _isPlaying = false;
    });
    widget.onSeek(0);
  }

  String _fmt(double seconds) {
    final d = Duration(seconds: seconds.round());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF120A22),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cast_connected, color: AppTheme.softLavender, size: 32),
          const SizedBox(height: 8),
          Text(
            widget.title.isNotEmpty ? widget.title : 'مشاهدة خارجية',
            style: const TextStyle(
              color: AppTheme.warmWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'افتحوا المحتوى في تطبيقه الرسمي، واضغطوا تشغيل من هنا مع بعض',
            style: TextStyle(color: AppTheme.dimWhite, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Synced stopwatch
          Text(
            _fmt(_elapsed),
            style: const TextStyle(
              color: AppTheme.rosePink,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt, color: AppTheme.dimWhite, size: 28),
                tooltip: 'إعادة الضبط',
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppTheme.rosePink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isPlaying ? 'بتتفرجوا دلوقتي ▶️' : 'متوقّف ⏸️',
            style: const TextStyle(color: AppTheme.dimWhite, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
