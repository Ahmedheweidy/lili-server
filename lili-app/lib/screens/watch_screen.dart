import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_source.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/web_sync_widget.dart';
import '../widgets/remote_sync_widget.dart';
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
    final source   = provider.source;
    final isBrowser = source == null || source.type == MediaType.web;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.deepNight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────
            _TopBar(provider: provider),

            // ── Player ────────────────────────────────────
            if (isBrowser)
              Expanded(flex: 3, child: _buildPlayer(context, provider, source))
            else
              _buildPlayer(context, provider, source),

            // ── Source bar ────────────────────────────────
            _SourceBar(source: source, onTap: () => _pickSource(context)),

            // ── Notification ──────────────────────────────
            if (provider.notification != null)
              _NotificationBanner(text: provider.notification!),

            // ── Chat ──────────────────────────────────────
            Expanded(
              flex: isBrowser ? 2 : 3,
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

  Widget _buildPlayer(BuildContext context, AppProvider provider, MediaSource? source) {
    if (source == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎬', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              const Text(
                'افتح متصفح وابدأ تتفرج',
                style: TextStyle(color: AppTheme.dimWhite, fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _pickSource(context),
                icon: const Icon(Icons.public_rounded, size: 18),
                label: const Text('فتح المتصفح'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (source.type == MediaType.remote) {
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
  }
}

// ── Top bar ───────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppProvider provider;
  const _TopBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.nightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.rosePink, AppTheme.softLavender],
            ).createShader(bounds),
            child: const Text(
              'Lili Watch',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const Spacer(),
          if (provider.connectedUsers.isNotEmpty)
            _ConnectedUsers(users: provider.connectedUsers),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: provider.disconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x22FF5252),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x44FF5252)),
              ),
              child: const Text(
                'خروج',
                style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedUsers extends StatelessWidget {
  final List<String> users;
  const _ConnectedUsers({required this.users});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...users.take(2).map((u) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: u == 'ليلى'
                      ? AppTheme.softLavender.withOpacity(0.15)
                      : AppTheme.rosePink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: u == 'ليلى'
                        ? AppTheme.softLavender.withOpacity(0.3)
                        : AppTheme.rosePink.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  u == 'ليلى' ? '🌸 ليلى' : '👨‍💻 أحمد',
                  style: TextStyle(
                    fontSize: 11,
                    color: u == 'ليلى' ? AppTheme.softLavender : AppTheme.rosePink,
                  ),
                ),
              ),
            )),
        const SizedBox(width: 6),
        Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
        ),
      ],
    );
  }
}

// ── Source bar ────────────────────────────────────────────────
class _SourceBar extends StatelessWidget {
  final MediaSource? source;
  final VoidCallback onTap;
  const _SourceBar({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRemote = source?.type == MediaType.remote;
    String label;
    if (source == null) {
      label = 'اختار إيه هتتفرج عليه';
    } else if (isRemote) {
      label = source!.title.isNotEmpty ? source!.title : 'عدّاد يدوي';
    } else {
      try {
        label = Uri.parse(source!.url).host.replaceFirst('www.', '');
        if (label.isEmpty) label = source!.url;
      } catch (_) {
        label = source!.url;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppTheme.cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isRemote ? Icons.timer_outlined : Icons.public_rounded,
              color: AppTheme.softLavender,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.warmWhite, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.rosePink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'تغيير',
                style: TextStyle(color: AppTheme.rosePink, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification banner ───────────────────────────────────────
class _NotificationBanner extends StatelessWidget {
  final String text;
  const _NotificationBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0F2E),
        border: Border(
          top: BorderSide(color: Color(0xFF2A1A3A)),
          bottom: BorderSide(color: Color(0xFF2A1A3A)),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.warmWhite, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
