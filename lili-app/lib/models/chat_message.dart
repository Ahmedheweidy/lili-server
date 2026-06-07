class ChatMessage {
  final String id;
  final String username;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'].toString(),
        username: j['username'] as String,
        text: j['text'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch((j['timestamp'] as num).toInt()),
      );
}
