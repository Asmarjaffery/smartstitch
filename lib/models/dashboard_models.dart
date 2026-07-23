import 'package:cloud_firestore/cloud_firestore.dart';

class RecentOrderModel {
  final String orderId;
  final String customerName;
  final String artistName;
  final String? riderName;
  final double amount;
  final String status;
  final DateTime date;

  RecentOrderModel({
    required this.orderId,
    required this.customerName,
    required this.artistName,
    this.riderName,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory RecentOrderModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final ts = map['createdAt'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return RecentOrderModel(
      orderId: id,
      customerName: map['customerName'] ?? 'Unknown',
      artistName: map['artistName'] ?? 'Unassigned',
      riderName: map['riderName'],
      amount: (map['totalAmount'] ?? map['servicePrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      date: parsedDate,
    );
  }
}

class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime date;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final ts = map['createdAt'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ReviewModel(
      id: id,
      customerName: map['customerName'] ?? 'Anonymous',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      date: parsedDate,
    );
  }
}

class ComplaintModel {
  final String id;
  final String title;
  final String status;
  final DateTime date;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
  });

  factory ComplaintModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final ts = map['createdAt'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ComplaintModel(
      id: id,
      title: map['title'] ?? map['subject'] ?? 'Complaint',
      status: map['status'] ?? 'open',
      date: parsedDate,
    );
  }
}

class PaymentModel {
  final String id;
  final String userName;
  final double amount;
  final String method;
  final String status;
  final DateTime date;

  PaymentModel({
    required this.id,
    required this.userName,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final ts = map['createdAt'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return PaymentModel(
      id: id,
      userName: map['userName'] ?? 'Unknown',
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] ?? map['paymentMethod'] ?? 'N/A',
      status: map['status'] ?? 'pending',
      date: parsedDate,
    );
  }
}

class AppointmentModel {
  final String id;
  final String customerName;
  final String serviceName;
  final DateTime scheduledAt;

  AppointmentModel({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.scheduledAt,
  });

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final ts = map['scheduledAt'] ?? map['appointmentDate'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AppointmentModel(
      id: id,
      customerName: map['customerName'] ?? 'Customer',
      serviceName: map['serviceName'] ?? 'Service',
      scheduledAt: parsedDate,
    );
  }
}

class ActivityModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final String type;

  ActivityModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  factory ActivityModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate;
    final ts = map['createdAt'];
    if (ts is Timestamp) {
      parsedDate = ts.toDate();
    } else if (ts is String) {
      parsedDate = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ActivityModel(
      id: id,
      title: map['title'] ?? 'Activity',
      subtitle: map['subtitle'] ?? '',
      time: parsedDate,
      type: map['type'] ?? 'general',
    );
  }
}