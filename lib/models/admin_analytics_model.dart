class AdminAnalyticsModel {
  final double totalRevenue;
  final double totalCommission;
  final int totalUsers;
  final int totalArtists;
  final int totalRiders;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int pendingComplaints;
  final int pendingWithdrawals;
  final Map<String, double> monthlyRevenue; 
  final DateTime generatedAt;

  const AdminAnalyticsModel({
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalUsers,
    required this.totalArtists,
    required this.totalRiders,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.pendingComplaints,
    required this.pendingWithdrawals,
    required this.monthlyRevenue,
    required this.generatedAt,
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) =>
      AdminAnalyticsModel(
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        totalCommission: (json['totalCommission'] as num).toDouble(),
        totalUsers: json['totalUsers'] as int,
        totalArtists: json['totalArtists'] as int,
        totalRiders: json['totalRiders'] as int,
        totalOrders: json['totalOrders'] as int,
        pendingOrders: json['pendingOrders'] as int,
        completedOrders: json['completedOrders'] as int,
        cancelledOrders: json['cancelledOrders'] as int,
        pendingComplaints: json['pendingComplaints'] as int,
        pendingWithdrawals: json['pendingWithdrawals'] as int,
        monthlyRevenue: Map<String, double>.from(
          (json['monthlyRevenue'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        ),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'totalRevenue': totalRevenue,
        'totalCommission': totalCommission,
        'totalUsers': totalUsers,
        'totalArtists': totalArtists,
        'totalRiders': totalRiders,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'pendingComplaints': pendingComplaints,
        'pendingWithdrawals': pendingWithdrawals,
        'monthlyRevenue': monthlyRevenue,
        'generatedAt': generatedAt.toIso8601String(),
      };
}
