

import 'package:smartstitch/core/utils/parser_helper.dart';

class GrowthService {
  static Map<String, List<double>> calculateGrowthSeries(
    List<Map<String, dynamic>> userDocs,
  ) {
    final now = DateTime.now();
    final monthStarts = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );

    final List<double> customerGrowth = [];
    final List<double> artistGrowth = [];
    final List<double> riderGrowth = [];

    for (final monthStart in monthStarts) {
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      double customers = 0;
      double artists = 0;
      double riders = 0;

      for (final u in userDocs) {
        final created = ParserHelper.parseDate(u['createdAt']);
        if (created == null || created.isAfter(monthEnd) || created.isAtSameMomentAs(monthEnd)) {
          continue;
        }

        final role = ParserHelper.parseString(u['role']).toLowerCase();
        if (role == 'customer' || role == 'user') customers++;
        if (role == 'artist') artists++;
        if (role == 'rider') riders++;
      }

      customerGrowth.add(customers);
      artistGrowth.add(artists);
      riderGrowth.add(riders);
    }

    return {
      'customers': customerGrowth,
      'artists': artistGrowth,
      'riders': riderGrowth,
    };
  }
}
