import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'chat_bubble.dart';

class ChatPanel extends StatefulWidget {
  final List<ChatMessage> messages;
  final String currentUsername;
  final void Function(String) onSend;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.currentUsername,
    required this.onSend,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void didUpdateWidget(ChatPanel old) {
    super.didUpdateWidget(old);
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppTheme.nightSurface,
            border: Border(top: BorderSide(color: Color(0xFF2A1A3A), width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppTheme.rosePink, size: 16),
              const SizedBox(width: 8),
              const Text(
                'الشات',
                style: TextStyle(
                  color: AppTheme.rosePink,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.messages.length} رسالة',
                style: const TextStyle(color: AppTheme.dimWhite, fontSize: 12),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: widget.messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💬', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 8),
                      Text(
                        'ابدأ الشات مع بعض',
                        style: TextStyle(color: AppTheme.dimWhite),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, i) {
                    final msg = widget.messages[i];
                    return ChatBubble(
                      message: msg,
                      isMe: msg.username == widget.currentUsername,
                    );
                  },
                ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppTheme.nightSurface,
            border: Border(top: BorderSide(color: Color(0xFF2A1A3A))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textDirection: TextDirection.rtl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  maxLines: null,
                  style: const TextStyle(color: AppTheme.warmWhite, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintTextDirection: TextDirection.rtl,
                    filled: true,
                    fillColor: AppTheme.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppTheme.rosePink, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.rosePink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
