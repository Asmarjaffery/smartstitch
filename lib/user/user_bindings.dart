import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:smartstitch/user/booking/booking_controller.dart'; 
import 'package:smartstitch/user/complaint/complaint_controller.dart';
import 'package:smartstitch/user/notification/notification_user_controller.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/artist/artist_detail_screen.dart';
import 'package:smartstitch/user/artist/artist_screen.dart';
import 'package:smartstitch/user/booking/booking_confirm_screen.dart';
import 'package:smartstitch/user/booking/booking_screen.dart';
import 'package:smartstitch/user/chat/chat_list_screen.dart';
import 'package:smartstitch/user/home/customer_home.dart';
import 'package:smartstitch/user/measurement/measurement_screen.dart';
import 'package:smartstitch/user/notification/notifications_screen.dart';
import 'package:smartstitch/user/order/order_detail_screen.dart';
import 'package:smartstitch/user/order/orders_screen.dart';
import 'package:smartstitch/user/profile/profile_screen.dart';
import 'package:smartstitch/user/review/review_controller.dart';
import 'package:smartstitch/user/user_main_screen.dart';
import 'package:smartstitch/user/wishlist/wishlist_controller.dart';
import 'package:smartstitch/user/wishlist/wishlist_screen.dart';

class UserBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerHomeScreen>(() => const CustomerHomeScreen(), fenix: true);
    Get.lazyPut<ProfileScreen>(() => const ProfileScreen(), fenix: true);
    Get.lazyPut<OrdersScreen>(() => const OrdersScreen(), fenix: true);
    Get.lazyPut<OrderDetailScreen>(() => const OrderDetailScreen(), fenix: true);
    Get.lazyPut<BookingScreen>(() => const BookingScreen(), fenix: true);
    Get.lazyPut<BookingController>(() => BookingController(), fenix: true); // ✅ ADD THIS
    Get.lazyPut<BookingConfirmScreen>(() => const BookingConfirmScreen(),
        fenix: true);
    Get.lazyPut<NotificationsScreen>(() => const NotificationsScreen(), fenix: true);
    Get.lazyPut<MeasurementScreen>(() => const MeasurementScreen(), fenix: true);
    Get.lazyPut<ExploreScreen>(() => const ExploreScreen(), fenix: true);
    Get.lazyPut<ArtistDetailScreen>(() => const ArtistDetailScreen(), fenix: true);
    Get.lazyPut<ChatListScreen>(() => const ChatListScreen(), fenix: true);
    Get.lazyPut<WishlistController>(() => WishlistController(), fenix: true);
    Get.lazyPut(() => NotificationUserController(), fenix: true);
    Get.lazyPut(() => ComplaintController());
    Get.lazyPut<ReviewController>(() => ReviewController(), fenix: true); 
  }
}