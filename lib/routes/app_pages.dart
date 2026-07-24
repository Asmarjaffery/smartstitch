import 'package:get/get.dart';
import 'package:smartstitch/admin/admin_bindings.dart';
import 'package:smartstitch/admin/admin_main_screen.dart';
import 'package:smartstitch/admin/review/admin_review_screen.dart';
import 'package:smartstitch/admin/refunds/refund_requests_screen.dart';
import 'package:smartstitch/artist/artist_bindings.dart';
import 'package:smartstitch/artist/artist_main_screen.dart';
import 'package:smartstitch/artist/design/design_screen.dart';
import 'package:smartstitch/artist/portfolio/artist_portfolio_screen.dart';
import 'package:smartstitch/artist/portfolio/portfolio_details_screen.dart';
import 'package:smartstitch/auth/forget_password.dart';
import 'package:smartstitch/auth/post_login_welcome_screen.dart';
import 'package:smartstitch/core/widgets/portfolio_binding.dart';
import 'package:smartstitch/riders/notification/notification_center_controller.dart';
import 'package:smartstitch/riders/notification/notification_center_screen.dart';
import 'package:smartstitch/riders/profile/rider_profile_screen.dart';
import 'package:smartstitch/riders/rider_bindings.dart';
import 'package:smartstitch/riders/rider_main_screen.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/auth/login.dart';
import 'package:smartstitch/auth/signup_screen.dart';
import 'package:smartstitch/screens/splash_screen.dart';
import 'package:smartstitch/services/performance_screen.dart';
import 'package:smartstitch/user/artist/artist_detail_screen.dart';
import 'package:smartstitch/user/artist/artist_screen.dart';
import 'package:smartstitch/user/booking/booking_address_measurement_screen.dart';
import 'package:smartstitch/user/booking/booking_screen.dart';
import 'package:smartstitch/user/booking/booking_confirm_screen.dart'
    as confirm_screen;
import 'package:smartstitch/user/chat/chat_list_screen.dart';
import 'package:smartstitch/user/chat/chat_room_screen.dart';
import 'package:smartstitch/user/complaint/complaint_detail_screen.dart';
import 'package:smartstitch/user/complaint/complaint_screen.dart';
import 'package:smartstitch/user/complaint/create_complaint_screen.dart';
import 'package:smartstitch/user/design/design_screen.dart';
import 'package:smartstitch/user/measurement/measurement_screen.dart';
import 'package:smartstitch/user/measurement/ai_scanner_screen.dart';
import 'package:smartstitch/user/measurement/ai_result_screen.dart';
import 'package:smartstitch/user/notification/notifications_screen.dart';
import 'package:smartstitch/user/order/order_detail_screen.dart';
import 'package:smartstitch/user/order/orders_screen.dart';
import 'package:smartstitch/user/profile/profile_screen.dart';
import 'package:smartstitch/user/review/my_reviews_screen.dart';
import 'package:smartstitch/user/review/review_screen.dart';
import 'package:smartstitch/user/user_bindings.dart';
import 'package:smartstitch/user/user_main_screen.dart';
import 'package:smartstitch/user/wishlist/wishlist_screen.dart';
import 'package:smartstitch/ai/screens/ai_chat_screen.dart';
import 'package:smartstitch/ai/screens/ai_conversations_screen.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> routes = [
    // ─── Auth ───────────────────────────────────────────────
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const SignupScreen()),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.postLoginWelcome,
      page: () => const PostLoginWelcomeScreen(),
    ),
    // ─── User ───────────────────────────────────────────────
    GetPage(
      name: AppRoutes.customerHome,
      page: () => const UserMainScreen(),
      binding: UserBindings(),
    ),
    GetPage(
      name: AppRoutes.artistDetail,
      page: () => const ArtistDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.artistList,
      page: () => const ExploreScreen(),
    ),
    GetPage(
      name: AppRoutes.chatList,
      page: () => const ChatListScreen(),
    ),
    GetPage(
      name: AppRoutes.chatRoom,
      page: () => ChatRoomScreen(
        otherUserId: Get.arguments?['otherUserId'] ?? '',
        roomName: Get.arguments?['roomName'] ?? 'Chat',
      ),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: UserBindings(),
    ),
    GetPage(
      name: AppRoutes.bookingCreate,
      page: () => const BookingScreen(),
    ),
    GetPage(
      name: AppRoutes.bookingConfirm,
      page: () => const confirm_screen.BookingConfirmScreen(),
    ),
    GetPage(
      name: AppRoutes.bookingAddressMeasurement,
      page: () => const BookingAddressMeasurementScreen(),
    ),
    GetPage(
      name: AppRoutes.customerOrders,
      page: () => OrdersScreen(),
    ),
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.measurementScreen,
      page: () => const MeasurementScreen(),
    ),
    GetPage(
      name: AppRoutes.aiScanner,
      page: () => const AiScannerScreen(),
    ),
    GetPage(
      name: AppRoutes.aiMeasurementResult,
      page: () => const AiResultScreen(),
    ),
    GetPage(
      name: AppRoutes.wishlist,
      page: () => const WishlistScreen(),
    ),
    // ─── AI Assistant ────────────────────────────────────────
    GetPage(name: AppRoutes.aiChat, page: () => const AiChatScreen()),
    GetPage(
      name: AppRoutes.aiConversations,
      page: () => const AiConversationsScreen(),
    ),
    GetPage(
      name: AppRoutes.customerProfile,
      page: () => const ProfileScreen(),
    ),
    // ─── Complaint ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.complaintsCenter,
      page: () => const ComplaintCenterScreen(),
    ),
    GetPage(
      name: AppRoutes.createComplaint,
      page: () => const CreateComplaintScreen(),
    ),
    GetPage(
      name: AppRoutes.complaintDetail,
      page: () {
        final args = Get.arguments ?? {};
        return ComplaintDetailScreen(complaint: args['complaint']);
      },
    ),
    GetPage(
      name: AppRoutes.reviewCreate,
      page: () => const WriteReviewScreen(),
    ),
    GetPage(
      name: AppRoutes.myReviews,
      page: () => const MyReviewsScreen(),
    ),
    GetPage(
  name: AppRoutes.designExplore,
  page: () => const DesignExploreScreen(),
),
    // ─── Rider ──────────────────────────────────────────────
    GetPage(
      name: AppRoutes.riderDashboard,
      page: () => const RiderMainScreen(),
      binding: RiderBinding(),
    ),
    GetPage(
      name: AppRoutes.riderProfile,
      page: () => const RiderProfileScreen(),
      binding: RiderBinding(),
    ),
    GetPage(
      name: '/notifications',
      page: () => const NotificationCenterScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationCenterController());
      }),
    ),
    // ─── Admin ──────────────────────────────────────────────
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminMainScreen(),
      binding: AdminBindings(),
    ),
    GetPage(
      name: AppRoutes.adminReviews,
      page: () => const AdminReviewScreen(),
    ),
    GetPage(
      name: AppRoutes.performanceScreen,
      page: () => const PerformanceScreen(),
    ),
    GetPage(
      name: AppRoutes.adminRefunds,
      page: () => const RefundRequestsScreen(),
    ),
    // ─── Artist ─────────────────────────────────────────────
    GetPage(
      name: AppRoutes.artistDashboard,
      page: () => const ArtistMainScreen(),
      binding: ArtistBindings(),
    ),
    GetPage(
      name: AppRoutes.artistServiceCreate,
      page: () => const CreateServiceScreen(),
    ),
    GetPage(
  name: AppRoutes.artistPortfolio,

  page: () =>
      const ArtistPortfolioScreen(),

  binding: PortfolioBinding(),
),


GetPage(
  name: AppRoutes.portfolioDetails,

  page: () =>
      const PortfolioDetailsScreen(),

  binding: PortfolioBinding(),
),
  ];
}
