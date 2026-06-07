enum MediaType { web, remote }

class MediaSource {
  final MediaType type;
  final String url;    // website url, or '' for remote
  final String title;  // free label for remote mode (e.g. "Netflix - اسم الفيلم")

  const MediaSource({
    required this.type,
    this.url = '',
    this.title = '',
  });

  String get typeString => type == MediaType.remote ? 'remote' : 'web';

  factory MediaSource.fromJson(Map<String, dynamic> j) => MediaSource(
        type: (j['type'] as String?) == 'remote' ? MediaType.remote : MediaType.web,
        url: j['url'] as String? ?? '',
        title: j['title'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'type': typeString,
        'url': url,
        'title': title,
      };
}
