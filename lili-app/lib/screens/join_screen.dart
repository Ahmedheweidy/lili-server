import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  String _selected = '';
  bool _showUrl = false;
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
      text: context.read<AppProvider>().serverUrl,
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A0F2E), Color(0xFF0D0D1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 56),
                const Text('💕', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                const Text(
                  'Lili Watch',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.rosePink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نتفرج سوا مهما بعدنا',
                  style: TextStyle(fontSize: 16, color: AppTheme.dimWhite),
                ),
                const SizedBox(height: 40),
                const Text(
                  'مين انت؟',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warmWhite,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PersonCard(
                      name: 'أحمد',
                      emoji: '👨‍💻',
                      selected: _selected == 'أحمد',
                      onTap: () => setState(() => _selected = 'أحمد'),
                    ),
                    const SizedBox(width: 16),
                    _PersonCard(
                      name: 'ليلى',
                      emoji: '🌸',
                      selected: _selected == 'ليلى',
                      onTap: () => setState(() => _selected = 'ليلى'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Error
                if (provider.connectionError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x33FF5252),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '❌ مش قادر يوصل للسيرفر. تأكد من الـ URL',
                      style: TextStyle(color: Color(0xFFFF6B6B)),
                      textAlign: TextAlign.center,
                    ),
                  ),

                TextButton(
                  onPressed: () => setState(() => _showUrl = !_showUrl),
                  child: Text(_showUrl ? 'إخفاء إعدادات السيرفر' : '⚙️ إعدادات السيرفر'),
                ),

                if (_showUrl) ...[
                  const SizedBox(height: 4),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(labelText: 'Server URL'),
                    onChanged: (v) => provider.setServerUrl(v),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            provider.clearError();
                            provider.setUsername(_selected);
                            provider.connect();
                          },
                    child: const Text('يلا نتفرج 🎬', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final String name;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _PersonCard({
    required this.name,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A0F20) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.rosePink : const Color(0xFF3A2A4A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppTheme.rosePink : AppTheme.warmWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
