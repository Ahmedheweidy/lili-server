import 'package:flutter/material.dart';
import '../models/media_source.dart';
import '../theme/app_theme.dart';

Future<MediaSource?> showSourcePicker(BuildContext context, {MediaSource? current}) {
  return showModalBottomSheet<MediaSource>(
    context: context,
    backgroundColor: AppTheme.nightSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
  MediaType _type = MediaType.youtube;
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.current != null) {
      _type = widget.current!.type;
      _urlCtrl.text = widget.current!.url;
      _titleCtrl.text = widget.current!.title;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final url = _urlCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    if (_type != MediaType.remote && url.isEmpty) return;
    if (_type == MediaType.remote && title.isEmpty) return;
    Navigator.pop(
      context,
      MediaSource(type: _type, url: url, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dimWhite,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'إيه اللي هنتفرج عليه؟',
            style: TextStyle(
              color: AppTheme.warmWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Type selector
          Row(
            children: [
              _TypeChip(
                label: 'يوتيوب',
                icon: Icons.smart_display,
                selected: _type == MediaType.youtube,
                onTap: () => setState(() => _type = MediaType.youtube),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'رابط مباشر',
                icon: Icons.link,
                selected: _type == MediaType.direct,
                onTap: () => setState(() => _type = MediaType.direct),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'نتفلكس/شاهد',
                icon: Icons.cast_connected,
                selected: _type == MediaType.remote,
                onTap: () => setState(() => _type = MediaType.remote),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inputs per type
          if (_type == MediaType.youtube) ...[
            _field(_urlCtrl, 'رابط يوتيوب', 'https://youtu.be/...'),
          ] else if (_type == MediaType.direct) ...[
            _field(_urlCtrl, 'رابط الفيديو أو بث m3u8', 'https://...mp4 / .m3u8'),
          ] else ...[
            // remote
            Wrap(
              spacing: 8,
              children: [
                _serviceChip('Netflix'),
                _serviceChip('شاهد'),
                _serviceChip('WatchiT'),
              ],
            ),
            const SizedBox(height: 10),
            _field(_titleCtrl, 'بنتفرج على إيه؟', 'مثال: Netflix - اسم الفيلم'),
            const SizedBox(height: 8),
            const Text(
              'الفيديو هيشتغل في تطبيق الخدمة الرسمي، وهنا بس نزامن التشغيل والإيقاف + الشات.',
              style: TextStyle(color: AppTheme.dimWhite, fontSize: 12),
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _confirm,
            child: const Text('يلا نبدأ 🎬', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(color: AppTheme.warmWhite),
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: TextInputType.url,
    );
  }

  Widget _serviceChip(String name) {
    return ActionChip(
      label: Text(name),
      backgroundColor: AppTheme.cardBg,
      labelStyle: const TextStyle(color: AppTheme.softLavender),
      onPressed: () {
        final existing = _titleCtrl.text.trim();
        if (existing.isEmpty || !existing.contains(' - ')) {
          _titleCtrl.text = '$name - ';
          _titleCtrl.selection =
              TextSelection.collapsed(offset: _titleCtrl.text.length);
        }
        setState(() {});
      },
    );
  }
}

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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A0F20) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.rosePink : const Color(0xFF3A2A4A),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.rosePink : AppTheme.dimWhite, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.rosePink : AppTheme.dimWhite,
                  fontSize: 12,
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
