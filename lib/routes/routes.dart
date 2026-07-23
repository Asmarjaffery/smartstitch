class AppRoutes {
  AppRoutes._();

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerify = '/otp-verify';
  static const String postLoginWelcome = '/post-login-welcome';

  // ─── Customer ────────────────────────────────────────────────────────────
  static const String customerHome = '/customer/home';
  static const String customerProfile = '/customer/profile';
  static const String customerOrders = '/customer/orders';
  static const String orderDetail = '/customer/order-detail';
  static const String artistList = '/customer/artists';
  static const String artistDetail = '/customer/artist-detail';
  static const String bookingCreate = '/customer/booking/create';
  static const String bookingConfirm = '/customer/booking/confirm';
  static const String checkout = '/customer/checkout';
  static const String paymentSuccess = '/customer/payment-success';
  static const String reviewCreate = '/customer/review';
  static const String notifications = '/customer/notifications';
  static const String measurementScreen = '/customer/measurements';
  static const String aiScanner = '/customer/ai-scanner';
  static const String aiMeasurementResult = '/customer/ai-measurement-result';
  static const String wishlist = '/customer/wishlist';
  static const String bookingAddressMeasurement = '/booking-address-measurement';
  static const String complaintsCenter = '/customer/complaints';
  static const String createComplaint = '/customer/complaints/create';
  static const String complaintDetail = '/customer/complaints/detail';
  static const String myReviews = '/customer/my-reviews';
  static const String designExplore = '/customer/design-explore';

  // ─── Chat ────────────────────────────────────────────────────────────────
  static const String chatList = '/chat/list';
  static const String chatRoom = '/chat/room';

  // ─── Artist ──────────────────────────────────────────────────────────────
  static const String artistDashboard = '/artist/dashboard';
  static const String artistProfile = '/artist/profile';
  static const String artistOrders = '/artist/orders';
  static const String artistOrderDetail = '/artist/order-detail';
  static const String artistEarnings = '/artist/earnings';
  static const String artistServices = '/artist/services';
  static const String artistServiceCreate = '/artist/my-services';
  static const artistPortfolio ='/artist-portfolio';
  static const portfolioDetails ='/portfolio-details';

  // ─── Rider ───────────────────────────────────────────────────────────────
  static const String riderMain = '/rider/rider_main_screen';
  static const String riderDashboard = '/rider/dashboard';
  static const String riderProfile = '/rider/profile';
  static const String riderDeliveries = '/rider/deliveries';
  static const String riderDeliveryDetail = '/rider/delivery-detail';
  static const String riderEarnings = '/rider/earnings';

  // ─── AI Assistant ────────────────────────────────────────────────────────
  static const String aiChat = '/ai/chat';
  static const String aiConversations = '/ai/conversations';

  // ─── Admin ───────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin-dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/user-detail';
  static const String adminArtists = '/admin/artists';
  static const String adminRiders = '/admin/riders';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/order-detail';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';
  static const String adminReviews = '/admin/reviews';
  static const String performanceScreen = '/admin/performance';
}