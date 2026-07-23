import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message_model.dart';

class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── Other user info (fallback) ───────────────────────────────────────────
  final String? otherUserName;
  final String? otherUserImage;
  final bool isOtherOnline;
  final Map<String, String> participantNames;

  final Map<String, String> participantImages;

  const ChatRoomModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.otherUserName,
    this.otherUserImage,
    this.isOtherOnline = false,
    this.participantNames = const {},
    this.participantImages = const {},
  });

  // ─── Convenience getters ──────────────────────────────────────────────────
  String? get lastMessageText => lastMessage?.text;
  DateTime? get lastMessageAt => lastMessage?.sentAt ?? updatedAt;

  int getUnreadCount(String userId) => unreadCount;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    // ─── Parse unreadCount ─────────────────────────────────────────────────
    int parsedUnread = 0;
    final raw = json['unreadCount'];
    if (raw is int) {
      parsedUnread = raw;
    } else if (raw is Map) {
      parsedUnread =
          raw.values.fold(0, (a, b) => a + ((b as num).toInt()));
    }

    // ─── Parse lastMessage ─────────────────────────────────────────────────
    ChatMessageModel? lastMsg;
    if (json['lastMessage'] != null && json['lastMessage'] is Map) {
      try {
        lastMsg = ChatMessageModel.fromJson(
            Map<String, dynamic>.from(json['lastMessage'] as Map));
      } catch (_) {
        lastMsg = null;
      }
    }

    // ─── Parse participantNames ────────────────────────────────────────────
    Map<String, String> names = {};
    if (json['participantNames'] is Map) {
      names = Map<String, String>.from(
          (json['participantNames'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ));
    }

    // ─── Parse participantImages ───────────────────────────────────────────
    Map<String, String> images = {};
    if (json['participantImages'] is Map) {
      images = Map<String, String>.from(
          (json['participantImages'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ));
    }

    return ChatRoomModel(
      id: json['id'] as String? ?? '',
      participantIds:
          List<String>.from(json['participantIds'] as List? ?? []),
      lastMessage: lastMsg,
      unreadCount: parsedUnread,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      otherUserName: json['otherUserName'] as String?,
      otherUserImage: json['otherUserImage'] as String?,
      isOtherOnline: json['isOtherOnline'] as bool? ?? false,
      participantNames: names,
      participantImages: images,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': unreadCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'otherUserName': otherUserName,
        'otherUserImage': otherUserImage,
        'isOtherOnline': isOtherOnline,
        'participantNames': participantNames,
        'participantImages': participantImages,
      };

  ChatRoomModel copyWith({
    String? otherUserName,
    String? otherUserImage,
    bool? isOtherOnline,
    ChatMessageModel? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    Map<String, String>? participantNames,
    Map<String, String>? participantImages,
  }) {
    return ChatRoomModel(
      id: id,
      participantIds: participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserImage: otherUserImage ?? this.otherUserImage,
      isOtherOnline: isOtherOnline ?? this.isOtherOnline,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
    );
  }
}