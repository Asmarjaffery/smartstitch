import 'package:smartstitch/models/top_performer_entry.dart';

import '../models/analytics_metrics.dart';

class PerformerService {
  static List<TopPerformerEntry> getTopPerformersFromDouble(
    Map<String, double> scores, {
    required Map<String, String> names,
    required Map<String, String> avatars,
    required String Function(double val) subtitleBuilder,
  }) {
    if (scores.isEmpty) return [];

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) {
      return TopPerformerEntry(
        name: names[e.key] ?? e.key,
        subtitle: subtitleBuilder(e.value),
        value: e.value,
        imageUrl: avatars[e.key],
      );
    }).toList();
  }

  static List<TopPerformerEntry> getTopPerformersFromInt(
    Map<String, int> scores, {
    required Map<String, String> names,
    required Map<String, String> avatars,
    required String Function(int val) subtitleBuilder,
  }) {
    if (scores.isEmpty) return [];

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) {
      return TopPerformerEntry(
        name: names[e.key] ?? e.key,
        subtitle: subtitleBuilder(e.value),
        value: e.value.toDouble(),
        imageUrl: avatars[e.key],
      );
    }).toList();
  }
}
