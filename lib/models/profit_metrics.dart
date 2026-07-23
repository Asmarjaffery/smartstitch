class ProfitMetrics {
  final double profit;
  final double loss;
  final List<double> profitTrend;
  final List<double> lossTrend;

  ProfitMetrics({
    required this.profit,
    required this.loss,
    required this.profitTrend,
    required this.lossTrend,
  });

  Map<String, dynamic> toMap() {
    return {
      'profit': profit,
      'loss': loss,
      'profitTrend': profitTrend,
      'lossTrend': lossTrend,
    };
  }

  factory ProfitMetrics.empty(int bucketCount) {
    return ProfitMetrics(
      profit: 0.0,
      loss: 0.0,
      profitTrend: List<double>.filled(bucketCount, 0.0),
      lossTrend: List<double>.filled(bucketCount, 0.0),
    );
  }
}
