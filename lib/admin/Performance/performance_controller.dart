import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartstitch/models/rider_model.dart';

// ─── ARTIST MODEL (performance-specific) ─────────────────────────────────────

class ArtistModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalEarnings;
  final bool isActive;

  ArtistModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalEarnings,
    required this.isActive,
  });
}

// ─── SORT / FILTER ENUMS ─────────────────────────────────────────────────────

enum SortOption { totalOrders, rating, earnings, latest }

enum FilterOption { all, active, inactive }

// ─── BOOKING STATS HELPER (computed from `bookings` collection) ──────────────

class _BookingStats {
  int total = 0;
  int completed = 0;
  int cancelled = 0;
}

// ─── CONTROLLER ──────────────────────────────────────────────────────────────

class PerformanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Internal raw caches — combined together to build the final models.
  Map<String, Map<String, dynamic>> _artistDocs = {};
  Map<String, Map<String, dynamic>> _riderDocs = {};
  Map<String, Map<String, dynamic>> _userDocs = {};
  Map<String, double> _artistEarnings = {};
  Map<String, double> _riderEarnings = {};
  Map<String, _BookingStats> _artistStats = {};
  Map<String, _BookingStats> _riderStats = {};

  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxList<RiderModel> riders = <RiderModel>[].obs;
  final RxList<ArtistModel> filteredArtists = <ArtistModel>[].obs;
  final RxList<RiderModel> filteredRiders = <RiderModel>[].obs;

  final RxBool isLoadingArtists = true.obs;
  final RxBool isLoadingRiders = true.obs;
  final RxBool hasArtistError = false.obs;
  final RxBool hasRiderError = false.obs;
  final RxString artistError = ''.obs;
  final RxString riderError = ''.obs;

  final RxString searchQuery = ''.obs;
  final Rx<SortOption> sortOption = SortOption.totalOrders.obs;
  final Rx<FilterOption> filterOption = FilterOption.all.obs;

  final RxInt tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _listenArtists();
    _listenRiders();
    _listenArtistWallets();
    _listenRiderWallets();
    _listenUsers();
    _listenBookings();

    ever(searchQuery, (_) {
      _applyArtistFilters();
      _applyRiderFilters();
    });
    ever(sortOption, (_) {
      _applyArtistFilters();
      _applyRiderFilters();
    });
    ever(filterOption, (_) {
      _applyArtistFilters();
      _applyRiderFilters();
    });
    ever(artists, (_) => _applyArtistFilters());
    ever(riders, (_) => _applyRiderFilters());
  }

  // ─── FIRESTORE LISTENERS ────────────────────────────────────────────────

  void _listenArtists() {
    isLoadingArtists.value = true;
    hasArtistError.value = false;
    _firestore.collection('artists').snapshots().listen(
      (snapshot) {
        _artistDocs = {for (final d in snapshot.docs) d.id: d.data()};
        isLoadingArtists.value = false;
        _rebuildArtists();
      },
      onError: (e) {
        hasArtistError.value = true;
        artistError.value = e.toString();
        isLoadingArtists.value = false;
      },
    );
  }

  void _listenRiders() {
    isLoadingRiders.value = true;
    hasRiderError.value = false;
    _firestore.collection('riders').snapshots().listen(
      (snapshot) {
        _riderDocs = {for (final d in snapshot.docs) d.id: d.data()};
        isLoadingRiders.value = false;
        _rebuildRiders();
      },
      onError: (e) {
        hasRiderError.value = true;
        riderError.value = e.toString();
        isLoadingRiders.value = false;
      },
    );
  }

  void _listenArtistWallets() {
    _firestore.collection('artist_wallets').snapshots().listen((snapshot) {
      _artistEarnings = {
        for (final d in snapshot.docs)
          d.id: ((d.data()['lifetimeEarnings'] as num?)?.toDouble() ?? 0.0),
      };
      _rebuildArtists();
    });
  }

  void _listenRiderWallets() {
    _firestore.collection('rider_wallets').snapshots().listen((snapshot) {
      _riderEarnings = {
        for (final d in snapshot.docs)
          d.id: ((d.data()['lifetimeEarnings'] as num?)?.toDouble() ?? 0.0),
      };
      _rebuildRiders();
    });
  }

  void _listenUsers() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      _userDocs = {for (final d in snapshot.docs) d.id: d.data()};
      _rebuildRiders();
    });
  }

  void _listenBookings() {
    _firestore.collection('bookings').snapshots().listen((snapshot) {
      final artistStats = <String, _BookingStats>{};
      final riderStats = <String, _BookingStats>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final riderStatus =
            (data['riderStatus'] ?? '').toString().toLowerCase();

        final isCancelled = status == 'cancelled';
        final isCompleted = status == 'completed' || status == 'delivered';
        final isRiderDelivered = riderStatus == 'delivered' || isCompleted;

        final artistId = data['artistId']?.toString();
        if (artistId != null && artistId.isNotEmpty) {
          final s = artistStats.putIfAbsent(artistId, () => _BookingStats());
          s.total++;
          if (isCompleted) s.completed++;
          if (isCancelled) s.cancelled++;
        }

        final riderId = data['riderId']?.toString();
        if (riderId != null && riderId.isNotEmpty) {
          final s = riderStats.putIfAbsent(riderId, () => _BookingStats());
          s.total++;
          if (isRiderDelivered) s.completed++;
          if (isCancelled) s.cancelled++;
        }
      }

      _artistStats = artistStats;
      _riderStats = riderStats;
      _rebuildArtists();
      _rebuildRiders();
    });
  }

  // ─── REBUILD MODELS FROM COMBINED CACHES ───────────────────────────────

  void _rebuildArtists() {
    if (_artistDocs.isEmpty) return;
    final list = _artistDocs.entries.map((e) {
      final id = e.key;
      final data = e.value;
      final stats = _artistStats[id];
      return ArtistModel(
        id: id,
        name: data['businessName']?.toString() ??
            data['name']?.toString() ??
            '',
        imageUrl: data['profileImageUrl']?.toString() ??
            data['imageUrl']?.toString() ??
            '',
        rating: (data['averageRating'] as num?)?.toDouble() ??
            (data['rating'] as num?)?.toDouble() ??
            0.0,
        totalOrders:
            stats?.total ?? (data['totalOrders'] as num?)?.toInt() ?? 0,
        completedOrders: stats?.completed ?? 0,
        cancelledOrders: stats?.cancelled ?? 0,
        totalEarnings: _artistEarnings[id] ??
            (data['totalEarnings'] as num?)?.toDouble() ??
            0.0,
        isActive:
            data['isAvailable'] as bool? ?? data['isActive'] as bool? ?? false,
      );
    }).toList();
    artists.value = list;
  }

  void _rebuildRiders() {
    if (_riderDocs.isEmpty) return;
    final list = _riderDocs.entries.map((e) {
      final id = e.key;
      final data = e.value;
      final stats = _riderStats[id];
      final userData = _userDocs[data['userId']?.toString() ?? ''];

      final total =
          stats?.total ?? (data['totalDeliveries'] as num?)?.toInt() ?? 0;
      final completed = stats?.completed ??
          (data['completedDeliveries'] as num?)?.toInt() ??
          0;
      final cancelled = stats?.cancelled ?? 0;
      final active = (total - completed - cancelled).clamp(0, 1 << 30);

      return RiderModel(
        id: id,
        userId: data['userId']?.toString() ?? '',
        name: userData?['fullName']?.toString() ??
            userData?['name']?.toString() ??
            data['name']?.toString() ??
            '',
        imageUrl: userData?['profileImageUrl']?.toString() ??
            userData?['imageUrl']?.toString() ??
            data['imageUrl']?.toString() ??
            '',
        cnicNumber: data['cnicNumber']?.toString() ?? '',
        cnicImageUrl: data['cnicImageUrl']?.toString() ?? '',
        drivingLicenseUrl: data['drivingLicenseUrl']?.toString() ?? '',
        vehicleType: data['vehicleType']?.toString() ?? '',
        vehicleNumber: data['vehicleNumber']?.toString() ?? '',
        rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        totalDeliveries: total,
        activeDeliveries: active,
        completedDeliveries: completed,
        totalEarnings: _riderEarnings[id] ??
            (data['totalEarnings'] as num?)?.toDouble() ??
            0.0,
        isOnline: data['isOnline'] as bool? ?? false,
        joinedAt: _parseDate(data['joinedAt']),
      );
    }).toList();
    riders.value = list;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // ─── FILTER / SORT ──────────────────────────────────────────────────────

  void _applyArtistFilters() {
    var list = List<ArtistModel>.from(artists);

    if (filterOption.value == FilterOption.active) {
      list = list.where((a) => a.isActive).toList();
    } else if (filterOption.value == FilterOption.inactive) {
      list = list.where((a) => !a.isActive).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    switch (sortOption.value) {
      case SortOption.totalOrders:
        list.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
        break;
      case SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.earnings:
        list.sort((a, b) => b.totalEarnings.compareTo(a.totalEarnings));
        break;
      case SortOption.latest:
        break;
    }

    filteredArtists.value = list;
  }

  void _applyRiderFilters() {
    var list = List<RiderModel>.from(riders);

    if (filterOption.value == FilterOption.active) {
      list = list.where((r) => r.isOnline).toList();
    } else if (filterOption.value == FilterOption.inactive) {
      list = list.where((r) => !r.isOnline).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    switch (sortOption.value) {
      case SortOption.totalOrders:
        list.sort((a, b) => b.totalDeliveries.compareTo(a.totalDeliveries));
        break;
      case SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.earnings:
        list.sort((a, b) => b.totalEarnings.compareTo(a.totalEarnings));
        break;
      case SortOption.latest:
        break;
    }

    filteredRiders.value = list;
  }

  void onSearch(String query) => searchQuery.value = query;
  void onSortChanged(SortOption option) => sortOption.value = option;
  void onFilterChanged(FilterOption option) => filterOption.value = option;

  String get sortLabel {
    switch (sortOption.value) {
      case SortOption.totalOrders:
        return 'Total Orders';
      case SortOption.rating:
        return 'Rating';
      case SortOption.earnings:
        return 'Earnings';
      case SortOption.latest:
        return 'Latest';
    }
  }
}