import 'package:get/get.dart';
import 'package:smartstitch/riders/dashboard/rider_controller.dart';
import 'package:smartstitch/riders/notification/notification_center_controller.dart';
import 'package:smartstitch/riders/order/rider_order_controller.dart';
import 'package:smartstitch/riders/profile/profile_rider_controller.dart';
import 'package:smartstitch/riders/wallet/wallet_controller.dart';
import 'package:smartstitch/riders/review/rider_review_controller.dart';

class RiderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RiderController>(() => RiderController());
    Get.lazyPut<RiderOrderController>(() => RiderOrderController());
    Get.lazyPut<RiderProfileController>(() => RiderProfileController());
    Get.lazyPut<WalletController>(() => WalletController());
    Get.lazyPut<NotificationCenterController>(
      () => NotificationCenterController(),
    );
    Get.lazyPut<RiderReviewController>(() => RiderReviewController());
  }
}