import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smartstitch/models/wallet_models.dart';

class RiderWalletTransactionService {
  static final RiderWalletTransactionService instance =
      RiderWalletTransactionService._();

  RiderWalletTransactionService._();

  final _db = FirebaseFirestore.instance;

  static const _kTransactions = 'wallet_transactions';
  static const _kWallets = 'rider_wallets';
  static const _kWithdrawals = 'withdrawal_requests';

  // ---------------------------------------------------------------------------
  // Earnings
  // ---------------------------------------------------------------------------

  Future<bool> addEarning({
    required String riderId,
    required double amount,
    required String orderId,
    required String description,
  }) async {
    try {
      if (await _isDuplicateEarning(riderId, orderId)) {
        debugPrint('🚫 Duplicate earning prevented for order: $orderId');
        return false;
      }

      await _db.runTransaction((tx) async {
        final walletRef = _db.collection(_kWallets).doc(riderId);
        final walletSnap = await tx.get(walletRef);

        final currentBalance =
            (walletSnap.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + amount;

        final txId = _db.collection(_kTransactions).doc().id;

        tx.set(
          _db.collection(_kTransactions).doc(txId),
          WalletTransaction(
            id: txId,
            riderId: riderId,
            orderId: orderId,
            type: TransactionType.earning,
            status: TransactionStatus.completed,
            amount: amount,
            title: 'Delivery Earning',
            description: description,
            createdAt: DateTime.now(),
          ).toJson(),
        );

        tx.set(
          walletRef,
          {
            'riderId': riderId,
            'availableBalance': newBalance,
            'lifetimeEarnings': FieldValue.increment(amount),
            'todayEarnings': FieldValue.increment(amount),
            'weekEarnings': FieldValue.increment(amount),
            'lastUpdated': Timestamp.now(),
          },
          SetOptions(merge: true),
        );
      });

      debugPrint('✅ Earning added: Rs. $amount for order $orderId');
      return true;
    } catch (e) {
      debugPrint('❌ addEarning failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Withdrawals
  // ---------------------------------------------------------------------------

  Future<bool> processWithdrawal({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required double amount,
    required PaymentMethod paymentMethod,
    required String accountTitle,
    required String accountNumber,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final walletRef = _db.collection(_kWallets).doc(riderId);
        final walletSnap = await tx.get(walletRef);

        if (!walletSnap.exists) throw Exception('Wallet not found');

        final currentBalance =
            (walletSnap.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0;

        if (currentBalance < amount) throw Exception('Insufficient balance');

        final newBalance = currentBalance - amount;

        final withdrawalId = _db.collection(_kWithdrawals).doc().id;
        tx.set(
          _db.collection(_kWithdrawals).doc(withdrawalId),
          WithdrawalRequest(
            id: withdrawalId,
            riderId: riderId,
            riderName: riderName,
            riderEmail: riderEmail,
            amount: amount,
            paymentMethod: paymentMethod,
            accountTitle: accountTitle,
            accountNumber: accountNumber,
            status: WithdrawalStatus.pending,
            requestedAt: DateTime.now(),
          ).toJson(),
        );

        final txId = _db.collection(_kTransactions).doc().id;
        tx.set(
          _db.collection(_kTransactions).doc(txId),
          WalletTransaction(
            id: txId,
            riderId: riderId,
            type: TransactionType.withdrawal,
            status: TransactionStatus.pending,
            amount: amount,
            title: 'Withdrawal Request',
            description: 'Withdrawal request submitted — Rs. $amount',
            createdAt: DateTime.now(),
          ).toJson(),
        );

        tx.update(walletRef, {
          'availableBalance': newBalance,
          'pendingWithdrawal': FieldValue.increment(amount),
          'lastUpdated': Timestamp.now(),
        });
      });

      debugPrint('✅ Withdrawal request created: Rs. $amount');
      return true;
    } catch (e) {
      debugPrint('❌ processWithdrawal failed: $e');
      return false;
    }
  }

  Future<bool> refundWithdrawal({
    required String riderId,
    required double amount,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final walletRef = _db.collection(_kWallets).doc(riderId);

        final txId = _db.collection(_kTransactions).doc().id;
        tx.set(
          _db.collection(_kTransactions).doc(txId),
          WalletTransaction(
            id: txId,
            riderId: riderId,
            type: TransactionType.refund,
            status: TransactionStatus.completed,
            amount: amount,
            title: 'Withdrawal Refund',
            description: 'Rejected withdrawal refunded to wallet',
            createdAt: DateTime.now(),
          ).toJson(),
        );

        tx.update(walletRef, {
          'availableBalance': FieldValue.increment(amount),
          'pendingWithdrawal': FieldValue.increment(-amount),
          'lastUpdated': Timestamp.now(),
        });
      });

      debugPrint('✅ Withdrawal refunded: Rs. $amount');
      return true;
    } catch (e) {
      debugPrint('❌ refundWithdrawal failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<double> getWalletBalance(String riderId) async {
    try {
      final snap = await _db.collection(_kWallets).doc(riderId).get();
      return (snap.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('❌ getWalletBalance failed: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>?> getWalletData(String riderId) async {
    try {
      return (await _db.collection(_kWallets).doc(riderId).get()).data();
    } catch (e) {
      debugPrint('❌ getWalletData failed: $e');
      return null;
    }
  }

  Stream<Map<String, dynamic>?> listenToWallet(String riderId) => _db
      .collection(_kWallets)
      .doc(riderId)
      .snapshots()
      .map((snap) => snap.data());

  Future<List<WalletTransaction>> getTransactionHistory(
    String riderId, {
    int limit = 50,
  }) async {
    try {
      final snap = await _db
          .collection(_kTransactions)
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((doc) => WalletTransaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ getTransactionHistory failed: $e');
      return [];
    }
  }

  Stream<List<WalletTransaction>> listenToTransactionHistory(
    String riderId, {
    int limit = 50,
  }) =>
      _db
          .collection(_kTransactions)
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => WalletTransaction.fromJson(d.data()))
              .toList());

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<bool> _isDuplicateEarning(String riderId, String orderId) async {
    try {
      final snap = await _db
          .collection(_kTransactions)
          .where('riderId', isEqualTo: riderId)
          .where('orderId', isEqualTo: orderId)
          .where('type', isEqualTo: 'earning')
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ _isDuplicateEarning failed: $e');
      return false;
    }
  }
}