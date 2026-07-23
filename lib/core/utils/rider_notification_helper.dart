import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/services/rider_notification_service.dart';

/// Convenience wrappers for creating typed rider notifications.
///
/// Each method maps a domain event to a [RiderNotificationService.createNotification]
/// call with a pre-defined title, body, and data payload.
class RiderNotificationHelper {
  RiderNotificationHelper._();

  static final _service = RiderNotificationService.instance;

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  static Future<void> notifyOrderAssigned({
    required String riderId,
    required String bookingId,
    required String customerName,
    required String pickupAddress,
    required String deliveryAddress,
    required double estimatedDistance,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '📦 New Delivery Order',
        body: 'Order from $customerName is ready to pick up',
        type: NotificationType.order,
        data: {
          'bookingId': bookingId,
          'customerName': customerName,
          'pickupAddress': pickupAddress,
          'deliveryAddress': deliveryAddress,
          'estimatedDistance': estimatedDistance,
          'action': 'view_order',
        },
      );

  static Future<void> notifyOrderAccepted({
    required String riderId,
    required String bookingId,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '✅ Order Accepted',
        body: 'You accepted the delivery order',
        type: NotificationType.order,
        data: {'bookingId': bookingId, 'action': 'track_order'},
      );

  static Future<void> notifyPickupStarted({
    required String riderId,
    required String bookingId,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '🏪 Pickup Started',
        body: 'You started pickup from studio',
        type: NotificationType.order,
        data: {'bookingId': bookingId, 'action': 'track_order'},
      );

  static Future<void> notifyPickedUp({
    required String riderId,
    required String bookingId,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '📦 Order Picked Up',
        body: 'Order picked up. Head to the delivery location',
        type: NotificationType.order,
        data: {'bookingId': bookingId, 'action': 'track_order'},
      );

  static Future<void> notifyDeliveryStarted({
    required String riderId,
    required String bookingId,
    required String customerName,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '🛵 On the Way',
        body: 'Heading to $customerName\'s location',
        type: NotificationType.order,
        data: {'bookingId': bookingId, 'action': 'track_order'},
      );

  static Future<void> notifyDelivered({
    required String riderId,
    required String bookingId,
    required double earnings,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '🎉 Order Delivered!',
        body: 'Delivered successfully! Earned Rs. ${earnings.toInt()}',
        type: NotificationType.order,
        data: {
          'bookingId': bookingId,
          'earnings': earnings,
          'action': 'view_earnings',
        },
      );

  static Future<void> notifyOrderCancelled({
    required String riderId,
    required String bookingId,
    required String reason,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '❌ Order Cancelled',
        body: reason,
        type: NotificationType.order,
        data: {'bookingId': bookingId, 'reason': reason},
      );

  // ---------------------------------------------------------------------------
  // Wallet
  // ---------------------------------------------------------------------------

  static Future<void> notifyEarningsAdded({
    required String riderId,
    required double amount,
    required String orderId,
    required double newBalance,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '💰 Earnings Added',
        body: 'Rs. ${amount.toInt()} added to your wallet',
        type: NotificationType.wallet,
        data: {
          'orderId': orderId,
          'amount': amount,
          'newBalance': newBalance,
          'action': 'view_wallet',
        },
      );

  static Future<void> notifyLowBalance({
    required String riderId,
    required double currentBalance,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '⚠️ Low Wallet Balance',
        body:
            'Your balance is Rs. ${currentBalance.toInt()}. Submit a withdrawal to keep your funds safe',
        type: NotificationType.wallet,
        data: {'currentBalance': currentBalance, 'action': 'view_wallet'},
      );

  // ---------------------------------------------------------------------------
  // Withdrawals
  // ---------------------------------------------------------------------------

  static Future<void> notifyWithdrawalSubmitted({
    required String riderId,
    required String withdrawalId,
    required double amount,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '📬 Withdrawal Submitted',
        body: 'Rs. $amount withdrawal submitted. We\'ll process within 1–2 days',
        type: NotificationType.withdrawal,
        data: {
          'withdrawalId': withdrawalId,
          'amount': amount,
          'action': 'view_withdrawal',
        },
      );

  static Future<void> notifyWithdrawalApproved({
    required String riderId,
    required String withdrawalId,
    required double amount,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '✅ Withdrawal Approved',
        body: 'Your withdrawal of Rs. $amount has been approved',
        type: NotificationType.withdrawal,
        data: {
          'withdrawalId': withdrawalId,
          'amount': amount,
          'status': 'approved',
          'action': 'view_withdrawal',
        },
      );

  static Future<void> notifyWithdrawalPaid({
    required String riderId,
    required String withdrawalId,
    required double amount,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '💳 Withdrawal Paid',
        body: 'Rs. $amount transferred to your account',
        type: NotificationType.withdrawal,
        data: {
          'withdrawalId': withdrawalId,
          'amount': amount,
          'status': 'paid',
          'action': 'view_withdrawal',
        },
      );

  static Future<void> notifyWithdrawalRejected({
    required String riderId,
    required String withdrawalId,
    required double amount,
    required String reason,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '❌ Withdrawal Rejected',
        body: 'Withdrawal rejected. Amount refunded to your wallet',
        type: NotificationType.withdrawal,
        data: {
          'withdrawalId': withdrawalId,
          'amount': amount,
          'reason': reason,
          'status': 'rejected',
          'action': 'view_withdrawal',
        },
      );

  // ---------------------------------------------------------------------------
  // Account
  // ---------------------------------------------------------------------------

  static Future<void> notifyRiderApproved({
    required String riderId,
    required String riderName,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '🎉 Account Approved!',
        body: 'Congratulations $riderName! Your account is approved. Start delivering now!',
        type: NotificationType.account,
        data: {'status': 'approved', 'action': 'start_delivering'},
      );

  static Future<void> notifyRiderSuspended({
    required String riderId,
    required String reason,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '⚠️ Account Suspended',
        body: 'Your account has been suspended. Contact support for details',
        type: NotificationType.account,
        data: {'reason': reason, 'status': 'suspended', 'action': 'contact_support'},
      );

  static Future<void> notifyRiderReactivated({required String riderId}) =>
      _service.createNotification(
        userId: riderId,
        title: '✅ Account Reactivated',
        body: 'Your account is active again. Start accepting orders!',
        type: NotificationType.account,
        data: {'status': 'active', 'action': 'start_delivering'},
      );

  // ---------------------------------------------------------------------------
  // System
  // ---------------------------------------------------------------------------

  static Future<void> notifyMaintenance({
    required String riderId,
    required String message,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '🔧 Maintenance Notice',
        body: message,
        type: NotificationType.system,
        data: {'type': 'maintenance'},
      );

  static Future<void> notifyNewAppVersion({
    required String riderId,
    required String version,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: '📱 New Version Available',
        body: 'Update to version $version for new features and fixes',
        type: NotificationType.system,
        data: {'version': version, 'action': 'update_app'},
      );

  // ---------------------------------------------------------------------------
  // Promotions
  // ---------------------------------------------------------------------------

  static Future<void> notifyPromotion({
    required String riderId,
    required String title,
    required String body,
    required String promoCode,
  }) =>
      _service.createNotification(
        userId: riderId,
        title: title,
        body: body,
        type: NotificationType.promotion,
        data: {'promoCode': promoCode, 'action': 'view_promo'},
      );
}