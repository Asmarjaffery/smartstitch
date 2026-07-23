import 'enums.dart';

class WithdrawRequestModel {
  final String id;
  final String requesterId;  // artistId or riderId
  final UserRole requesterRole;
  final double amount;
  final String bankName;
  final String accountTitle;
  final String accountNumber;
  final WithdrawStatus status;
  final String? adminNote;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const WithdrawRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterRole,
    required this.amount,
    required this.bankName,
    required this.accountTitle,
    required this.accountNumber,
    this.status = WithdrawStatus.pending,
    this.adminNote,
    required this.requestedAt,
    this.processedAt,
  });

  factory WithdrawRequestModel.fromJson(Map<String, dynamic> json) =>
      WithdrawRequestModel(
        id: json['id'] as String,
        requesterId: json['requesterId'] as String,
        requesterRole: UserRole.values.byName(json['requesterRole'] as String),
        amount: (json['amount'] as num).toDouble(),
        bankName: json['bankName'] as String,
        accountTitle: json['accountTitle'] as String,
        accountNumber: json['accountNumber'] as String,
        status: WithdrawStatus.values.byName(json['status'] as String),
        adminNote: json['adminNote'] as String?,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        processedAt: json['processedAt'] != null
            ? DateTime.parse(json['processedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterId': requesterId,
        'requesterRole': requesterRole.name,
        'amount': amount,
        'bankName': bankName,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'status': status.name,
        'adminNote': adminNote,
        'requestedAt': requestedAt.toIso8601String(),
        'processedAt': processedAt?.toIso8601String(),
      };
}