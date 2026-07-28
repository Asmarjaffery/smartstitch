import 'package:smartstitch/models/enums.dart';

/// Typed wrapper for a `rider_wallets/{riderId}` document.
/// Field names match exactly what RiderOrderController.markDelivered()
/// already writes — this model doesn't change that write path, it just
/// gives the Wallet screen (and Compensation History) a safe read shape
/// instead of pulling raw maps out of snapshots.
class RiderWalletModel {
  final String riderId;
  final double availableBalance;
  final double pendingCompensation; // sum of not-yet-approved claims
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double lifetimeEarnings;
  final double pendingWithdrawal;
  final int totalTransactions;
  final DateTime? updatedAt;

  const RiderWalletModel({
    required this.riderId,
    this.availableBalance = 0,
    this.pendingCompensation = 0,
    this.todayEarnings = 0,
    this.weekEarnings = 0,
    this.monthEarnings = 0,
    this.lifetimeEarnings = 0,
    this.pendingWithdrawal = 0,
    this.totalTransactions = 0,
    this.updatedAt,
  });

  factory RiderWalletModel.empty(String riderId) =>
      RiderWalletModel(riderId: riderId);

  factory RiderWalletModel.fromJson(String riderId, Map<String, dynamic> json) {
    return RiderWalletModel(
      riderId: riderId,
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
      pendingCompensation:
          (json['pendingCompensation'] as num?)?.toDouble() ?? 0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0,
      weekEarnings: (json['weekEarnings'] as num?)?.toDouble() ?? 0,
      monthEarnings: (json['monthEarnings'] as num?)?.toDouble() ?? 0,
      lifetimeEarnings: (json['lifetimeEarnings'] as num?)?.toDouble() ?? 0,
      pendingWithdrawal: (json['pendingWithdrawal'] as num?)?.toDouble() ?? 0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'availableBalance': availableBalance,
        'pendingCompensation': pendingCompensation,
        'todayEarnings': todayEarnings,
        'weekEarnings': weekEarnings,
        'monthEarnings': monthEarnings,
        'lifetimeEarnings': lifetimeEarnings,
        'pendingWithdrawal': pendingWithdrawal,
        'totalTransactions': totalTransactions,
      };
}

/// Typed wrapper for a `wallet_transactions` document.
/// `type` is additive: existing docs written as type: 'earning' still parse
/// fine; new compensation payouts should be written with
/// type: 'compensation' so the Wallet screen can group/filter them.
class WalletTransactionModel {
  final String id;
  final String riderId;
  final String? orderId;
  final WalletTransactionType type;
  final String status; // 'paid' | 'pending' | 'failed' — kept as raw string
  final double amount;
  final String title;
  final String? description;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.riderId,
    this.orderId,
    required this.type,
    required this.status,
    required this.amount,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(String id, Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: id,
      riderId: json['riderId'] as String,
      orderId: json['orderId'] as String?,
      type: _parseType(json['type']),
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'orderId': orderId,
        'type': type.name,
        'status': status,
        'amount': amount,
        'title': title,
        'description': description,
      };

  static WalletTransactionType _parseType(dynamic v) {
    if (v is String) {
      try {
        return WalletTransactionType.values.byName(v);
      } catch (_) {}
    }
    return WalletTransactionType.earning;
  }
}