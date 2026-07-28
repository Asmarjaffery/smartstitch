import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/order/admin_order_controller.dart' show SimpleUser;
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/delivery_exception_model.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/services/notification_service.dart';

/// Drives the admin "Failed Deliveries" table + review drawer.
/// Reuses SimpleUser from AdminOrderController for name/phone lookups so we
/// don't duplicate that fetch logic.
class AdminCompensationController extends GetxController {
  static AdminCompensationController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final RxList<DeliveryExceptionModel> items = <DeliveryExceptionModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<CompensationStatus?> filter = Rx(null); // null == All

  // id → SimpleUser cache, keyed by userId, for the table/drawer.
  final Map<String, SimpleUser> _userCache = {};

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll({CompensationStatus? status}) async {
    try {
      isLoading.value = true;
      filter.value = status;

      Query<Map<String, dynamic>> q = _db
          .collection('delivery_exceptions')
          .orderBy('createdAt', descending: true);

      if (status != null) {
        q = q.where('compensationStatus', isEqualTo: status.name);
      }

      final snap = await q.limit(200).get();
      items.value =
          snap.docs.map((d) => DeliveryExceptionModel.fromJson(d.data())).toList();

      // Warm the name cache for anyone visible in the current page.
      final ids = <String>{
        for (final i in items) ...[i.customerId, i.riderId],
      };
      await Future.wait(ids.map(_ensureUserCached));
    } catch (e) {
      debugPrint('AdminCompensationController.loadAll error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _ensureUserCached(String userId) async {
    if (userId.isEmpty || _userCache.containsKey(userId)) return;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) _userCache[userId] = SimpleUser.fromDoc(doc);
    } catch (e) {
      debugPrint('user cache error for $userId: $e');
    }
  }

  String nameFor(String userId) => _userCache[userId]?.name ?? 'Unknown';
  String phoneFor(String userId) => _userCache[userId]?.phone ?? '';

  // ─── Actions ────────────────────────────────────────────────────────────

  Future<void> approveCompensation(DeliveryExceptionModel item) async {
    await _updateAndNotifyRider(
      item,
      compensationStatus: CompensationStatus.approved,
      status: DeliveryExceptionStatus.resolved,
      title: 'Compensation Approved',
      body: 'Your Rs. ${item.compensationAmount.toStringAsFixed(0)} claim '
          'for order ${item.orderId} was approved.',
    );

    // Move it from pending → available balance on the rider's wallet.
    await _db.collection('rider_wallets').doc(item.riderId).set({
      'pendingCompensation': FieldValue.increment(-item.compensationAmount),
      'availableBalance': FieldValue.increment(item.compensationAmount),
    }, SetOptions(merge: true));

    await _db.collection('wallet_transactions').add({
      'riderId': item.riderId,
      'orderId': item.orderId,
      'type': WalletTransactionType.compensation.name,
      'status': 'paid',
      'amount': item.compensationAmount,
      'title': 'Compensation Approved',
      'description': item.reason.label,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectCompensation(DeliveryExceptionModel item, String reason) async {
    await _updateAndNotifyRider(
      item,
      compensationStatus: CompensationStatus.rejected,
      status: DeliveryExceptionStatus.resolved,
      adminNote: reason,
      title: 'Compensation Rejected',
      body: 'Your claim for order ${item.orderId} was rejected: $reason',
    );

    await _db.collection('rider_wallets').doc(item.riderId).set({
      'pendingCompensation': FieldValue.increment(-item.compensationAmount),
    }, SetOptions(merge: true));
  }

  Future<void> waiveCharges(DeliveryExceptionModel item) async {
    await _db.collection('delivery_exceptions').doc(item.id).update({
      'outstandingChargeAction': OutstandingChargeAction.waived.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _replaceLocal(item.copyWith(
      outstandingChargeAction: OutstandingChargeAction.waived,
    ));

    try {
      await NotificationService.instance.sendNotification(
        recipientId: item.customerId,
        recipientRole: UserRole.customer,
        type: NotificationType.general,
        title: 'Delivery Charge Waived',
        body: 'Your outstanding delivery charge for order ${item.orderId} '
            'has been waived.',
        data: {'orderId': item.orderId},
      );
    } catch (e) {
      debugPrint('waiveCharges notify error: $e');
    }
  }

  Future<void> assignNewRider(DeliveryExceptionModel item, String newRiderId) async {
    await _db.collection('delivery_exceptions').doc(item.id).update({
      'newRiderId': newRiderId,
      'status': DeliveryExceptionStatus.underReview.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _db.collection('bookings').doc(item.orderId).update({
      'riderId': newRiderId,
      'status': 'riderAssigned',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _replaceLocal(item.copyWith(
      newRiderId: newRiderId,
      status: DeliveryExceptionStatus.underReview,
    ));
  }

  Future<void> _updateAndNotifyRider(
    DeliveryExceptionModel item, {
    required CompensationStatus compensationStatus,
    required DeliveryExceptionStatus status,
    String? adminNote,
    required String title,
    required String body,
  }) async {
    try {
      await _db.collection('delivery_exceptions').doc(item.id).update({
        'compensationStatus': compensationStatus.name,
        'status': status.name,
        if (adminNote != null) 'adminNote': adminNote,
        'reviewedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _replaceLocal(item.copyWith(
        compensationStatus: compensationStatus,
        status: status,
        adminNote: adminNote,
        reviewedAt: DateTime.now(),
      ));

      await NotificationService.instance.sendNotification(
        recipientId: item.riderId,
        recipientRole: UserRole.rider,
        type: NotificationType.general,
        title: title,
        body: body,
        data: {'orderId': item.orderId, 'exceptionId': item.id},
      );

      Get.snackbar(title, 'Rider has been notified.',
          backgroundColor: AppColors.success, colorText: Colors.white);
    } catch (e) {
      debugPrint('_updateAndNotifyRider error: $e');
      Get.snackbar('Error', 'Could not complete this action.',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void _replaceLocal(DeliveryExceptionModel updated) {
    final idx = items.indexWhere((e) => e.id == updated.id);
    if (idx != -1) items[idx] = updated;
  }
}