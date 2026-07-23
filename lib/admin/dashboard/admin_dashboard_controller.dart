import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/dashboard_models.dart';

class AdminDashboardController extends GetxController {
  static AdminDashboardController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final isLoading = true.obs;

  // KPI values
  final totalRevenue = 0.0.obs;
  final totalOrders = 0.obs;
  final totalCustomers = 0.obs;
  final totalArtists = 0.obs;
  final totalRiders = 0.obs;
  final activeServices = 0.obs;
  final pendingOrders = 0.obs;
  final monthlyGrowth = 0.0.obs;

  // Chart data
  final revenueTrend = <double>[].obs; // last 7 points
  final ordersTrend = <int>[].obs; // last 7 points
  final weeklyEarnings = <double>[0, 0, 0, 0, 0, 0, 0].obs;

  // Lists
  final recentOrders = <RecentOrderModel>[].obs;
  final recentReviews = <ReviewModel>[].obs;
  final latestComplaints = <ComplaintModel>[].obs;
  final latestPayments = <PaymentModel>[].obs;
  final upcomingAppointments = <AppointmentModel>[].obs;
  final activityTimeline = <ActivityModel>[].obs;

  final Map<String, Map<String, dynamic>> _orderDocs = {};
  final Map<String, Map<String, dynamic>> _bookingDocs = {};
  final Map<String, String> _userNames = {};

  @override
  void onInit() {
    super.onInit();
    _listenUsers();
    _listenOrdersAndBookings();
    _listenServices();
    _listenReviews();
    _listenComplaints();
    _listenPayments();
    _listenAppointments();
    _listenActivity();
  }

  void _listenUsers() {
  _db.collection('users').snapshots().listen((snap) {
    final docs = snap.docs;

    _userNames.clear();

    for (final doc in docs) {
      final data = doc.data();

      _userNames[doc.id] =
          data['fullName'] ??
          data['name'] ??
          data['username'] ??
          'Unknown';
    }

    totalCustomers.value =
        docs.where((d) => d['role'] == 'customer').length;

    totalArtists.value =
        docs.where((d) => d['role'] == 'artist').length;

    totalRiders.value =
        docs.where((d) => d['role'] == 'rider').length;

    // Refresh recent orders once names are available
    _rebuildRecentOrders();

    isLoading.value = false;
  });
}

  void _listenServices() {
    _db.collection('services').snapshots().listen((snap) {
      activeServices.value = snap.docs.length;
    });
  }

  void _listenOrdersAndBookings() {
    void recalc() {
      final all = <String, Map<String, dynamic>>{}
        ..addAll(_orderDocs)
        ..addAll(_bookingDocs);
      final docs = all.values.toList();

      totalOrders.value = docs.length;
      pendingOrders.value = docs.where((d) => d['status'] == 'pending').length;

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));

      double total = 0;
      double thisMonthRevenue = 0;
      double lastMonthRevenue = 0;
      final weekAgo = now.subtract(const Duration(days: 7));
      final weekMap = <int, double>{0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

      final dailyRevenueMap = <String, double>{};
      final dailyOrdersMap = <String, int>{};

      for (final doc in docs) {
        final status = doc['status'] as String? ?? '';
        final amount =
            (doc['totalAmount'] ?? doc['servicePrice'] ?? 0).toDouble();

        final ts = doc['createdAt'];
        DateTime? date;
        if (ts is Timestamp) {
          date = ts.toDate();
        } else if (ts is String) {
          date = DateTime.tryParse(ts);
        }

        if (date != null) {
          final dayKey = '${date.year}-${date.month}-${date.day}';
          dailyOrdersMap[dayKey] = (dailyOrdersMap[dayKey] ?? 0) + 1;
        }

        if (status != 'delivered' && status != 'completed') continue;

        total += amount;

        if (date != null) {
          if (!date.isBefore(thisMonthStart)) thisMonthRevenue += amount;
          if (!date.isBefore(lastMonthStart) && date.isBefore(lastMonthEnd)) {
            lastMonthRevenue += amount;
          }
          if (date.isAfter(weekAgo)) {
            final idx = date.weekday - 1;
            weekMap[idx] = (weekMap[idx] ?? 0) + amount;
          }
          final dayKey = '${date.year}-${date.month}-${date.day}';
          dailyRevenueMap[dayKey] = (dailyRevenueMap[dayKey] ?? 0) + amount;
        }
      }

      totalRevenue.value = total;
      weeklyEarnings.value = List.generate(7, (i) => weekMap[i] ?? 0);

      monthlyGrowth.value = lastMonthRevenue == 0
          ? (thisMonthRevenue > 0 ? 100 : 0)
          : ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100;

      // last 7 days trend
      final last7Revenue = <double>[];
      final last7Orders = <int>[];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.year}-${d.month}-${d.day}';
        last7Revenue.add(dailyRevenueMap[key] ?? 0);
        last7Orders.add(dailyOrdersMap[key] ?? 0);
      }
      revenueTrend.value = last7Revenue;
      ordersTrend.value = last7Orders;

      // recent orders (latest 6)
      _rebuildRecentOrders();
    }

    _db.collection('orders').snapshots().listen((snap) {
      _orderDocs.clear();
      for (final doc in snap.docs) {
        _orderDocs[doc.id] = {...doc.data(), '_docId': doc.id};
      }
      recalc();
    });

    _db.collection('bookings').snapshots().listen((snap) {
      _bookingDocs.clear();
      for (final doc in snap.docs) {
        _bookingDocs[doc.id] = {
          ...doc.data(),
          'totalAmount': doc.data()['servicePrice'],
          '_docId': doc.id,
        };
      }
      recalc();
    });
  }

  void _listenReviews() {
    _db
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      recentReviews.value =
          snap.docs.map((d) => ReviewModel.fromMap(d.id, d.data())).toList();
    });
  }

  void _listenComplaints() {
    _db
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      latestComplaints.value =
          snap.docs.map((d) => ComplaintModel.fromMap(d.id, d.data())).toList();
    });
  }

  void _listenPayments() {
    _db
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      latestPayments.value =
          snap.docs.map((d) => PaymentModel.fromMap(d.id, d.data())).toList();
    });
  }

  void _listenAppointments() {
    final now = Timestamp.now();
    _db
        .collection('bookings')
        .where('scheduledAt', isGreaterThanOrEqualTo: now)
        .orderBy('scheduledAt')
        .limit(5)
        .snapshots()
        .listen((snap) {
      upcomingAppointments.value = snap.docs
          .map((d) => AppointmentModel.fromMap(d.id, d.data()))
          .toList();
    }, onError: (_) {
      upcomingAppointments.value = [];
    });
  }

  void _listenActivity() {
    _db
        .collection('activity_logs')
        .orderBy('createdAt', descending: true)
        .limit(8)
        .snapshots()
        .listen((snap) {
      activityTimeline.value =
          snap.docs.map((d) => ActivityModel.fromMap(d.id, d.data())).toList();
    }, onError: (_) {
      activityTimeline.value = [];
    });
  }
void _rebuildRecentOrders() {
  final docs = [
    ..._orderDocs.values,
    ..._bookingDocs.values,
  ];

  docs.sort((a, b) {
    DateTime parse(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime(2000);
      return DateTime(2000);
    }

    return parse(b['createdAt']).compareTo(parse(a['createdAt']));
  });

  recentOrders.value = docs.take(6).map((d) {
    final customerId = d['customerId'];
    final artistId = d['artistId'];
    final riderId = d['riderId'];

    return RecentOrderModel(
      orderId: d['_docId'] ?? '',

      customerName: _userNames[customerId] ?? 'Unknown',

      artistName: _userNames[artistId] ?? 'Unassigned',

      riderName: riderId == null
          ? null
          : _userNames[riderId],

      amount:
          (d['totalAmount'] ?? d['servicePrice'] ?? 0)
              .toDouble(),

      status: d['status'] ?? 'pending',

      date: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(d['createdAt'] ?? '') ??
              DateTime.now(),
    );
  }).toList();
}
  Future<void> approvePendingArtist(String userId) async {
    await _db.collection('users').doc(userId).update({'isVerified': true});
  }

  Future<void> approvePendingRider(String userId) async {
    await _db.collection('users').doc(userId).update({'isVerified': true});
  }
}
