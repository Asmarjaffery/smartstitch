import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// A notification delivered to a specific user (customer, rider, or vendor).
class NotificationModel {
  final String id;
  final String recipientId;
  final UserRole recipientRole;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      recipientRole: UserRole.values.byName(
        (json['recipientRole'] as String?) ?? 'customer',
      ),
      type: NotificationType.values.byName(
        (json['type'] as String?) ?? 'general',
      ),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientId': recipientId,
        'recipientRole': recipientRole.name,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt), // store as Firestore Timestamp
      };

  // ---------------------------------------------------------------------------
  // Mutation helpers
  // ---------------------------------------------------------------------------

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    UserRole? recipientRole,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        recipientId: recipientId ?? this.recipientId,
        recipientRole: recipientRole ?? this.recipientRole,
        type: type ?? this.type,
        title: title ?? this.title,
        body: body ?? this.body,
        data: data ?? this.data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );

  NotificationModel markAsRead() => copyWith(isRead: true);

  // ---------------------------------------------------------------------------
  // Equality & debugging
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NotificationModel(id: $id, type: $type, recipientRole: $recipientRole, isRead: $isRead)';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Handles both Firestore [Timestamp] and ISO-8601 [String] values.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}