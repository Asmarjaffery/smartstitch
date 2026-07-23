import '../models/analytics_metrics.dart';

class ChartService {
  static List<ServiceSlice> buildServiceSlices(Map<String, int> serviceCounts) {
    if (serviceCounts.isEmpty) return [];
    
    final sorted = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    final topSlices = sorted.take(6).toList();
    
    return List.generate(topSlices.length, (i) {
      return ServiceSlice(
        label: topSlices[i].key,
        value: topSlices[i].value.toDouble(),
        colorIndex: i,
      );
    });
  }
}
