import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/models/delivery_exception_model.dart';
import 'package:smartstitch/models/enums.dart';

/// Customer-side counterpart to CompensationController — reads the
/// same 'delivery_exceptions' collection the rider writes to, and handles
/// reschedule / outstanding-charge payment actions.
///
/// Kept separate from the rider controller (different lifecycle: this one
/// is scoped to "whatever order the customer is currently viewing").
class CustomerCompensationController extends GetxController {
  static CustomerCompensationController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final Rx<DeliveryExceptionModel?> exception = Rx(null);
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;

  /// Loads the most recent delivery-exception report for an order.
  /// Call this from the customer's Order Detail screen once you see
  /// order.status flip to a "delivery failed" state (or booking doc's
  /// `lastDeliveryExceptionId`, written by the rider's submitReport()).
  Future<void> loadForOrder(String orderId) async {
    try {
      isLoading.value = true;
      final snap = await _db
          .collection('delivery_exceptions')
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      exception.value = snap.docs.isEmpty
          ? null
          : DeliveryExceptionModel.fromJson(snap.docs.first.data());
    } catch (e) {
      debugPrint('loadForOrder error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// "Pay Now" on the Reschedule Delivery screen. Doesn't process the actual
  /// payment (hook up your existing JazzCash/EasyPaisa/Stripe flow here) —
  /// just persists the reschedule + new fee once payment succeeds.
  Future<bool> confirmReschedule({
    required String orderId,
    required double newDeliveryFee,
    required String paymentMethod,
  }) async {
    final current = exception.value;
    if (current == null) return false;
    try {
      isProcessingPayment.value = true;

      await _db.collection('delivery_exceptions').doc(current.id).update({
        'rescheduledDeliveryFee': newDeliveryFee,
        'status': DeliveryExceptionStatus.underReview.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _db.collection('bookings').doc(orderId).update({
        'status': 'riderAssigned', // back into the delivery queue
        'deliveryFee': newDeliveryFee,
        'paymentMethod': paymentMethod,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      exception.value = current.copyWith(
        rescheduledDeliveryFee: newDeliveryFee,
        status: DeliveryExceptionStatus.underReview,
      );
      return true;
    } catch (e) {
      debugPrint('confirmReschedule error: $e');
      Get.snackbar('Error', 'Could not confirm reschedule. Please try again.',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return false;
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// "Pay & Continue" on the Outstanding Charge (COD) screen.
  Future<bool> payOutstandingCharge({
    required String orderId,
    required String paymentMethod,
  }) async {
    final current = exception.value;
    if (current == null) return false;
    try {
      isProcessingPayment.value = true;

      await _db.collection('delivery_exceptions').doc(current.id).update({
        'outstandingChargeAction': OutstandingChargeAction.paid.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      exception.value = current.copyWith(
        outstandingChargeAction: OutstandingChargeAction.paid,
      );
      return true;
    } catch (e) {
      debugPrint('payOutstandingCharge error: $e');
      Get.snackbar('Error', 'Payment failed. Please try again.',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return false;
    } finally {
      isProcessingPayment.value = false;
    }
  }
}