import 'package:get/get.dart';
import 'package:smartstitch/admin/order/admin_order_controller.dart';
import 'package:smartstitch/admin/analytics/analytics_controller.dart';
import 'dashboard/admin_dashboard_controller.dart';
import 'users/admin_user_controller.dart';
import 'users/admin_artist_controller.dart';
import 'users/admin_rider_controller.dart';
import 'services/admin_service_controller.dart';
import 'payment/admin_payment_controller.dart';
import 'complaint/admin_complaint_controller.dart';
import 'notification/admin_notification_controller.dart';

class AdminBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardController>(() => AdminDashboardController(),
        fenix: true);

    Get.lazyPut<AdminUserController>(() => AdminUserController(), fenix: true);

    Get.lazyPut<AdminArtistController>(() => AdminArtistController(),
        fenix: true);

    Get.lazyPut<AdminRiderController>(() => AdminRiderController(),
        fenix: true);

    Get.lazyPut<AdminCategoriesController>(() => AdminCategoriesController(),
        fenix: true);

    Get.lazyPut<AdminServicesController>(() => AdminServicesController(), 
        fenix: true);

    Get.lazyPut<AdminPaymentController>(() => AdminPaymentController(),
        fenix: true);

    Get.lazyPut<AdminComplaintController>(() => AdminComplaintController(),
        fenix: true);

    Get.lazyPut<AdminNotificationController>(
        () => AdminNotificationController(),
        fenix: true);

    Get.lazyPut<AdminOrderController>(() => AdminOrderController(), fenix: true);

    Get.lazyPut<AnalyticsController>(() => AnalyticsController(), fenix: true);
  }
}