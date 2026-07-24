import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/enums.dart';

/// A single refund request, created automatically whenever a customer
/// cancels a booking that had `paymentStatus == PaymentStatus.completed`
/// (the spec's "paid").
///
/// Firestore collection: `refundRequests` (doc id == orderId, so there can
/// only ever be one active refund request per booking).
class RefundRequestModel {
  final String orderId;
  final String customerId;
  final String tailorId;
  final String paymentIntentId;
  final CancellationReason cancellationReason;
  final String cancellationDescription;
  final RefundStatus refundStatus;
  final String? rejectionReason;
  final DateTime? requestedAt;
  final DateTime? refundedAt;

  // Denormalized display fields, written once at creation time so the
  // admin "Refund Requests" screen can render beautiful cards without an
  // N+1 lookup per card for customer/tailor/amount.
  final String customerName;
  final String tailorName;
  final double paidAmount;
  final String bookingStatus;

  const RefundRequestModel({
    required this.orderId,
    required this.customerId,
    required this.tailorId,
    required this.paymentIntentId,
    required this.cancellationReason,
    required this.cancellationDescription,
    required this.refundStatus,
    this.rejectionReason,
    this.requestedAt,
    this.refundedAt,
    this.customerName = '',
    this.tailorName = '',
    this.paidAmount = 0.0,
    this.bookingStatus = 'cancelled',
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    double num_(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    CancellationReason parseReason(dynamic v) {
      if (v is String) {
        try {
          return CancellationReason.values.byName(v);
        } catch (_) {}
      }
      return CancellationReason.other;
    }

    RefundStatus parseRefundStatus(dynamic v) {
      if (v is String) {
        try {
          return RefundStatus.values.byName(v);
        } catch (_) {}
      }
      return RefundStatus.requested;
    }

    return RefundRequestModel(
      orderId: json['orderId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      tailorId: json['tailorId']?.toString() ?? '',
      paymentIntentId: json['paymentIntentId']?.toString() ?? '',
      cancellationReason: parseReason(json['cancellationReason']),
      cancellationDescription: json['cancellationDescription']?.toString() ?? '',
      refundStatus: parseRefundStatus(json['refundStatus']),
      rejectionReason: json['rejectionReason']?.toString(),
      requestedAt: ts(json['requestedAt']),
      refundedAt: ts(json['refundedAt']),
      customerName: json['customerName']?.toString() ?? '',
      tailorName: json['tailorName']?.toString() ?? '',
      paidAmount: num_(json['paidAmount']),
      bookingStatus: json['bookingStatus']?.toString() ?? 'cancelled',
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'tailorId': tailorId,
      'paymentIntentId': paymentIntentId,
      'cancellationReason': cancellationReason.name,
      'cancellationDescription': cancellationDescription,
      'refundStatus': RefundStatus.requested.name,
      'requestedAt': FieldValue.serverTimestamp(),
      'customerName': customerName,
      'tailorName': tailorName,
      'paidAmount': paidAmount,
      'bookingStatus': bookingStatus,
    };
  }
}
