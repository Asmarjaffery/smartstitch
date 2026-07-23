class WithdrawalMetrics {
  final double totalWithdrawals;
  final List<double> withdrawalTrend;

  WithdrawalMetrics({
    required this.totalWithdrawals,
    required this.withdrawalTrend,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalWithdrawals': totalWithdrawals,
      'withdrawalTrend': withdrawalTrend,
    };
  }

  factory WithdrawalMetrics.empty(int bucketCount) {
    return WithdrawalMetrics(
      totalWithdrawals: 0.0,
      withdrawalTrend: List<double>.filled(bucketCount, 0.0),
    );
  }
}
