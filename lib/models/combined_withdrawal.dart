import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_models.dart' show WithdrawalRequest, PaymentMethodX;

/// Which side of the marketplace this withdrawal belongs to — riders
/// withdraw from `withdrawal_requests` / `rider_wallets`, artists withdraw
/// from `artist_withdrawals` / `artist_wallets`. The admin screen needs to
/// show both in one merged list, so every row is tagged with its role.
enum WithdrawalRole { rider, artist }

/// A single row in the admin's combined withdrawal list — a thin,
/// UI-facing wrapper that looks the same whether the underlying request
/// came from a rider or an artist.
///
/// `status` is kept as a raw String ('pending' / 'approved' / 'paid' /
/// 'rejected') rather than the WithdrawalStatus enum, since the admin
/// screen only ever compares it against string literals.
class CombinedWithdrawal {
  final String id;
  final WithdrawalRole role;
  final String userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String status;
  final String? paymentMethodLabel;
  final String accountTitle;
  final String accountNumber;
  final String? adminNotes;
  final DateTime requestedAt;

  const CombinedWithdrawal({
    required this.id,
    required this.role,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.status,
    this.paymentMethodLabel,
    required this.accountTitle,
    required this.accountNumber,
    this.adminNotes,
    required this.requestedAt,
  });

  /// Builds a [CombinedWithdrawal] from a rider's [WithdrawalRequest]
  /// (defined in wallet_models.dart).
  factory CombinedWithdrawal.fromRider(WithdrawalRequest r) =>
      CombinedWithdrawal(
        id: r.id,
        role: WithdrawalRole.rider,
        userId: r.riderId,
        userName: r.riderName,
        userEmail: r.riderEmail,
        amount: r.amount,
        status: r.status.name,
        paymentMethodLabel: r.paymentMethod.label,
        accountTitle: r.accountTitle,
        accountNumber: r.accountNumber,
        adminNotes: r.adminNotes,
        requestedAt: r.requestedAt,
      );

  /// Builds a [CombinedWithdrawal] straight from a raw Firestore doc in
  /// the `artist_withdrawals` collection.
  ///
  /// ⚠️ Adjust the field names below if your ArtistWithdrawalRequest /
  /// artist_withdrawals documents use different keys — I don't have that
  /// model's exact shape, so this assumes it mirrors the rider one
  /// (artistId/artistName/artistEmail instead of riderId/riderName/riderEmail).
  factory CombinedWithdrawal.fromArtistDoc(
      String docId, Map<String, dynamic> data) {
    return CombinedWithdrawal(
      id: docId,
      role: WithdrawalRole.artist,
      userId: data['artistId'] ?? '',
      userName: data['artistName'] ?? '',
      userEmail: data['artistEmail'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      paymentMethodLabel: data['paymentMethod'],
      accountTitle: data['accountTitle'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      adminNotes: data['adminNotes'],
      requestedAt: data['requestedAt'] is Timestamp
          ? (data['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}