class Conversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'],
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt']).toUtc(),
      lastUpdated: DateTime.parse(json['lastUpdated']).toUtc(),
    );
  }
}