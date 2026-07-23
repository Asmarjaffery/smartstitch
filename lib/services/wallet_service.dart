import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_models.dart';
import '../models/enums.dart' hide PaymentMethod;
import 'package:smartstitch/services/wallet_brevo_service.dart';
import 'package:smartstitch/services/notification_service.dart';

class WalletService {
  static final WalletService instance = WalletService._internal();
  factory WalletService() => instance;
  WalletService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _wallets => _db.collection('rider_wallets');
  CollectionReference get _transactions => _db.collection('wallet_transactions');
  CollectionReference get _withdrawals => _db.collection('withdrawal_requests');

  // ─── Helper ───────────────────────────────────────────────
  String _dateStr(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ─── WALLET ──────────────────────────────────────────────

  Stream<RiderWallet> watchWallet(String riderId) {
    return _wallets.doc(riderId).snapshots().map((snap) {
      if (!snap.exists) return RiderWallet.empty(riderId);
      return RiderWallet.fromJson(
          {'riderId': snap.id, ...snap.data() as Map<String, dynamic>});
    });
  }

  Future<RiderWallet> getWallet(String riderId) async {
    final snap = await _wallets.doc(riderId).get();
    if (!snap.exists) return RiderWallet.empty(riderId);
    return RiderWallet.fromJson(
        {'riderId': snap.id, ...snap.data() as Map<String, dynamic>});
  }

  Future<void> initWallet(String riderId) async {
    final doc = _wallets.doc(riderId);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set(RiderWallet.empty(riderId).toJson());
    }
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────

  Stream<List<WalletTransaction>> watchTransactions(String riderId,
      {int limit = 20}) {
    return _transactions
        .where('riderId', isEqualTo: riderId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WalletTransaction.fromJson(
                {'id': d.id, ...d.data() as Map<String, dynamic>}))
            .toList());
  }

  Future<void> addTransaction(WalletTransaction tx) async {
    final docRef = _transactions.doc();
    final withId = WalletTransaction(
      id: docRef.id,
      riderId: tx.riderId,
      orderId: tx.orderId,
      type: tx.type,
      status: tx.status,
      amount: tx.amount,
      title: tx.title,
      description: tx.description,
      createdAt: tx.createdAt,
    );
    await docRef.set(withId.toJson());

    // ─── In-app notification: rider earned/received a wallet transaction ──
    NotificationService.instance.sendNotification(
      recipientId: tx.riderId,
      recipientRole: UserRole.rider,
      type: NotificationType.paymentReceived,
      title: tx.title,
      body: tx.description ?? '',
      data: {'transactionId': docRef.id},
    );
  }

  // ─── WITHDRAWAL REQUESTS ──────────────────────────────────

  Future<WithdrawalRequest> createWithdrawalRequest({
    required String riderId,
    required String riderName,
    required String riderEmail,
    required double amount,
    required PaymentMethod paymentMethod,
    required String accountTitle,
    required String accountNumber,
    String? notes,
  }) async {
    final wallet = await getWallet(riderId);

    if (amount > wallet.availableBalance) {
      throw Exception('Insufficient balance');
    }
    if (amount < 500) {
      throw Exception('Minimum withdrawal amount is Rs. 500');
    }

    final docRef = _withdrawals.doc();
    final request = WithdrawalRequest(
      id: docRef.id,
      riderId: riderId,
      riderName: riderName,
      riderEmail: riderEmail,
      amount: amount,
      paymentMethod: paymentMethod,
      accountTitle: accountTitle,
      accountNumber: accountNumber,
      notes: notes,
      status: WithdrawalStatus.pending,
      requestedAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(docRef, request.toJson());
    batch.update(_wallets.doc(riderId), {
      'availableBalance': FieldValue.increment(-amount),
      'pendingWithdrawal': FieldValue.increment(amount),
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();

    // ─── Email: Request Received ──────────────────────────
    WalletBrevoService.sendWithdrawalRequested(
      toEmail: riderEmail,
      riderName: riderName,
      withdrawalId: docRef.id.substring(0, 8).toUpperCase(),
      amount: amount.toStringAsFixed(0),
      paymentMethod: paymentMethod.label,
      accountTitle: accountTitle,
      accountNumber: accountNumber,
      requestedDate: _dateStr(DateTime.now()),
    );

    // ─── In-app notification: withdrawal request submitted ────────────
    NotificationService.instance.sendNotification(
      recipientId: riderId,
      recipientRole: UserRole.rider,
      type: NotificationType.withdrawUpdate,
      title: 'Withdrawal Requested',
      body:
          'Your withdrawal request of Rs. ${amount.toStringAsFixed(0)} has been submitted.',
      data: {'withdrawalId': docRef.id},
    );

    return request;
  }

  Stream<List<WithdrawalRequest>> watchWithdrawalHistory(String riderId) {
    return _withdrawals
        .where('riderId', isEqualTo: riderId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequest.fromJson(
                {'id': d.id, ...d.data() as Map<String, dynamic>}))
            .toList());
  }

  // ─── ADMIN: UPDATE WITHDRAWAL STATUS ─────────────────────

  Future<void> updateWithdrawalStatus({
    required String withdrawalId,
    required String riderId,
    required double amount,
    required WithdrawalStatus newStatus,
    String? adminNotes,
    String riderEmail = '',
    String riderName = '',
  }) async {
    final batch = _db.batch();

    batch.update(_withdrawals.doc(withdrawalId), {
      'status': newStatus.name,
      'adminNotes': adminNotes,
      'processedAt': Timestamp.now(),
    });

    if (newStatus == WithdrawalStatus.paid) {
      batch.update(_wallets.doc(riderId), {
        'pendingWithdrawal': FieldValue.increment(-amount),
        'updatedAt': Timestamp.now(),
      });
    } else if (newStatus == WithdrawalStatus.rejected) {
      batch.update(_wallets.doc(riderId), {
        'availableBalance': FieldValue.increment(amount),
        'pendingWithdrawal': FieldValue.increment(-amount),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();

    // ─── Email + In-app notification: Status Update ───────────────────
    final dateStr = _dateStr(DateTime.now());
    final shortId = withdrawalId.substring(0, 8).toUpperCase();

    if (newStatus == WithdrawalStatus.paid) {
      if (riderEmail.isNotEmpty) {
        WalletBrevoService.sendWithdrawalPaid(
          toEmail: riderEmail,
          riderName: riderName,
          withdrawalId: shortId,
          amount: amount.toStringAsFixed(0),
          paymentMethod: 'Wallet',
          accountNumber: '',
          paidDate: dateStr,
        );
      }

      NotificationService.instance.sendNotification(
        recipientId: riderId,
        recipientRole: UserRole.rider,
        type: NotificationType.withdrawUpdate,
        title: 'Withdrawal Paid',
        body: 'Rs. ${amount.toStringAsFixed(0)} has been paid to your account.',
        data: {'withdrawalId': withdrawalId},
      );
    } else if (newStatus == WithdrawalStatus.rejected) {
      if (riderEmail.isNotEmpty) {
        WalletBrevoService.sendWithdrawalRejected(
          toEmail: riderEmail,
          riderName: riderName,
          withdrawalId: shortId,
          amount: amount.toStringAsFixed(0),
          reason: adminNotes ?? 'Request rejected by admin',
          rejectedDate: dateStr,
        );
      }

      NotificationService.instance.sendNotification(
        recipientId: riderId,
        recipientRole: UserRole.rider,
        type: NotificationType.withdrawUpdate,
        title: 'Withdrawal Rejected',
        body: adminNotes ?? 'Your withdrawal request was rejected.',
        data: {'withdrawalId': withdrawalId},
      );
    } else if (newStatus == WithdrawalStatus.approved) {
      // No email sent here today (email for "approved" is triggered from
      // WalletController.adminUpdateStatus instead) — but we still want an
      // in-app notification so it shows up under the Withdrawal tab.
      NotificationService.instance.sendNotification(
        recipientId: riderId,
        recipientRole: UserRole.rider,
        type: NotificationType.withdrawUpdate,
        title: 'Withdrawal Approved',
        body:
            'Your withdrawal request of Rs. ${amount.toStringAsFixed(0)} has been approved.',
        data: {'withdrawalId': withdrawalId},
      );
    }
  }

  // ─── ADMIN: WATCH ALL WITHDRAWALS ─────────────────────────

  Stream<List<WithdrawalRequest>> watchAllWithdrawals(
      {WithdrawalStatus? filterStatus}) {
    Query query = _withdrawals.orderBy('requestedAt', descending: true);
    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }
    return query.snapshots().map((snap) => snap.docs
    
        .map((d) => WithdrawalRequest.fromJson(
            {'id': d.id, ...d.data() as Map<String, dynamic>}))
        .toList());
  }
}