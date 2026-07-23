import 'package:cloud_firestore/cloud_firestore.dart';

enum AiMessageRole { user, assistant }

class AiMessage {
  final String id;
  final AiMessageRole role;
  final String text;
  final DateTime timestamp;
  final bool isError;
  final String? actionType;
  final String? actionValue;
  // ✅ NEW: generic extra data for rich actions — e.g. for actionType
  // 'call' this carries the rider's name/photo so the chat bubble can
  // render a proper contact card instead of just a plain button.
  final Map<String, String>? actionMeta;

  const AiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
    this.actionType,
    this.actionValue,
    this.actionMeta,
  });

  bool get isUser => role == AiMessageRole.user;

  Map<String, String> toHistoryMap() => {
        'role': role == AiMessageRole.user ? 'user' : 'model',
        'text': text,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
        'actionType': actionType,
        'actionValue': actionValue,
        'actionMeta': actionMeta,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        id: json['id'] as String? ?? '',
        role: AiMessageRole.values.byName(json['role'] as String? ?? 'user'),
        text: json['text'] as String? ?? '',
        timestamp: _parseDate(json['timestamp']),
        isError: json['isError'] as bool? ?? false,
        actionType: json['actionType'] as String?,
        actionValue: json['actionValue'] as String?,
        actionMeta: (json['actionMeta'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}