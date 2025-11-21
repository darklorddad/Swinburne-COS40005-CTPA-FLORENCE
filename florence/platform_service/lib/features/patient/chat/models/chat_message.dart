class ChatMessage {
  final String? id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.context,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['message_id'], // Handle both DB and API response formats
      role: json['role'] ?? 'system',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      context: json['context'] ?? json['context_used'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}
