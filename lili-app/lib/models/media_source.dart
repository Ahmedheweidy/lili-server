enum MediaType { youtube, direct, web, remote }

class MediaSource {
  final MediaType type;
  final String url;    // youtube url, direct/m3u8 url, website url, or '' for remote
  final String title;  // free label, mainly for remote mode (e.g. "Netflix - اسم الفيلم")

  const MediaSource({
    required this.type,
    this.url = '',
    this.title = '',
  });

  static MediaType _typeFromString(String s) {
    switch (s) {
      case 'youtube':
        return MediaType.youtube;
      case 'web':
        return MediaType.web;
      case 'remote':
        return MediaType.remote;
      default:
        return MediaType.direct;
    }
  }

  String get typeString {
    switch (type) {
      case MediaType.youtube:
        return 'youtube';
      case MediaType.web:
        return 'web';
      case MediaType.remote:
        return 'remote';
      case MediaType.direct:
        return 'direct';
    }
  }

  factory MediaSource.fromJson(Map<String, dynamic> j) => MediaSource(
        type: _typeFromString(j['type'] as String? ?? 'direct'),
        url: j['url'] as String? ?? '',
        title: j['title'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'type': typeString,
        'url': url,
        'title': title,
      };
}
