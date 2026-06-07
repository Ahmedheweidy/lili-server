import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/chat_panel.dart';

class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

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
                  // Connected users avatars
                  if (provider.connectedUsers.isNotEmpty)
                    Row(
                      children: [
                        ...provider.connectedUsers.take(3).map((u) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Tooltip(
                                message: u,
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

            // ── Video player with controls ────────────────
            VideoPlayerWidget(
              pendingPlay: provider.pendingPlay,
              pendingPause: provider.pendingPause,
              pendingSeek: provider.pendingSeek,
              notification: provider.notification,
              onPlay: provider.onPlay,
              onPause: provider.onPause,
              onSeek: provider.onSeek,
              onTimeUpdate: provider.onTimeUpdate,
              onClearPendingPlay: provider.clearPendingPlay,
              onClearPendingPause: provider.clearPendingPause,
              onClearPendingSeek: provider.clearPendingSeek,
            ),

            // ── Chat ──────────────────────────────────────
            Expanded(
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
}
