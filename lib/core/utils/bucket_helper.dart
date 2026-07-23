import 'dart:math' as math;
import 'package:smartstitch/models/enums.dart';


class BucketConfig {
  final DateTime start;
  final int bucketCount;
  final String mode;

  BucketConfig._(this.start, this.bucketCount, this.mode);

  factory BucketConfig.hourly(DateTime start) =>
      BucketConfig._(start, 24, 'hourly');
      
  factory BucketConfig.daily(DateTime start, int count) =>
      BucketConfig._(DateTime(start.year, start.month, start.day), count, 'daily');
      
  factory BucketConfig.monthly(DateTime start, int count) =>
      BucketConfig._(DateTime(start.year, start.month, 1), count, 'monthly');

  int indexOf(DateTime dt) {
    if (mode == 'hourly') {
      if (dt.year != start.year || dt.month != start.month || dt.day != start.day) {
        return -1;
      }
      return dt.hour.clamp(0, bucketCount - 1);
    }

    if (mode == 'daily') {
      final normalized = DateTime(start.year, start.month, start.day);
      final diff = DateTime(dt.year, dt.month, dt.day).difference(normalized).inDays;
      return diff >= 0 && diff < bucketCount ? diff : -1;
    }

    final s = DateTime(start.year, start.month, 1);
    final diffMonths = (dt.year - s.year) * 12 + (dt.month - s.month);
    return diffMonths >= 0 && diffMonths < bucketCount ? diffMonths : -1;
  }

  List<String> labels() {
    if (mode == 'hourly') {
      return List.generate(bucketCount, (i) => '${i.toString().padLeft(2, '0')}:00',
          growable: false);
    }
    if (mode == 'daily') {
      return List.generate(bucketCount, (i) {
        final d = start.add(Duration(days: i));
        return '${d.day}/${d.month}';
      }, growable: false);
    }
    return List.generate(bucketCount, (i) {
      final d = DateTime(start.year, start.month + i, 1);
      return '${d.month}/${d.year}';
    }, growable: false);
  }

  static BucketConfig build(DateTime start, DateTime end, AnalyticsFilter filter) {
    final diff = end.difference(start);
    final days = diff.inDays.abs();

    if (filter == AnalyticsFilter.today || days <= 1) {
      return BucketConfig.hourly(DateTime(start.year, start.month, start.day));
    }
    if (filter == AnalyticsFilter.last7Days) {
      return BucketConfig.daily(start, 7);
    }
    if (filter == AnalyticsFilter.last30Days) {
      return BucketConfig.daily(start, 30);
    }
    if (filter == AnalyticsFilter.last6Months) {
      return BucketConfig.monthly(start, 6);
    }
    if (filter == AnalyticsFilter.lastYear) {
      return BucketConfig.monthly(start, 12);
    }

    final rangeDays = math.max(1, end.difference(start).inDays + 1);
    if (rangeDays <= 1) return BucketConfig.hourly(start);
    if (rangeDays <= 35) return BucketConfig.daily(start, math.min(30, rangeDays));
    return BucketConfig.monthly(start, math.min(12, rangeDays ~/ 30 + 1));
  }
}
