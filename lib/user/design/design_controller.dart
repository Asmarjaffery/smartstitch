import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartstitch/models/artist_model.dart';

// ─── Sort Options ────────────────────────────────────────────────────────────
enum DesignSortOption { newest, priceLowToHigh, priceHighToLow, popular }

// ─── Design Explore Item (denormalized: service + artist info) ────────────
class DesignExploreItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final String artistId;
  final String artistName;
  final String artistImage;
  final double artistRating;
  final bool artistVerified;
  final int ordersCount;
  final DateTime? createdAt;

  DesignExploreItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.artistId,
    required this.artistName,
    required this.artistImage,
    required this.artistRating,
    required this.artistVerified,
    required this.ordersCount,
    this.createdAt,
  });

  factory DesignExploreItem.fromServiceDoc(
      String id, Map<String, dynamic> data, ArtistModel? artist) {
    // Build gallery the same way the rest of the app maps 'services' docs.
    final gallery = <String>[];
    if (data['coverImageUrl'] != null &&
        (data['coverImageUrl'] as String).isNotEmpty) {
      gallery.add(data['coverImageUrl'] as String);
    }
    if (data['galleryImageUrls'] is List) {
      for (final img in data['galleryImageUrls'] as List) {
        if (img is String && img.isNotEmpty) gallery.add(img);
      }
    }

    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw);
    }

    String artistImage = '';
    if (artist != null) {
      if (artist.profileImageUrl.isNotEmpty) {
        artistImage = artist.profileImageUrl;
      } else if (artist.portfolioImages.isNotEmpty) {
        artistImage = artist.portfolioImages.first;
      }
    }

    return DesignExploreItem(
      id: id,
      title: data['serviceName'] as String? ?? '',
      description: data['shortDescription'] as String? ?? '',
      category: data['category'] as String? ?? '',
      price: (data['startingPrice'] as num?)?.toDouble() ?? 0,
      imageUrls: gallery,
      artistId: data['artistId'] as String? ?? '',
      artistName: artist?.businessName ?? 'Artist',
      artistImage: artistImage,
      artistRating: artist?.rating ?? 0,
      artistVerified: artist?.isVerified ?? false,
      ordersCount: (data['ordersCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
    );
  }
}

// ─── Controller ──────────────────────────────────────────────────────────────
class DesignExploreController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  final List<DesignExploreItem> _allDesigns = [];
  final RxList<DesignExploreItem> filteredDesigns = <DesignExploreItem>[].obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final Rx<DesignSortOption> sortOption = DesignSortOption.newest.obs;
  final RxList<String> categories = <String>['All'].obs;

  // Simple in-memory cache so re-opening a design's artist doesn't refetch.
  final Map<String, ArtistModel> _artistCache = {};

  @override
  void onInit() {
    super.onInit();
    fetchDesigns();
  }

  // ─── Fetch all published designs from every artist ──────────────────────
  // NOTE: Deliberately using only equality filters (no orderBy) here so this
  // query never needs a Firestore composite index — sorting/searching is
  // done client-side below instead.
  Future<void> fetchDesigns({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      errorMessage.value = '';

      final snap = await _db
          .collection('services')
          .where('type', isEqualTo: 'artist')
          .where('status', isEqualTo: 'published')
          .get();

      final docs = snap.docs;

      final artistIds = docs
          .map((d) => (d.data()['artistId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      await _cacheArtists(artistIds);

      final items = docs.map((doc) {
        final data = doc.data();
        final artistId = data['artistId'] as String? ?? '';
        return DesignExploreItem.fromServiceDoc(
            doc.id, data, _artistCache[artistId]);
      }).toList();

      _allDesigns
        ..clear()
        ..addAll(items);

      final cats = items
          .map((i) => i.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      categories.value = ['All', ...cats];

      _applyFilters();
    } catch (e) {
      debugPrint('❌ DesignExploreController.fetchDesigns error: $e');
      errorMessage.value = 'Could not load designs. Pull down to refresh.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() async {
    isRefreshing.value = true;
    await fetchDesigns(silent: true);
  }

  // ─── Batch-fetch artist docs (chunked to respect Firestore's 30-item
  // whereIn limit) so the grid doesn't do one query per card. ──────────────
  Future<void> _cacheArtists(List<String> ids) async {
    final toFetch = ids.where((id) => !_artistCache.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    for (final chunk in _chunks(toFetch, 30)) {
      try {
        final snap = await _db
            .collection('artists')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          _artistCache[doc.id] =
              ArtistModel.fromJson({...doc.data(), 'id': doc.id});
        }
      } catch (e) {
        debugPrint('❌ _cacheArtists chunk error: $e');
      }
    }
  }

  List<List<T>> _chunks<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(
          i, (i + size > list.length) ? list.length : i + size));
    }
    return result;
  }

  // Used by the detail sheet / booking flow, which need the full ArtistModel.
  Future<ArtistModel?> getArtist(String artistId) async {
    if (_artistCache.containsKey(artistId)) return _artistCache[artistId];
    try {
      final doc = await _db.collection('artists').doc(artistId).get();
      if (!doc.exists) return null;
      final artist = ArtistModel.fromJson({...doc.data()!, 'id': doc.id});
      _artistCache[artistId] = artist;
      return artist;
    } catch (_) {
      return null;
    }
  }

  // ─── Search / Filter / Sort ──────────────────────────────────────────────
  void search(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void setSort(DesignSortOption option) {
    sortOption.value = option;
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<DesignExploreItem>.from(_allDesigns);

    if (selectedCategory.value != 'All') {
      list = list.where((d) => d.category == selectedCategory.value).toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.artistName.toLowerCase().contains(q) ||
            d.category.toLowerCase().contains(q);
      }).toList();
    }

    switch (sortOption.value) {
      case DesignSortOption.newest:
        list.sort((a, b) => (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000)));
        break;
      case DesignSortOption.priceLowToHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case DesignSortOption.priceHighToLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case DesignSortOption.popular:
        list.sort((a, b) => b.ordersCount.compareTo(a.ordersCount));
        break;
    }

    filteredDesigns.value = list;
  }
}