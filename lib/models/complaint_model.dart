import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String? orderId;
  final String subject;
  final String description;
  final String? issueType;
  final String? priority;
  final ComplaintStatus status;
  final String? adminResponse;
  final bool isAutoResponded;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final List<String> evidenceImages; 
  final List<String> evidenceVideos; 

  const ComplaintModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.subject,
    required this.description,
    this.issueType,
    this.priority,
    this.status = ComplaintStatus.pending,
    this.adminResponse,
    this.isAutoResponded = false,
    required this.submittedAt,
    this.resolvedAt,
    this.evidenceImages = const [], 
    this.evidenceVideos = const [], 
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      orderId: d['orderId']?.toString(),
      subject: d['subject'] ?? d['category'] ?? '',
      description: d['description'] ?? d['message'] ?? '',
      issueType: d['issueType'],
      priority: d['priority'],
      status: _parseStatus(d['status']),
      adminResponse: d['adminResponse'] ?? d['adminReply'],
      isAutoResponded: d['isAutoResponded'] ?? false,
      submittedAt: _parseDate(d['createdAt'] ?? d['submittedAt']),
      resolvedAt: _parseDate(d['resolvedAt']),
      evidenceImages: List<String>.from(d['evidenceImages'] ?? []), 
      evidenceVideos: List<String>.from(d['evidenceVideos'] ?? []), 
    );
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      userId: json['userId'],
      orderId: json['orderId'],
      subject: json['subject'],
      description: json['description'],
      issueType: json['issueType'],
      priority: json['priority'],
      status: ComplaintStatus.values.byName(json['status']),
      adminResponse: json['adminResponse'],
      isAutoResponded: json['isAutoResponded'] ?? false,
      submittedAt: DateTime.parse(json['submittedAt']),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      evidenceImages: List<String>.from(json['evidenceImages'] ?? []), 
      evidenceVideos: List<String>.from(json['evidenceVideos'] ?? []), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'subject': subject,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status.name,
      'adminResponse': adminResponse,
      'isAutoResponded': isAutoResponded,
      'createdAt': submittedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'evidenceImages': evidenceImages, 
      'evidenceVideos': evidenceVideos, 
    };
  }

  static ComplaintStatus _parseStatus(String? status) {
    switch (status) {
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'in_progress':
      case 'inProgress':
        return ComplaintStatus.inProgress;
      case 'pending':
      default:
        return ComplaintStatus.pending;
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

class ComplaintStat {
  final String title;
  final int count;
  final Color color;

  ComplaintStat(this.title, this.count, this.color);
}