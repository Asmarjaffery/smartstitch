import 'dart:ui';

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

// ─── Compensation feature — Rider / Customer / Admin ──────────────────────
// NOTE: adjust these three import blocks if your actual folder names differ
// (assumed symmetric with lib/riders/compensation/, which already exists).
import 'package:smartstitch/riders/compensation/compensation_controller.dart';
import 'package:smartstitch/riders/wallet/rider_wallet_screen.dart';
import 'package:smartstitch/riders/compensation/compensation_history_screen.dart';
import 'package:smartstitch/user/compensation/customer_compensation_controller.dart';
import 'package:smartstitch/user/compensation/delivery_failed_screen.dart';
import 'package:smartstitch/user/compensation/reschedule_delivery_screen.dart';
import 'package:smartstitch/user/compensation/outstanding_charge_screen.dart';
import 'package:smartstitch/admin/compensation/admin_compensation_controller.dart';
import 'package:smartstitch/admin/compensation/failed_deliveries_screen.dart';
import 'package:smartstitch/controllers/auth_controller.dart';

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
      name: AppRoutes.bookingSuccess,
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

    // ─── Customer: Delivery Exceptions ──────────────────────
    GetPage(
      name: AppRoutes.customerDeliveryFailed,
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CustomerCompensationController>()) {
          Get.put(CustomerCompensationController());
        }
      }),
      page: () {
        final args = Get.arguments ?? {};
        return DeliveryFailedScreen(
          orderId: args['orderId'] as String? ?? '',
          previousDeliveryFee:
              (args['previousDeliveryFee'] as num?)?.toDouble() ?? 0,
          onCancelOrder: args['onCancelOrder'] as VoidCallback?,
        );
      },
    ),
    GetPage(
      name: AppRoutes.customerRescheduleDelivery,
      page: () {
        final args = Get.arguments ?? {};
        return RescheduleDeliveryScreen(
          orderId: args['orderId'] as String? ?? '',
          previousDeliveryFee:
              (args['previousDeliveryFee'] as num?)?.toDouble() ?? 0,
          newDeliveryFee: (args['newDeliveryFee'] as num?)?.toDouble(),
        );
      },
    ),
    GetPage(
      name: AppRoutes.customerOutstandingCharge,
      page: () {
        final args = Get.arguments ?? {};
        return OutstandingChargeScreen(
          orderId: args['orderId'] as String? ?? '',
          outstandingAmount:
              (args['outstandingAmount'] as num?)?.toDouble() ?? 0,
        );
      },
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

    // ─── Rider: Compensation & Delivery Exceptions ──────────
    GetPage(
      name: AppRoutes.riderWallet,
      // RiderWalletScreen takes no params — it reads everything from
      // WalletController via Get.find() internally, including a
      // TransactionType.compensation case already wired into its
      // transaction list. No CompensationController binding needed here.
      page: () => const RiderWalletScreen(),
    ),
    GetPage(
      name: AppRoutes.riderCompensationHistory,
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CompensationController>()) {
          Get.put(CompensationController());
        }
      }),
      page: () {
        final riderId = (Get.arguments?['riderId'] as String?) ??
            AuthController.to.currentUserId ??
            '';
        return CompensationHistoryScreen(riderId: riderId);
      },
    ),
    // NOTE: riderReportDeliveryIssue / riderDeliveryAttemptSummary /
    // riderIssueSubmitted are NOT registered here on purpose — they're
    // pushed directly (ReportDeliveryIssueSheet.show(...) / Get.to(...))
    // from rider_screen.dart with typed constructor params, which is
    // simpler than threading everything through Get.arguments.

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

    // ─── Admin: Failed Deliveries & Compensation ────────────
    GetPage(
      name: AppRoutes.adminFailedDeliveries,
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AdminCompensationController>()) {
          Get.put(AdminCompensationController());
        }
      }),
      page: () => const FailedDeliveriesScreen(),
    ),
    // Same screen/data as adminFailedDeliveries — the Figma spec listed
    // "Rider Compensation" as a separate sidebar item, but it's the same
    // delivery_exceptions list with the same filter tabs, so both routes
    // point here rather than duplicating a whole screen.
    GetPage(
      name: AppRoutes.adminRiderCompensation,
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AdminCompensationController>()) {
          Get.put(AdminCompensationController());
        }
      }),
      page: () => const FailedDeliveriesScreen(),
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