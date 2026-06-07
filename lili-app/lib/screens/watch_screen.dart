import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_source.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/youtube_player_widget.dart';
import '../widgets/remote_sync_widget.dart';
import '../widgets/web_sync_widget.dart';
import '../widgets/chat_panel.dart';
import '../widgets/source_picker.dart';

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  Future<void> _pickSource(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final result = await showSourcePicker(context, current: provider.source);
    if (result != null) provider.setSource(result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final source = provider.source;
    final isWeb = source?.type == MediaType.web;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────
            Container(
              color: AppTheme.nightSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Text(
                    '💕 Lili Watch',
                    style: TextStyle(
                      color: AppTheme.rosePink,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  if (provider.connectedUsers.isNotEmpty)
                    Row(
                      children: [
                        ...provider.connectedUsers.take(3).map((u) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: u == 'ليلى'
                                    ? AppTheme.softLavender.withOpacity(0.3)
                                    : AppTheme.rosePink.withOpacity(0.3),
                                child: Text(
                                  u == 'ليلى' ? '🌸' : '👨‍💻',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: provider.disconnect,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 32),
                    ),
                    child: const Text('خروج', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),

            // ── Player area ───────────────────────────────
            // Web mode needs a large flexible area; other players are intrinsic.
            if (isWeb)
              Expanded(flex: 3, child: _buildPlayer(context, provider, source))
            else
              _buildPlayer(context, provider, source),

            // ── Source bar (change what we're watching) ───
            InkWell(
              onTap: () => _pickSource(context),
              child: Container(
                color: AppTheme.cardBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.movie_filter, color: AppTheme.softLavender, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sourceLabel(source),
                        style: const TextStyle(color: AppTheme.warmWhite, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text('تغيير', style: TextStyle(color: AppTheme.rosePink, fontSize: 13)),
                  ],
                ),
              ),
            ),

            // ── Notification ──────────────────────────────
            if (provider.notification != null)
              Container(
                width: double.infinity,
                color: const Color(0xFF1A0F2E),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Text(
                  provider.notification!,
                  style: const TextStyle(color: AppTheme.warmWhite, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // ── Chat ──────────────────────────────────────
            Expanded(
              flex: isWeb ? 2 : 1,
              child: ChatPanel(
                messages: provider.messages,
                currentUsername: provider.username,
                onSend: provider.sendChatMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(MediaSource? s) {
    if (s == null) return 'اختار فيديو نتفرج عليه';
    switch (s.type) {
      case MediaType.youtube:
        return 'يوتيوب: ${s.title.isNotEmpty ? s.title : s.url}';
      case MediaType.direct:
        return 'فيديو: ${s.title.isNotEmpty ? s.title : s.url}';
      case MediaType.web:
        return 'موقع: ${s.url}';
      case MediaType.remote:
        return s.title.isNotEmpty ? s.title : 'مشاهدة خارجية';
    }
  }

  Widget _buildPlayer(BuildContext context, AppProvider provider, MediaSource? source) {
    if (source == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎬', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                const Text(
                  'لسه مفيش حاجة شغالة',
                  style: TextStyle(color: AppTheme.dimWhite),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _pickSource(context),
                  child: const Text('اختار فيديو'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (source.type) {
      case MediaType.youtube:
        return YoutubePlayerWidget(
          key: ValueKey('yt-${source.url}'),
          url: source.url,
          pendingPlay: provider.pendingPlay,
          pendingPause: provider.pendingPause,
          pendingSeek: provider.pendingSeek,
          onPlay: provider.onPlay,
          onPause: provider.onPause,
          onSeek: provider.onSeek,
          onTimeUpdate: provider.onTimeUpdate,
          onClearPendingPlay: provider.clearPendingPlay,
          onClearPendingPause: provider.clearPendingPause,
          onClearPendingSeek: provider.clearPendingSeek,
        );
      case MediaType.direct:
        return VideoPlayerWidget(
          key: ValueKey('vid-${source.url}'),
          url: source.url,
          pendingPlay: provider.pendingPlay,
          pendingPause: provider.pendingPause,
          pendingSeek: provider.pendingSeek,
          onPlay: provider.onPlay,
          onPause: provider.onPause,
          onSeek: provider.onSeek,
          onTimeUpdate: provider.onTimeUpdate,
          onClearPendingPlay: provider.clearPendingPlay,
          onClearPendingPause: provider.clearPendingPause,
          onClearPendingSeek: provider.clearPendingSeek,
        );
      case MediaType.web:
        return WebSyncWidget(
          key: ValueKey('web-${source.url}'),
          url: source.url,
          pendingPlay: provider.pendingPlay,
          pendingPause: provider.pendingPause,
          pendingSeek: provider.pendingSeek,
          onPlay: provider.onPlay,
          onPause: provider.onPause,
          onSeek: provider.onSeek,
          onClearPendingPlay: provider.clearPendingPlay,
          onClearPendingPause: provider.clearPendingPause,
          onClearPendingSeek: provider.clearPendingSeek,
        );
      case MediaType.remote:
        return RemoteSyncWidget(
          key: ValueKey('remote-${source.title}'),
          title: source.title,
          pendingPlay: provider.pendingPlay,
          pendingPause: provider.pendingPause,
          pendingSeek: provider.pendingSeek,
          onPlay: provider.onPlay,
          onPause: provider.onPause,
          onSeek: provider.onSeek,
          onClearPendingPlay: provider.clearPendingPlay,
          onClearPendingPause: provider.clearPendingPause,
          onClearPendingSeek: provider.clearPendingSeek,
        );
    }
  }
}
