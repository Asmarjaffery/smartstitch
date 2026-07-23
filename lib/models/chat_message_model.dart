import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final int? durationSeconds;
  final double? latitude;   // 👈 naya
  final double? longitude;  // 👈 naya
  final bool isRead;
  final DateTime sentAt;

  const ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.durationSeconds,
    this.latitude,
    this.longitude,
    this.isRead = false,
    required this.sentAt,
  });

  // ─── FIX: safely parse Timestamp OR String ────────────────────────────────
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String? ?? '',
        chatRoomId: json['chatRoomId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        receiverId: json['receiverId'] as String? ?? '',
        // FIX: safely parse type — fallback to text if unknown
        type: _parseType(json['type']),
        text: json['text'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        // FIX: durationSeconds may come as int or double from Firestore
        durationSeconds: json['durationSeconds'] != null
            ? (json['durationSeconds'] as num).toInt()
            : null,
        latitude: json['latitude'] != null
            ? (json['latitude'] as num).toDouble()
            : null,
        longitude: json['longitude'] != null
            ? (json['longitude'] as num).toDouble()
            : null,
        isRead: json['isRead'] as bool? ?? false,
        // FIX: use _parseDate so Timestamp doesn't crash
        sentAt: _parseDate(json['sentAt']),
      );

  static MessageType _parseType(dynamic value) {
    if (value == null) return MessageType.text;
    try {
      return MessageType.values.byName(value as String);
    } catch (_) {
      return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'receiverId': receiverId,
        'type': type.name,
        'text': text,
        'mediaUrl': mediaUrl,
        'durationSeconds': durationSeconds,
        'latitude': latitude,
        'longitude': longitude,
        'isRead': isRead,
        'sentAt': sentAt.toIso8601String(),
      };
}