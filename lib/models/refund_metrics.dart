class RefundMetrics {
  final double totalRefunds;
  final List<double> refundTrend;

  RefundMetrics({
    required this.totalRefunds,
    required this.refundTrend,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalRefunds': totalRefunds,
      'refundTrend': refundTrend,
    };
  }

  factory RefundMetrics.empty(int bucketCount) {
    return RefundMetrics(
      totalRefunds: 0.0,
      refundTrend: List<double>.filled(bucketCount, 0.0),
    );
  }
}
