import 'package:smartstitch/models/enums.dart';
import 'admin_context.dart';
import 'artist_context.dart';
import 'customer_context.dart';
import 'rider_context.dart';

/// Dispatches context fetching to the correct role-specific provider.
class AiContextProvider {
  AiContextProvider._();

  static final _customer = CustomerContext();
  static final _artist = ArtistContext();
  static final _rider = RiderContext();
  static final _admin = AdminContext();

  /// Fetch Firestore context and return a plain-text summary string.
  static Future<String> getSummary({
    required String userId,
    required UserRole role,
  }) async {
    // TEMP DEBUG — remove once context is confirmed working.
    // ignore: avoid_print
    print('[AiContextProvider] fetching context for userId="$userId" role=$role');
    if (userId.isEmpty) {
      // ignore: avoid_print
      print('[AiContextProvider] userId is EMPTY — AuthController.currentUserId '
          'is not returning a value. This alone will make context blank.');
      return 'Context unavailable: no userId';
    }
    try {
      String summary;
      switch (role) {
        case UserRole.customer:
          final ctx = await _customer.fetch(userId);
          summary = _customer.toSummary(ctx);
          break;
        case UserRole.artist:
          final ctx = await _artist.fetch(userId);
          summary = _artist.toSummary(ctx);
          break;
        case UserRole.rider:
          final ctx = await _rider.fetch(userId);
          summary = _rider.toSummary(ctx);
          break;
        case UserRole.admin:
          final ctx = await _admin.fetch(userId);
          summary = _admin.toSummary(ctx);
          break;
      }
      // ignore: avoid_print
      print('[AiContextProvider] SUMMARY BUILT (${summary.length} chars):\n$summary');
      return summary;
    } catch (e) {
      // ignore: avoid_print
      print('[AiContextProvider] getSummary ERROR: $e');
      return 'Context unavailable: $e';
    }
  }
}