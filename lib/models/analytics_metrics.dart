import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/top_performer_entry.dart';

class ServiceSlice {
  final String label;
  final double value;
  final int colorIndex;

  ServiceSlice({
    required this.label,
    required this.value,
    required this.colorIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'value': value,
      'colorIndex': colorIndex,
    };
  }

  factory ServiceSlice.fromMap(Map<String, dynamic> map) {
    return ServiceSlice(
      label: map['label'] ?? '',
      value: (map['value'] ?? 0.0).toDouble(),
      colorIndex: map['colorIndex'] ?? 0,
    );
  }
}

class AnalyticsMetrics {
  double dailyRevenue;
  double weeklyRevenue;
  double monthlyRevenue;
  double yearlyRevenue;
  double grossSales;
  int totalOrders;
  int deliveredCount;
  int completedCount;
  int activeCount;
  int cancelledCount;
  double cancellationRate;
  double deliverySuccessRate;
  double avgOrderValue;
  double avgDeliveryTime;
  double avgStitchingTime;
  double platformRevenue;
  double adminCommission;
  double artistEarnings;
  double riderEarnings;

  String highestRevenueCategory;
  List<ServiceSlice> servicePopularitySlices;

  List<double> revenueTrend;
  List<int> ordersTrend;

  // ─── ADDED: Top performer lists (were missing, causing undefined_setter) ───
  List<TopPerformerEntry> topArtists;
  List<TopPerformerEntry> topRiders;
  List<TopPerformerEntry> topCustomers;
  List<TopPerformerEntry> highestPayingCustomers;

  AnalyticsMetrics({
    this.dailyRevenue = 0.0,
    this.weeklyRevenue = 0.0,
    this.monthlyRevenue = 0.0,
    this.yearlyRevenue = 0.0,
    this.grossSales = 0.0,
    this.totalOrders = 0,
    this.deliveredCount = 0,
    this.completedCount = 0,
    this.activeCount = 0,
    this.cancelledCount = 0,
    this.cancellationRate = 0.0,
    this.deliverySuccessRate = 0.0,
    this.avgOrderValue = 0.0,
    this.avgDeliveryTime = 0.0,
    this.avgStitchingTime = 0.0,
    this.platformRevenue = 0.0,
    this.adminCommission = 0.0,
    this.artistEarnings = 0.0,
    this.riderEarnings = 0.0,
    this.highestRevenueCategory = '',
    this.servicePopularitySlices = const [],
    this.revenueTrend = const [],
    this.ordersTrend = const [],
    this.topArtists = const [],
    this.topRiders = const [],
    this.topCustomers = const [],
    this.highestPayingCustomers = const [],
  });
}

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