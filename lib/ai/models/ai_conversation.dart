import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_message.dart';

class AiConversation {
  final String id;
  final String userId;
  final String title;
  final String role; // UserRole.name
  final String language; // 'en', 'ur', 'roman_ur'
  final List<AiMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.role,
    required this.language,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  AiMessage? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  AiConversation copyWith({
    String? title,
    String? language,
    List<AiMessage>? messages,
    DateTime? updatedAt,
  }) =>
      AiConversation(
        id: id,
        userId: userId,
        title: title ?? this.title,
        role: role,
        language: language ?? this.language,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'role': role,
        'language': language,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    List<AiMessage> messages = [];
    try {
      final rawList = json['messages'] as List<dynamic>?;
      if (rawList != null) {
        messages = rawList
            .whereType<Map<String, dynamic>>()
            .map(AiMessage.fromJson)
            .toList();
      }
    } catch (_) {}

    return AiConversation(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'New Conversation',
      role: json['role'] as String? ?? 'customer',
      language: json['language'] as String? ?? 'en',
      messages: messages,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
