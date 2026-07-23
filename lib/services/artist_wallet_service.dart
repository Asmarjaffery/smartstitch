import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstitch/models/artist_wallet_models.dart';
import 'package:smartstitch/services/wallet_brevo_service.dart';

class ArtistWalletService {
  static final ArtistWalletService instance = ArtistWalletService._();
  ArtistWalletService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference get _wallets => _db.collection('artist_wallets');
  CollectionReference get _withdrawals => _db.collection('artist_withdrawals');
  CollectionReference _txns(String artistId) =>
      _wallets.doc(artistId).collection('transactions');

  String _dateStr(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Maps a WithdrawalStatus (pending/approved/paid/rejected) to the
  /// correct TransactionStatus (completed/pending/cancelled/failed) so the
  /// linked "transactions" record always stores a value that actually
  /// exists in the TransactionStatus enum. Writing `newStatus.name`
  /// directly (e.g. "paid") used to silently fail to parse back and fall
  /// back to TransactionStatus.pending — this is the fix for that bug.
  TransactionStatus _mapToTransactionStatus(WithdrawalStatus s) {
    switch (s) {
      case WithdrawalStatus.paid:
        return TransactionStatus.completed;
      case WithdrawalStatus.rejected:
        return TransactionStatus.failed;
      case WithdrawalStatus.approved:
      case WithdrawalStatus.pending:
        return TransactionStatus.pending;
    }
  }

  Future<void> syncWalletFromBookings({required String artistId}) async {
    try {
      final bookingsSnap = await _db
          .collection('bookings')
          .where('artistId', isEqualTo: artistId)
          .get();

      double lifetime = 0;
      double todayE = 0;
      double weekE = 0;
      double monthE = 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      for (final doc in bookingsSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final status = d['status'] ?? '';
        final isCompleted = status == 'delivered' ||
            status == 'completed' ||
            status == 'approved'||
            status == 'stitchingCompleted';

        if (!isCompleted) continue;

        final price = ((d['servicePrice'] ?? 0) as num).toDouble();
        final earning = price * 0.85;

        // Use the completion date (when the earning actually landed), not
        // appointmentDate (when the booking was scheduled). A booking made
        // weeks ago but delivered/paid today should count toward today's /
        // this week's / this month's earnings — appointmentDate was
        // causing todayEarnings/weekEarnings/monthEarnings to stay 0 while
        // lifetimeEarnings (which isn't date-filtered) kept growing.
        DateTime date = now;
        final raw = d['deliveredAt'] ?? d['completedAt'] ?? d['createdAt'];
        if (raw is Timestamp) {
          date = raw.toDate();
        } else if (raw is String) {
          date = DateTime.tryParse(raw) ?? now;
        }

        lifetime += earning;
        if (!date.isBefore(todayStart)) todayE += earning;
        if (!date.isBefore(weekStart)) weekE += earning;
        if (!date.isBefore(monthStart)) monthE += earning;
      }

      final pendingWdSnap = await _withdrawals
          .where('artistId', isEqualTo: artistId)
          .where('status', isEqualTo: 'pending')
          .get();

      double pendingWd = 0;
      for (final doc in pendingWdSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        pendingWd += ((d['amount'] ?? 0) as num).toDouble();
      }

      final approvedSnap = await _withdrawals
          .where('artistId', isEqualTo: artistId)
          .where('status', isEqualTo: 'paid')
          .get();

      double withdrawn = 0;
      for (final doc in approvedSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        withdrawn += ((d['amount'] ?? 0) as num).toDouble();
      }

      final available =
          (lifetime - withdrawn - pendingWd).clamp(0, double.infinity);

      await _wallets.doc(artistId).set({
        'artistId': artistId,
        'availableBalance': available,
        'pendingWithdrawal': pendingWd,
        'todayEarnings': todayE,
        'weekEarnings': weekE,
        'monthEarnings': monthE,
        'lifetimeEarnings': lifetime,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      debugPrint('✅ Wallet synced: available=$available, lifetime=$lifetime');
    } catch (e) {
      debugPrint('❌ syncWalletFromBookings error: $e');
    }
  }

  Stream<ArtistWallet> watchWallet(String artistId) {
    return _wallets.doc(artistId).snapshots().map((snap) {
      if (!snap.exists) return ArtistWallet.empty(artistId);
      return ArtistWallet.fromJson({
        ...snap.data() as Map<String, dynamic>,
        'artistId': artistId,
      });
    });
  }

  Stream<List<ArtistWalletTransaction>> watchTransactions(String artistId) {
    return _txns(artistId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ArtistWalletTransaction.fromJson(
                {...d.data() as Map<String, dynamic>, 'id': d.id}))
            .toList());
  }

  Stream<List<ArtistWithdrawalRequest>> watchWithdrawalHistory(
      String artistId) {
    return _withdrawals
        .where('artistId', isEqualTo: artistId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ArtistWithdrawalRequest.fromJson(
                {...d.data() as Map<String, dynamic>, 'id': d.id}))
            .toList());
  }

  Future<void> creditEarning({
    required String artistId,
    required String orderId,
    required double amount,
    String title = 'Order Earning',
  }) async {
    // ✅ Idempotency guard (booking-level flag): if this booking document
    // already has `earningCredited: true`, skip immediately — this
    // protects against creditEarning() being called more than once for
    // the same booking (e.g. status update retried, race condition, or
    // manual re-trigger), without needing to wait for the transactions
    // query below.
    final bookingDoc = await _db.collection('bookings').doc(orderId).get();

    if (bookingDoc.exists) {
      final data = bookingDoc.data()!;
      if ((data['earningCredited'] ?? false) == true) {
        debugPrint('⚠️ Earning already credited.');
        return;
      }
    }

    final existing = await _txns(artistId)
        .where('orderId', isEqualTo: orderId)
        .where('type', isEqualTo: 'earning')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      debugPrint('⚠️ Earning already credited for order $orderId');
      return;
    }

    final now = Timestamp.now();
    final batch = _db.batch();

    final walletRef = _wallets.doc(artistId);
    final walletSnap = await walletRef.get();
    if (!walletSnap.exists) {
      batch.set(walletRef, {
        'artistId': artistId,
        'availableBalance': 0,
        'pendingWithdrawal': 0,
        'todayEarnings': 0,
        'weekEarnings': 0,
        'monthEarnings': 0,
        'lifetimeEarnings': 0,
        'updatedAt': now,
      });
    }

    batch.update(walletRef, {
      'availableBalance': FieldValue.increment(amount),
      'lifetimeEarnings': FieldValue.increment(amount),
      'todayEarnings': FieldValue.increment(amount),
      'weekEarnings': FieldValue.increment(amount),
      'monthEarnings': FieldValue.increment(amount),
      'updatedAt': now,
    });

    final txRef = _txns(artistId).doc();
    batch.set(txRef, {
      'artistId': artistId,
      'orderId': orderId,
      'type': 'earning',
      'status': 'completed',
      'amount': amount,
      'title': title,
      'description':
          'Earning from order #${orderId.substring(0, 8).toUpperCase()}',
      'createdAt': now,
    });

    await batch.commit();

    // ✅ Mark the booking as credited so any future call for this same
    // orderId short-circuits immediately via the guard at the top.
    await _db.collection('bookings').doc(orderId).update({
      'earningCredited': true,
      'creditedAt': Timestamp.now(),
    });
  }

  Future<ArtistWithdrawalRequest> createWithdrawalRequest({
    required String artistId,
    required String artistName,
    required String artistEmail,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final now = Timestamp.now();
    final batch = _db.batch();

    final reqRef = _withdrawals.doc();
    final reqData = {
      'artistId': artistId,
      'artistName': artistName,
      'artistEmail': artistEmail,
      'amount': amount,
      'paymentMethod': paymentMethod.name,

      'notes': notes,
      'status': 'pending',
      'adminNotes': null,
      'requestedAt': now,
      'processedAt': null,
    };
    batch.set(reqRef, reqData);

    final walletRef = _wallets.doc(artistId);
    batch.update(walletRef, {
      'availableBalance': FieldValue.increment(-amount),
      'pendingWithdrawal': FieldValue.increment(amount),
      'updatedAt': now,
    });

    final txRef = _txns(artistId).doc();
    batch.set(txRef, {
      'artistId': artistId,
      'orderId': null,
      'withdrawalId': reqRef.id,
      'type': 'withdrawal',
      'status': 'pending',
      'amount': amount,
      'title': 'Withdrawal Request',
      'createdAt': now,
    });

    await batch.commit();

    WalletBrevoService.sendWithdrawalRequested(
      toEmail: artistEmail,
      riderName: artistName,
      withdrawalId: reqRef.id.substring(0, 8).toUpperCase(),
      amount: amount.toStringAsFixed(0),
      paymentMethod: paymentMethod.label,
      requestedDate: _dateStr(DateTime.now()),
    );

    return ArtistWithdrawalRequest.fromJson({...reqData, 'id': reqRef.id});
  }

  Future<void> updateWithdrawalStatus({
    required String withdrawalId,
    required String artistId,
    required double amount,
    required WithdrawalStatus newStatus,
    String? adminNotes,
    String artistEmail = '',
    String artistName = '',
  }) async {
    final now = Timestamp.now();
    final batch = _db.batch();

    final reqRef = _withdrawals.doc(withdrawalId);
    batch.update(reqRef, {
      'status': newStatus.name,
      'adminNotes': adminNotes,
      'processedAt': now,
    });

    var linkedTxnSnap = await _txns(artistId)
        .where('withdrawalId', isEqualTo: withdrawalId)
        .limit(1)
        .get();

    if (linkedTxnSnap.docs.isEmpty) {
      linkedTxnSnap = await _txns(artistId)
          .where('type', isEqualTo: 'withdrawal')
          .where('status', isEqualTo: 'pending')
          .where('amount', isEqualTo: amount)
          .limit(1)
          .get();
    }

    if (linkedTxnSnap.docs.isNotEmpty) {
      // ✅ FIX: map WithdrawalStatus -> TransactionStatus instead of
      // writing newStatus.name directly (e.g. "paid" is not a valid
      // TransactionStatus, so it used to silently fall back to "pending"
      // when read back — that's why Recent Transactions showed "Pending"
      // even though Withdrawal History correctly showed "Paid").
      batch.update(linkedTxnSnap.docs.first.reference, {
        'status': _mapToTransactionStatus(newStatus).name,
        'withdrawalId': withdrawalId,
      });
    } else {
      debugPrint(
          '⚠️ No matching transaction found to sync status for withdrawal $withdrawalId');
    }

    final walletRef = _wallets.doc(artistId);
    if (newStatus == WithdrawalStatus.paid) {
      batch.update(walletRef, {
        'pendingWithdrawal': FieldValue.increment(-amount),
        'updatedAt': now,
      });
    } else if (newStatus == WithdrawalStatus.rejected) {
      batch.update(walletRef, {
        'availableBalance': FieldValue.increment(amount),
        'pendingWithdrawal': FieldValue.increment(-amount),
        'updatedAt': now,
      });

      final txRef = _txns(artistId).doc();
      batch.set(txRef, {
        'artistId': artistId,
        'orderId': null,
        'withdrawalId': withdrawalId,
        'type': 'refund',
        'status': 'completed',
        'amount': amount,
        'title': 'Withdrawal Refunded',
        'description': adminNotes ?? 'Request rejected',
        'createdAt': now,
      });
    }

    await batch.commit();

    await syncWalletFromBookings(artistId: artistId);

    if (artistEmail.isNotEmpty) {
      final dateStr = _dateStr(DateTime.now());
      final shortId = withdrawalId.substring(0, 8).toUpperCase();
      if (newStatus == WithdrawalStatus.paid) {
        WalletBrevoService.sendWithdrawalPaid(
          toEmail: artistEmail,
          riderName: artistName,
          withdrawalId: shortId,
          amount: amount.toStringAsFixed(0),
          paymentMethod: 'Wallet',
          accountNumber: '',
          paidDate: dateStr,
        );
      } else if (newStatus == WithdrawalStatus.rejected) {
        WalletBrevoService.sendWithdrawalRejected(
          toEmail: artistEmail,
          riderName: artistName,
          withdrawalId: shortId,
          amount: amount.toStringAsFixed(0),
          reason: adminNotes ?? 'Request rejected by admin',
          rejectedDate: dateStr,
        );
      }
    }
  }

  /// One-time migration to fix any existing transaction documents whose
  /// `status` field was written directly from a WithdrawalStatus name
  /// (e.g. "paid", "rejected") before the mapping fix above existed.
  /// Run this once (e.g. from an admin debug button) to backfill old data.
  Future<int> migrateOldWithdrawalTransactionStatuses() async {
    int fixedCount = 0;
    try {
      final allWithdrawals = await _withdrawals.get();
      debugPrint(
          '🔧 Migration: scanning ${allWithdrawals.docs.length} withdrawal requests...');

      for (final wDoc in allWithdrawals.docs) {
        final data = wDoc.data() as Map<String, dynamic>;
        final artistId = data['artistId'] as String?;
        final statusStr = data['status'] as String?;
        final amount = ((data['amount'] ?? 0) as num).toDouble();
        final withdrawalId = wDoc.id;

        if (artistId == null || artistId.isEmpty || statusStr == null) {
          continue;
        }

        final withdrawalStatus = WithdrawalStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => WithdrawalStatus.pending,
        );
        // ✅ FIX: use the mapped TransactionStatus name, not the raw
        // WithdrawalStatus name, when backfilling old linked transactions.
        final correctTxnStatus =
            _mapToTransactionStatus(withdrawalStatus).name;

        final linkedSnap = await _txns(artistId)
            .where('withdrawalId', isEqualTo: withdrawalId)
            .limit(1)
            .get();

        if (linkedSnap.docs.isNotEmpty) {
          final txnData =
              linkedSnap.docs.first.data() as Map<String, dynamic>;
          if (txnData['status'] != correctTxnStatus) {
            await linkedSnap.docs.first.reference
                .update({'status': correctTxnStatus});
            fixedCount++;
            debugPrint(
                '✅ Fixed (linked): $withdrawalId → $correctTxnStatus');
          }
          continue;
        }

        final candidatesSnap = await _txns(artistId)
            .where('type', isEqualTo: 'withdrawal')
            .where('amount', isEqualTo: amount)
            .get();

        for (final txnDoc in candidatesSnap.docs) {
          final txnData = txnDoc.data() as Map<String, dynamic>;
          if (txnData.containsKey('withdrawalId') &&
              txnData['withdrawalId'] != null) {
            continue;
          }
          await txnDoc.reference.update({
            'withdrawalId': withdrawalId,
            'status': correctTxnStatus,
          });
          fixedCount++;
          debugPrint(
              '✅ Fixed (fallback-linked): $withdrawalId → $correctTxnStatus');
          break;
        }
      }

      debugPrint('🎉 Migration complete. Fixed $fixedCount record(s).');
    } catch (e) {
      debugPrint('❌ Migration error: $e');
    }
    return fixedCount;
  }
}