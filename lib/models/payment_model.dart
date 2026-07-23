import 'enums.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String customerId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? gatewayResponse;
  final bool isRefunded;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.gatewayResponse,
    this.isRefunded = false,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        customerId: json['customerId'] as String,
        amount: (json['amount'] as num).toDouble(),
        method: PaymentMethod.values.byName(json['method'] as String),
        status: PaymentStatus.values.byName(json['status'] as String),
        transactionId: json['transactionId'] as String?,
        gatewayResponse: json['gatewayResponse'] as String?,
        isRefunded: json['isRefunded'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'customerId': customerId,
        'amount': amount,
        'method': method.name,
        'status': status.name,
        'transactionId': transactionId,
        'gatewayResponse': gatewayResponse,
        'isRefunded': isRefunded,
        'createdAt': createdAt.toIso8601String(),
      };
}