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
    _urlCtrl = TextEditingController(text: context.read<AppProvider>().serverUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A18), Color(0xFF1A0F2E), Color(0xFF0D0A20)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Hero ──────────────────────────────────
                    Column(
                      children: [
                        const SizedBox(height: 52),
                        _buildLogo(),
                        const SizedBox(height: 12),
                        const Text(
                          'نتفرج سوا مهما بعدنا',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.dimWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 52),

                        // ── Profile cards ──────────────────────
                        const Text(
                          'مين انت؟',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.dimWhite,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ProfileCard(
                              name: 'أحمد',
                              emoji: '👨‍💻',
                              selected: _selected == 'أحمد',
                              activeGradient: const [Color(0xFF3D1428), Color(0xFF251030)],
                              activeBorder: AppTheme.rosePink,
                              onTap: () => setState(() => _selected = 'أحمد'),
                            ),
                            const SizedBox(width: 20),
                            _ProfileCard(
                              name: 'ليلى',
                              emoji: '🌸',
                              selected: _selected == 'ليلى',
                              activeGradient: const [Color(0xFF1A1545), Color(0xFF150F35)],
                              activeBorder: AppTheme.softLavender,
                              onTap: () => setState(() => _selected = 'ليلى'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Bottom actions ─────────────────────────
                    Column(
                      children: [
                        const SizedBox(height: 40),

                        if (provider.connectionError)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x22FF5252),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0x55FF5252)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wifi_off_rounded, color: Color(0xFFFF6B6B), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'مش قادر يوصل للسيرفر',
                                  style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 14),
                                ),
                              ],
                            ),
                          ),

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
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text(
                              'يلا نتفرج 🎬',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() => _showUrl = !_showUrl),
                          icon: Icon(
                            _showUrl ? Icons.keyboard_arrow_up : Icons.settings_outlined,
                            size: 16,
                            color: AppTheme.dimWhite,
                          ),
                          label: Text(
                            _showUrl ? 'إخفاء الإعدادات' : 'إعدادات السيرفر',
                            style: const TextStyle(color: AppTheme.dimWhite, fontSize: 13),
                          ),
                        ),
                        if (_showUrl) ...[
                          const SizedBox(height: 4),
                          TextField(
                            controller: _urlCtrl,
                            style: const TextStyle(color: AppTheme.warmWhite, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              prefixIcon: Icon(Icons.dns_outlined, color: AppTheme.softLavender, size: 18),
                            ),
                            onChanged: (v) => provider.setServerUrl(v),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Gradient icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D1428), Color(0xFF1A1545)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.rosePink.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('💕', style: TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.rosePink, AppTheme.softLavender],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Lili Watch',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Profile card ──────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String name;
  final String emoji;
  final bool selected;
  final List<Color> activeGradient;
  final Color activeBorder;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.name,
    required this.emoji,
    required this.selected,
    required this.activeGradient,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: selected ? 150 : 140,
        height: selected ? 190 : 178,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: activeGradient,
                )
              : const LinearGradient(colors: [AppTheme.cardBg, AppTheme.cardBg]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? activeBorder : const Color(0xFF2E2245),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: activeBorder.withOpacity(0.25), blurRadius: 24, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: selected ? 52 : 46)),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : AppTheme.dimWhite,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 32 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: activeBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
