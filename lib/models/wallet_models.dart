import 'package:cloud_firestore/cloud_firestore.dart';

// ─── ENUMS ──────────────────────────────────────────────────

// 'compensation' added additively for rider delivery-exception payouts —
// existing 'earning' docs written by markDelivered() are untouched.
enum TransactionType { earning, withdrawal, bonus, refund, compensation }

enum TransactionStatus { completed, pending, cancelled, failed }

enum WithdrawalStatus { pending, approved, paid, rejected }

// JazzCash / EasyPaisa removed — withdrawals are now processed strictly via
// bank account / debit card (manually, by admin, since no payout gateway is
// wired up yet).
enum PaymentMethod { bankAccount }

// ─── EXTENSIONS ─────────────────────────────────────────────

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.earning:
        return 'Delivery Earnings';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.compensation:
        return 'Compensation';
    }
  }

  String get value => name;
}

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  String get value {
    return name;
  }
}

extension WithdrawalStatusX on WithdrawalStatus {
  String get label {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'Pending Review';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.paid:
        return 'Paid';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }

  String get value => name;
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.bankAccount:
        return 'Bank Account / Card';
    }
  }

  String get value => name;

  String get description {
    switch (this) {
      case PaymentMethod.bankAccount:
        return 'Direct transfer to your bank account or debit card';
    }
  }

  String get iconAsset {
    switch (this) {
      case PaymentMethod.bankAccount:
        return 'assets/icons/bank.png';
    }
  }
}

// ─── RIDER WALLET MODEL ─────────────────────────────────────

class RiderWallet {
  final String riderId;
  final double availableBalance;
  final double pendingWithdrawal;
  // Sum of compensation claims that are submitted/under review but not yet
  // approved — mirrors CompensationStatus.pending in enums.dart. Once admin
  // approves a claim, the payout is written as a `compensation` transaction
  // and this figure drops accordingly.
  final double pendingCompensation;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double lifetimeEarnings;
  final DateTime updatedAt;

  const RiderWallet({
    required this.riderId,
    required this.availableBalance,
    required this.pendingWithdrawal,
    this.pendingCompensation = 0,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.lifetimeEarnings,
    required this.updatedAt,
  });

  factory RiderWallet.empty(String riderId) => RiderWallet(
        riderId: riderId,
        availableBalance: 0,
        pendingWithdrawal: 0,
        pendingCompensation: 0,
        todayEarnings: 0,
        weekEarnings: 0,
        monthEarnings: 0,
        lifetimeEarnings: 0,
        updatedAt: DateTime.now(),
      );

  factory RiderWallet.fromJson(Map<String, dynamic> json) => RiderWallet(
        riderId: json['riderId'] ?? '',
        availableBalance: (json['availableBalance'] ?? 0).toDouble(),
        pendingWithdrawal: (json['pendingWithdrawal'] ?? 0).toDouble(),
        pendingCompensation: (json['pendingCompensation'] ?? 0).toDouble(),
        todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
        weekEarnings: (json['weekEarnings'] ?? 0).toDouble(),
        monthEarnings: (json['monthEarnings'] ?? 0).toDouble(),
        lifetimeEarnings: (json['lifetimeEarnings'] ?? 0).toDouble(),
        updatedAt: json['updatedAt'] is Timestamp
            ? (json['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'availableBalance': availableBalance,
        'pendingWithdrawal': pendingWithdrawal,
        'pendingCompensation': pendingCompensation,
        'todayEarnings': todayEarnings,
        'weekEarnings': weekEarnings,
        'monthEarnings': monthEarnings,
        'lifetimeEarnings': lifetimeEarnings,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  RiderWallet copyWith({
    double? availableBalance,
    double? pendingWithdrawal,
    double? pendingCompensation,
    double? todayEarnings,
    double? weekEarnings,
    double? monthEarnings,
    double? lifetimeEarnings,
    DateTime? updatedAt,
  }) =>
      RiderWallet(
        riderId: riderId,
        availableBalance: availableBalance ?? this.availableBalance,
        pendingWithdrawal: pendingWithdrawal ?? this.pendingWithdrawal,
        pendingCompensation: pendingCompensation ?? this.pendingCompensation,
        todayEarnings: todayEarnings ?? this.todayEarnings,
        weekEarnings: weekEarnings ?? this.weekEarnings,
        monthEarnings: monthEarnings ?? this.monthEarnings,
        lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─── WALLET TRANSACTION MODEL ────────────────────────────────

class WalletTransaction {
  final String id;
  final String riderId;
  final String? orderId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String title;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
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

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'] ?? '',
        riderId: json['riderId'] ?? '',
        orderId: json['orderId'],
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.earning,
        ),
        status: TransactionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TransactionStatus.pending,
        ),
        amount: (json['amount'] ?? 0).toDouble(),
        title: json['title'] ?? '',
        description: json['description'],
        createdAt: json['createdAt'] is Timestamp
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'orderId': orderId,
        'type': type.name,
        'status': status.name,
        'amount': amount,
        'title': title,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

// ─── WITHDRAWAL REQUEST MODEL ────────────────────────────────

class WithdrawalRequest {
  final String id;
  final String riderId;
  final String riderName;
  final String riderEmail;
  final double amount;
  final PaymentMethod paymentMethod;
  final String accountTitle;
  final String accountNumber;
  final String? notes;
  final WithdrawalStatus status;
  final String? adminNotes;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const WithdrawalRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderEmail,
    required this.amount,
    required this.paymentMethod,
    required this.accountTitle,
    required this.accountNumber,
    this.notes,
    required this.status,
    this.adminNotes,
    required this.requestedAt,
    this.processedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      WithdrawalRequest(
        id: json['id'] ?? '',
        riderId: json['riderId'] ?? '',
        riderName: json['riderName'] ?? '',
        riderEmail: json['riderEmail'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == json['paymentMethod'],
          orElse: () => PaymentMethod.bankAccount,
        ),
        accountTitle: json['accountTitle'] ?? '',
        accountNumber: json['accountNumber'] ?? '',
        notes: json['notes'],
        status: WithdrawalStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => WithdrawalStatus.pending,
        ),
        adminNotes: json['adminNotes'],
        requestedAt: json['requestedAt'] is Timestamp
            ? (json['requestedAt'] as Timestamp).toDate()
            : DateTime.now(),
        processedAt: json['processedAt'] is Timestamp
            ? (json['processedAt'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'riderEmail': riderEmail,
        'amount': amount,
        'paymentMethod': paymentMethod.name,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'notes': notes,
        'status': status.name,
        'adminNotes': adminNotes,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'processedAt':
            processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      };

  WithdrawalRequest copyWith({
    WithdrawalStatus? status,
    String? adminNotes,
    DateTime? processedAt,
  }) =>
      WithdrawalRequest(
        id: id,
        riderId: riderId,
        riderName: riderName,
        riderEmail: riderEmail,
        amount: amount,
        paymentMethod: paymentMethod,
        accountTitle: accountTitle,
        accountNumber: accountNumber,
        notes: notes,
        status: status ?? this.status,
        adminNotes: adminNotes ?? this.adminNotes,
        requestedAt: requestedAt,
        processedAt: processedAt ?? this.processedAt,
      );
}