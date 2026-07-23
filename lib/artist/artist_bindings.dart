import 'package:get/get.dart';
import 'package:smartstitch/artist/dashboard/dashboard_controller.dart';
import 'package:smartstitch/artist/earning/earnings_controller.dart';
import 'package:smartstitch/artist/notification/notification_controller.dart';
import 'package:smartstitch/artist/design/design_controller.dart';
import 'package:smartstitch/artist/portfolio/artist_portfolio_controller.dart';
import 'package:smartstitch/artist/profile/profile_controller.dart';
import 'package:smartstitch/artist/wallet/artist_wallet_controller.dart';

class ArtistBindings extends Bindings {
  @override
  void dependencies() {

    Get.lazyPut<ArtistDashboardController>(
      () => ArtistDashboardController(),
      fenix: true,
    );

    Get.lazyPut<ArtistProfileController>(
      () => ArtistProfileController(),
      fenix: true,
    );

    Get.lazyPut<ServiceController>(
      () => ServiceController(),
      fenix: true,
    );

    Get.lazyPut<NotificationController>(
      () => NotificationController(),
      fenix: true,
    );

    Get.lazyPut<EarningsController>(
      () => EarningsController(),
      fenix: true,
    );

    Get.lazyPut<ArtistWalletController>(
      () => ArtistWalletController(),
      fenix: true,
    );

    Get.lazyPut<ArtistPortfolioController>(
      () => ArtistPortfolioController(),
      fenix: true,
    );
  }
}