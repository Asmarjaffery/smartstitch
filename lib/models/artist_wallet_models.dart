import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/wallet_models.dart';
// Shared enums from wallet_models — no duplication
export 'package:smartstitch/models/wallet_models.dart'
    show TransactionType, TransactionStatus, WithdrawalStatus, PaymentMethod,
         TransactionStatusX, WithdrawalStatusX, PaymentMethodX;

// ─── ARTIST WALLET ────────────────────────────────────────────────────────────

class ArtistWallet {
  final String artistId;
  final double availableBalance;
  final double pendingWithdrawal;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double lifetimeEarnings;
  final DateTime updatedAt;

  const ArtistWallet({
    required this.artistId,
    required this.availableBalance,
    required this.pendingWithdrawal,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.lifetimeEarnings,
    required this.updatedAt,
  });

  factory ArtistWallet.empty(String artistId) => ArtistWallet(
        artistId: artistId,
        availableBalance: 0,
        pendingWithdrawal: 0,
        todayEarnings: 0,
        weekEarnings: 0,
        monthEarnings: 0,
        lifetimeEarnings: 0,
        updatedAt: DateTime.now(),
      );

  factory ArtistWallet.fromJson(Map<String, dynamic> j) => ArtistWallet(
        artistId: j['artistId'] ?? '',
        availableBalance: (j['availableBalance'] ?? 0).toDouble(),
        pendingWithdrawal: (j['pendingWithdrawal'] ?? 0).toDouble(),
        todayEarnings: (j['todayEarnings'] ?? 0).toDouble(),
        weekEarnings: (j['weekEarnings'] ?? 0).toDouble(),
        monthEarnings: (j['monthEarnings'] ?? 0).toDouble(),
        lifetimeEarnings: (j['lifetimeEarnings'] ?? 0).toDouble(),
        updatedAt: j['updatedAt'] is Timestamp
            ? (j['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'artistId': artistId,
        'availableBalance': availableBalance,
        'pendingWithdrawal': pendingWithdrawal,
        'todayEarnings': todayEarnings,
        'weekEarnings': weekEarnings,
        'monthEarnings': monthEarnings,
        'lifetimeEarnings': lifetimeEarnings,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

// ─── ARTIST WALLET TRANSACTION ────────────────────────────────────────────────

class ArtistWalletTransaction {
  final String id;
  final String artistId;
  final String? orderId;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String title;
  final String? description;
  final DateTime createdAt;

  const ArtistWalletTransaction({
    required this.id,
    required this.artistId,
    this.orderId,
    required this.type,
    required this.status,
    required this.amount,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory ArtistWalletTransaction.fromJson(Map<String, dynamic> j) =>
      ArtistWalletTransaction(
        id: j['id'] ?? '',
        artistId: j['artistId'] ?? '',
        orderId: j['orderId'],
        type: TransactionType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => TransactionType.earning,
        ),
        status: TransactionStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => TransactionStatus.pending,
        ),
        amount: (j['amount'] ?? 0).toDouble(),
        title: j['title'] ?? '',
        description: j['description'],
        createdAt: j['createdAt'] is Timestamp
            ? (j['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}

// ─── ARTIST WITHDRAWAL REQUEST ────────────────────────────────────────────────
//
// No bank fields here anymore (bankName / accountTitle / accountNumber).
// Payout destination lives entirely on the artist's Stripe Connect account
// — this app never sees or stores raw bank details.

class ArtistWithdrawalRequest {
  final String id;
  final String artistId;
  final String artistName;
  final String artistEmail;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? notes;
  final WithdrawalStatus status;
  final String? adminNotes;
  final DateTime requestedAt;
  final DateTime? processedAt;

  const ArtistWithdrawalRequest({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.artistEmail,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.status,
    this.adminNotes,
    required this.requestedAt,
    this.processedAt,
  });

  factory ArtistWithdrawalRequest.fromJson(Map<String, dynamic> j) =>
      ArtistWithdrawalRequest(
        id: j['id'] ?? '',
        artistId: j['artistId'] ?? '',
        artistName: j['artistName'] ?? '',
        artistEmail: j['artistEmail'] ?? '',
        amount: (j['amount'] ?? 0).toDouble(),
        paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == j['paymentMethod'],
          orElse: () => PaymentMethod.bankAccount,
        ),
        notes: j['notes'],
        status: WithdrawalStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => WithdrawalStatus.pending,
        ),
        adminNotes: j['adminNotes'],
        requestedAt: j['requestedAt'] is Timestamp
            ? (j['requestedAt'] as Timestamp).toDate()
            : DateTime.now(),
        processedAt: j['processedAt'] is Timestamp
            ? (j['processedAt'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'artistId': artistId,
        'artistName': artistName,
        'artistEmail': artistEmail,
        'amount': amount,
        'paymentMethod': paymentMethod.name,
        'notes': notes,
        'status': status.name,
        'adminNotes': adminNotes,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'processedAt':
            processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      };

  ArtistWithdrawalRequest copyWith({
    WithdrawalStatus? status,
    String? adminNotes,
    DateTime? processedAt,
  }) =>
      ArtistWithdrawalRequest(
        id: id,
        artistId: artistId,
        artistName: artistName,
        artistEmail: artistEmail,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
        status: status ?? this.status,
        adminNotes: adminNotes ?? this.adminNotes,
        requestedAt: requestedAt,
        processedAt: processedAt ?? this.processedAt,
      );
}