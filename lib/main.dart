import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/riders/dashboard/rider_controller.dart';
import 'package:smartstitch/riders/wallet/wallet_controller.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/routes/app_pages.dart';

import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/controllers/chat_controller.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';

import 'package:smartstitch/firebase_options.dart';
import 'package:smartstitch/user/home/home_controller.dart';
import 'package:smartstitch/user/order/order_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ─── Stripe setup ────────────────────────────────────────────
  // flutter_stripe internally checks Platform.isIOS/isAndroid via dart:io,
  // which throws "Unsupported operation: Platform._operatingSystem" on web.
  // So we only initialize native Stripe on mobile/desktop, not on web.
  if (!kIsWeb) {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    await Stripe.instance.applySettings();
  }

  runApp(const SmartStitchApp());
}

class SmartStitchApp extends StatelessWidget {
  const SmartStitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Stitch',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
        Get.put(ChatController(), permanent: true);
        Get.put(OrderController(), permanent: true);
        Get.put(HomeController(), permanent: true);
        Get.put(BookingController(), permanent: true);
        Get.put(RiderController(), permanent: false);
        Get.lazyPut(() => WalletController(), fenix: true);
      }),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}