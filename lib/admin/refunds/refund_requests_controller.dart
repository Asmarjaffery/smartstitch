import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/models/refund_model.dart' hide RefundStatus;
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/services/notification_service.dart';
import 'package:smartstitch/services/refund_service.dart';

class RefundRequestsController extends GetxController {
  static RefundRequestsController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  final RxList<RefundRequestModel> refundRequests = <RefundRequestModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<String> processingIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToRefundRequests();
  }

  void _listenToRefundRequests() {
    isLoading.value = true;
    _firebaseService.firestore
        .collection('refundRequests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      refundRequests.value = snapshot.docs
          .map((doc) =>
              RefundRequestModel.fromJson({...doc.data(), 'orderId': doc.id}))
          .toList();
      isLoading.value = false;
    }, onError: (_) {
      isLoading.value = false;
      AppHelpers.showError('Failed to load refund requests.');
    });
  }
  Future<void> approveRefund(RefundRequestModel request) async {
    if (processingIds.contains(request.orderId)) return;
    if (request.paymentIntentId.isEmpty) {
      AppHelpers.showError('Missing payment reference for this booking.');
      return;
    }

    try {
      processingIds.add(request.orderId);

      final result = await RefundService.instance.refundPayment(
        paymentIntentId: request.paymentIntentId,
        amount: request.paidAmount > 0 ? request.paidAmount : null,
        refundRequestId: request.orderId,
      );

      if (!result.success) {
        AppHelpers.showError(
          result.message.isNotEmpty
              ? result.message
              : 'Refund failed. Please try again.',
        );
        return;
      }

      final batch = _firebaseService.firestore.batch();

      final refundRef = _firebaseService.firestore
          .collection('refundRequests')
          .doc(request.orderId);
      batch.update(refundRef, {
        'refundStatus': RefundStatus.approved.name,
        'refundedAt': FieldValue.serverTimestamp(),
      });
      final bookingsRef = _firebaseService.firestore
          .collection('bookings')
          .doc(request.orderId);
      final ordersRef =
          _firebaseService.firestore.collection('orders').doc(request.orderId);
      final ordersSnap = await ordersRef.get();
      final targetRef = ordersSnap.exists ? ordersRef : bookingsRef;

     batch.update(targetRef, {
  'paymentStatus': PaymentStatus.refunded.name,
  'refundStatus': RefundStatus.approved.name,
  'refundId': result.refundId,
  'refundAmount': result.stripeStatus,
  'refundedAt': FieldValue.serverTimestamp(),
});

      await batch.commit();

      try {
        await NotificationService.instance.sendNotification(
          recipientId: request.customerId,
          recipientRole: UserRole.customer,
          type: NotificationType.orderUpdate,
          title: 'Refund Approved',
          body:
              'Your refund for order #${_shortId(request.orderId)} has been processed.',
          data: {'orderId': request.orderId},
        );
      } catch (_) {}

      AppHelpers.showSuccess('Refund approved and processed.');
    } catch (e) {
      AppHelpers.showError('Failed to approve refund. Please try again.');
    } finally {
      processingIds.remove(request.orderId);
    }
  }
  Future<void> rejectRefund(
    RefundRequestModel request, {
    required String rejectionReason,
  }) async {
    if (processingIds.contains(request.orderId)) return;
    if (rejectionReason.trim().isEmpty) {
      AppHelpers.showError('Please provide a reason for rejection.');
      return;
    }

    try {
      processingIds.add(request.orderId);

      final batch = _firebaseService.firestore.batch();

      final refundRef = _firebaseService.firestore
          .collection('refundRequests')
          .doc(request.orderId);
      batch.update(refundRef, {
        'refundStatus': RefundStatus.rejected.name,
        'rejectionReason': rejectionReason.trim(),
      });

      final bookingsRef = _firebaseService.firestore
          .collection('bookings')
          .doc(request.orderId);
      final ordersRef =
          _firebaseService.firestore.collection('orders').doc(request.orderId);
      final ordersSnap = await ordersRef.get();
      final targetRef = ordersSnap.exists ? ordersRef : bookingsRef;

      batch.update(targetRef, {
        'refundStatus': RefundStatus.rejected.name,
        'rejectionReason': rejectionReason.trim(),
      });

      await batch.commit();

      try {
        await NotificationService.instance.sendNotification(
          recipientId: request.customerId,
          recipientRole: UserRole.customer,
          type: NotificationType.orderUpdate,
          title: 'Refund Request Rejected',
          body: rejectionReason.trim(),
          data: {'orderId': request.orderId},
        );
      } catch (_) {}

      AppHelpers.showSuccess('Refund request rejected.');
    } catch (e) {
      AppHelpers.showError('Failed to reject refund. Please try again.');
    } finally {
      processingIds.remove(request.orderId);
    }
  }

  String _shortId(String id) =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}
