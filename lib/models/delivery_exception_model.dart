import 'package:smartstitch/models/enums.dart';


class DeliveryExceptionModel {
  final String id;
  final String orderId;
  final String customerId;
  final String riderId;
  final String? artistId;

  // ─── What happened ──────────────────────────────────────────────────
  final DeliveryExceptionReason reason;
  final String? notes; // required when reason == other
  final DateTime attemptTime;
  final int attemptCount;

  // Proof the rider actually called the customer before marking
  // "Customer Didn't Answer" — set only for that reason. ISO8601 string.
  final String? callAttemptedAt;

  // ─── Where it happened ──────────────────────────────────────────────
  final double? gpsLat;
  final double? gpsLng;
  final double? gpsAccuracyMeters;

  // Optional proof-of-attempt photos the rider can attach.
  final List<String> images;

  // ─── Money ───────────────────────────────────────────────────────────
  /// What SmartStitch owes the rider for the wasted trip, pending admin
  /// approval. Mirrors deliveryFee from OrderModel as the default suggestion.
  final double compensationAmount;
  final CompensationStatus compensationStatus;

  /// Unpaid COD delivery charge the customer still owes from this failed
  /// attempt (0 if the order isn't COD or nothing is outstanding).
  final double outstandingCharge;
  final OutstandingChargeAction outstandingChargeAction;

  /// New delivery fee quoted if/when the customer reschedules.
  final double? rescheduledDeliveryFee;

  // ─── Workflow state ──────────────────────────────────────────────────
  final DeliveryExceptionStatus status;
  final String? newRiderId; // set if admin reassigns
  final String? adminNote; // reject reason / waive reason / free note
  final String? reviewedByAdminId;
  final DateTime? reviewedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryExceptionModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.riderId,
    this.artistId,
    required this.reason,
    this.notes,
    required this.attemptTime,
    this.attemptCount = 1,
    this.callAttemptedAt,
    this.gpsLat,
    this.gpsLng,
    this.gpsAccuracyMeters,
    this.images = const [],
    this.compensationAmount = 0,
    this.compensationStatus = CompensationStatus.pending,
    this.outstandingCharge = 0,
    this.outstandingChargeAction = OutstandingChargeAction.none,
    this.rescheduledDeliveryFee,
    this.status = DeliveryExceptionStatus.submitted,
    this.newRiderId,
    this.adminNote,
    this.reviewedByAdminId,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasGpsData => gpsLat != null && gpsLng != null;
  bool get isCod => outstandingCharge > 0;
  bool get isPendingReview =>
      status != DeliveryExceptionStatus.resolved &&
      compensationStatus == CompensationStatus.pending;

  DeliveryExceptionModel copyWith({
    DeliveryExceptionStatus? status,
    CompensationStatus? compensationStatus,
    OutstandingChargeAction? outstandingChargeAction,
    double? rescheduledDeliveryFee,
    String? newRiderId,
    String? adminNote,
    String? reviewedByAdminId,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return DeliveryExceptionModel(
      id: id,
      orderId: orderId,
      customerId: customerId,
      riderId: riderId,
      artistId: artistId,
      reason: reason,
      notes: notes,
      attemptTime: attemptTime,
      attemptCount: attemptCount,
      callAttemptedAt: callAttemptedAt,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      gpsAccuracyMeters: gpsAccuracyMeters,
      images: images,
      compensationAmount: compensationAmount,
      compensationStatus: compensationStatus ?? this.compensationStatus,
      outstandingCharge: outstandingCharge,
      outstandingChargeAction:
          outstandingChargeAction ?? this.outstandingChargeAction,
      rescheduledDeliveryFee:
          rescheduledDeliveryFee ?? this.rescheduledDeliveryFee,
      status: status ?? this.status,
      newRiderId: newRiderId ?? this.newRiderId,
      adminNote: adminNote ?? this.adminNote,
      reviewedByAdminId: reviewedByAdminId ?? this.reviewedByAdminId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory DeliveryExceptionModel.fromJson(Map<String, dynamic> json) {
    return DeliveryExceptionModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      customerId: json['customerId'] as String,
      riderId: json['riderId'] as String,
      artistId: json['artistId'] as String?,
      reason: _parseReason(json['reason']),
      notes: json['notes'] as String?,
      attemptTime: DateTime.parse(json['attemptTime'] as String),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 1,
      callAttemptedAt: json['callAttemptedAt'] as String?,
      gpsLat: (json['gpsLat'] as num?)?.toDouble(),
      gpsLng: (json['gpsLng'] as num?)?.toDouble(),
      gpsAccuracyMeters: (json['gpsAccuracyMeters'] as num?)?.toDouble(),
      images: List<String>.from(json['images'] as List? ?? []),
      compensationAmount:
          (json['compensationAmount'] as num?)?.toDouble() ?? 0,
      compensationStatus: _parseCompensationStatus(json['compensationStatus']),
      outstandingCharge: (json['outstandingCharge'] as num?)?.toDouble() ?? 0,
      outstandingChargeAction:
          _parseOutstandingAction(json['outstandingChargeAction']),
      rescheduledDeliveryFee:
          (json['rescheduledDeliveryFee'] as num?)?.toDouble(),
      status: _parseStatus(json['status']),
      newRiderId: json['newRiderId'] as String?,
      adminNote: json['adminNote'] as String?,
      reviewedByAdminId: json['reviewedByAdminId'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'customerId': customerId,
        'riderId': riderId,
        'artistId': artistId,
        'reason': reason.name,
        'notes': notes,
        'attemptTime': attemptTime.toIso8601String(),
        'attemptCount': attemptCount,
        'callAttemptedAt': callAttemptedAt,
        'gpsLat': gpsLat,
        'gpsLng': gpsLng,
        'gpsAccuracyMeters': gpsAccuracyMeters,
        'images': images,
        'compensationAmount': compensationAmount,
        'compensationStatus': compensationStatus.name,
        'outstandingCharge': outstandingCharge,
        'outstandingChargeAction': outstandingChargeAction.name,
        'rescheduledDeliveryFee': rescheduledDeliveryFee,
        'status': status.name,
        'newRiderId': newRiderId,
        'adminNote': adminNote,
        'reviewedByAdminId': reviewedByAdminId,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static DeliveryExceptionReason _parseReason(dynamic v) {
    if (v is String) {
      try {
        return DeliveryExceptionReason.values.byName(v);
      } catch (_) {}
    }
    return DeliveryExceptionReason.other;
  }

  static DeliveryExceptionStatus _parseStatus(dynamic v) {
    if (v is String) {
      try {
        return DeliveryExceptionStatus.values.byName(v);
      } catch (_) {}
    }
    return DeliveryExceptionStatus.submitted;
  }

  static CompensationStatus _parseCompensationStatus(dynamic v) {
    if (v is String) {
      try {
        return CompensationStatus.values.byName(v);
      } catch (_) {}
    }
    return CompensationStatus.pending;
  }

  static OutstandingChargeAction _parseOutstandingAction(dynamic v) {
    if (v is String) {
      try {
        return OutstandingChargeAction.values.byName(v);
      } catch (_) {}
    }
    return OutstandingChargeAction.none;
  }
}