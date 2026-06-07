import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String url;
  final String title;
  final int timestamp;

  const HistoryItem({required this.url, required this.title, required this.timestamp});

  String get domain {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  String get displayTitle => title.isNotEmpty && title != url ? title : domain;

  String get timeAgo {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (diff < 60000)     return 'دلوقتي';
    if (diff < 3600000)   return '${(diff / 60000).floor()} دقيقة';
    if (diff < 86400000)  return '${(diff / 3600000).floor()} ساعة';
    if (diff < 604800000) return '${(diff / 86400000).floor()} يوم';
    return '${(diff / 604800000).floor()} أسبوع';
  }

  Map<String, dynamic> toJson() => {'url': url, 'title': title, 'ts': timestamp};

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        url: j['url'] as String? ?? '',
        title: j['title'] as String? ?? '',
        timestamp: j['ts'] as int? ?? 0,
      );
}

class HistoryService {
  static const _key = 'lili_history_v1';
  static const _max = 30;

  static bool _isSkippable(String url) {
    if (url.isEmpty) return true;
    final u = url.toLowerCase();
    return u.contains('google.com') || u.contains('about:blank');
  }

  static Future<List<HistoryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      return raw
          .map((s) {
            try {
              return HistoryItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<HistoryItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(String url, String title) async {
    if (_isSkippable(url)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await load();
      existing.removeWhere((h) => h.url == url);
      existing.insert(0, HistoryItem(
        url: url,
        title: title,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
      final trimmed = existing.take(_max).toList();
      await prefs.setStringList(_key, trimmed.map((h) => jsonEncode(h.toJson())).toList());
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
