import 'package:get/get.dart';
import 'package:smartstitch/artist/portfolio/artist_portfolio_controller.dart';


class PortfolioBinding extends Bindings {

  @override
  void dependencies() {

    Get.lazyPut<ArtistPortfolioController>(
      () => ArtistPortfolioController(),
      fenix: true,
    );

  }
}