import 'package:flutter/material.dart';
import '../models/media_source.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

Future<MediaSource?> showSourcePicker(BuildContext context, {MediaSource? current}) {
  return showModalBottomSheet<MediaSource>(
    context: context,
    backgroundColor: AppTheme.nightSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SourcePicker(current: current),
  );
}

class _SourcePicker extends StatefulWidget {
  final MediaSource? current;
  const _SourcePicker({this.current});

  @override
  State<_SourcePicker> createState() => _SourcePickerState();
}

class _SourcePickerState extends State<_SourcePicker> {
  MediaType _type = MediaType.web;
  final _urlCtrl   = TextEditingController();
  final _titleCtrl = TextEditingController();
  List<HistoryItem> _history = [];

  static const _quickLinks = {
    'شاهد':   'https://shahid.mbc.net',
    'WatchiT': 'https://www.watchit.com',
    'Netflix': 'https://www.netflix.com',
  };

  @override
  void initState() {
    super.initState();
    if (widget.current != null) {
      _type = widget.current!.type;
      _urlCtrl.text   = widget.current!.url;
      _titleCtrl.text = widget.current!.title;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await HistoryService.load();
    if (mounted) setState(() => _history = items);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_type == MediaType.remote) {
      if (_titleCtrl.text.trim().isEmpty) return;
      Navigator.pop(context, MediaSource(type: _type, url: '', title: _titleCtrl.text.trim()));
    } else {
      final url = _urlCtrl.text.trim();
      Navigator.pop(context, MediaSource(
        type: _type,
        url: url.isEmpty ? 'https://www.google.com' : url,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dimWhite.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'إيه اللي هنتفرج عليه؟',
            style: TextStyle(color: AppTheme.warmWhite, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ── Mode selector ─────────────────────────────
          Row(
            children: [
              _TypeChip(
                label: 'متصفح',
                icon: Icons.public_rounded,
                selected: _type == MediaType.web,
                onTap: () => setState(() => _type = MediaType.web),
              ),
              const SizedBox(width: 10),
              _TypeChip(
                label: 'عدّاد يدوي',
                icon: Icons.timer_outlined,
                selected: _type == MediaType.remote,
                onTap: () => setState(() => _type = MediaType.remote),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Browser inputs ────────────────────────────
          if (_type == MediaType.web) ...[
            // History
            if (_history.isNotEmpty) ...[
              const Text(
                'شوفتوها قبل كدا',
                style: TextStyle(color: AppTheme.dimWhite, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _history.length.clamp(0, 6),
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = _history[i];
                    return _HistoryTile(
                      item: item,
                      onTap: () => setState(() => _urlCtrl.text = item.url),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2A1A3A), height: 1),
              const SizedBox(height: 16),
            ],

            // Quick links
            Wrap(
              spacing: 8,
              children: _quickLinks.entries.map((e) => ActionChip(
                label: Text(e.key),
                backgroundColor: AppTheme.cardBg,
                labelStyle: const TextStyle(color: AppTheme.softLavender, fontSize: 13),
                onPressed: () => setState(() => _urlCtrl.text = e.value),
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              style: const TextStyle(color: AppTheme.warmWhite),
              decoration: const InputDecoration(
                labelText: 'رابط (اختياري)',
                hintText: 'اتركه فاضي تبدأ من جوجل',
                prefixIcon: Icon(Icons.link_rounded, color: AppTheme.softLavender, size: 18),
              ),
              keyboardType: TextInputType.url,
            ),
          ]

          // ── Manual timer inputs ───────────────────────
          else ...[
            Wrap(
              spacing: 8,
              children: _quickLinks.keys.map((name) => ActionChip(
                label: Text(name),
                backgroundColor: AppTheme.cardBg,
                labelStyle: const TextStyle(color: AppTheme.softLavender, fontSize: 13),
                onPressed: () {
                  final existing = _titleCtrl.text.trim();
                  if (existing.isEmpty || !existing.contains(' - ')) {
                    _titleCtrl.text = '$name - ';
                    _titleCtrl.selection = TextSelection.collapsed(offset: _titleCtrl.text.length);
                  }
                  setState(() {});
                },
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppTheme.warmWhite),
              decoration: const InputDecoration(
                labelText: 'بنتفرج على إيه؟',
                hintText: 'مثال: Netflix - اسم الفيلم',
                prefixIcon: Icon(Icons.movie_outlined, color: AppTheme.softLavender, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'شغّل الفيديو في تطبيقه الرسمي وهنا نزامن العدّاد + الشات.',
              style: TextStyle(color: AppTheme.dimWhite, fontSize: 12),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('يلا نبدأ 🎬', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── History tile ──────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;
  const _HistoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppTheme.softLavender, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: const TextStyle(color: AppTheme.warmWhite, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    item.domain,
                    style: const TextStyle(color: AppTheme.dimWhite, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.timeAgo,
              style: const TextStyle(color: AppTheme.dimWhite, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type chip ─────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A0F20) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.rosePink : const Color(0xFF3A2A4A),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: AppTheme.rosePink.withOpacity(0.15), blurRadius: 12)]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.rosePink : AppTheme.dimWhite, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppTheme.rosePink : AppTheme.dimWhite,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
