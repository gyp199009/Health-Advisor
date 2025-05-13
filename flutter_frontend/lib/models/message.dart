class MessageAttachment {
  final String recordId;
  
  MessageAttachment({
    required this.recordId,
  });
  
  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      recordId: json['recordId'],
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String? userId; // Can be null for system/assistant messages
  final String content;
  final String role; // 'user', 'assistant', 'system'
  final DateTime timestamp;
  final bool? error; // Optional field for error messages
  final List<MessageAttachment>? attachments; // Added to support file attachments

  Message({
    required this.id,
    required this.conversationId,
    this.userId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.error,
    this.attachments,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    List<MessageAttachment>? attachments;
    if (json['attachments'] != null) {
      attachments = List<MessageAttachment>.from(
        (json['attachments'] as List).map(
          (attachment) => MessageAttachment.fromJson(attachment),
        ),
      );
    }
    
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      userId: json['userId'],
      content: json['content'] ?? '',
      role: json['role'] ?? 'user',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp']).toUtc() // Ensure UTC time
          : DateTime.now().toUtc(),
      error: json['error'],
      attachments: attachments,
    );
  }
}