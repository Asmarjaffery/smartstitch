import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'package:smartstitch/artist/design/design_screen.dart'; 

class ArtistPortfolioController extends GetxController {
  ArtistPortfolioController();
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _serviceSubscription;
  Timer? _loadingTimeout;

  /// Loading
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;

  /// Search
  final RxString searchText = ''.obs;

  /// Lists
  final RxList<Map<String, dynamic>> portfolio = <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> filteredPortfolio =
      <Map<String, dynamic>>[].obs;

  /// Dashboard Stats
  final RxInt totalDesigns = 0.obs;
  final RxInt publishedDesigns = 0.obs;
  final RxInt draftDesigns = 0.obs;
  final RxInt totalOrders = 0.obs;
  final RxInt totalCategories = 0.obs;
  final RxDouble averageRating = 0.0.obs;

  String get artistId => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();

    debugPrint("🎨 ArtistPortfolioController initialized");
    debugPrint("Current Artist ID: $artistId");

    debounce(
      searchText,
      (_) => _applySearch(),
      time: const Duration(milliseconds: 300),
    );

    _listenPortfolio();
  }

  @override
  void onClose() {
    _serviceSubscription?.cancel();
    _loadingTimeout?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  Future<void> refreshPortfolio() async {
    debugPrint("🔄 Refreshing portfolio...");
    isRefreshing.value = true;

    _serviceSubscription?.cancel();
    _loadingTimeout?.cancel();

    _listenPortfolio();

    await Future.delayed(const Duration(milliseconds: 500));

    isRefreshing.value = false;
  }

  void _listenPortfolio() {
    debugPrint("📱 Starting portfolio listener...");
    debugPrint("Current Artist ID: $artistId");

    if (artistId.isEmpty) {
      debugPrint("❌ Artist ID is empty - user not logged in");
      isLoading.value = false;
      Get.snackbar(
        'Portfolio',
        'Please login first',
        backgroundColor: Colors.red,
      );
      return;
    }

    isLoading.value = true;

    // Timeout handler - if data doesn't load in 10 seconds, show empty state
    _loadingTimeout = Timer(const Duration(seconds: 10), () {
      if (isLoading.value) {
        debugPrint("⏱️ Loading timeout - showing empty state");
        isLoading.value = false;
        Get.snackbar(
          'Portfolio',
          'Unable to load portfolio. Please refresh.',
          backgroundColor: Colors.orange,
        );
      }
    });

    try {
      _serviceSubscription = _firestore
          .collection('services')
          .where('artistId', isEqualTo: artistId)
          .snapshots()
          .listen(
        (snapshot) {
          debugPrint("✅ Firestore snapshot received");
          debugPrint("📊 Total services found: ${snapshot.docs.length}");

          _loadingTimeout?.cancel();

          final List<Map<String, dynamic>> services = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            debugPrint("📄 Service: ${data['serviceName']} | Status: ${data['status']}");

            services.add({
              'id': doc.id,
              ...data,
            });
          }

          portfolio.assignAll(services);
          debugPrint("✔️ Portfolio loaded with ${services.length} items");

          _calculateStats();

          _applySearch();

          isLoading.value = false;
        },
        onError: (error) {
          debugPrint("❌ Firestore error: $error");

          _loadingTimeout?.cancel();
          isLoading.value = false;

          Get.snackbar(
            'Portfolio',
            'Error loading portfolio: ${error.toString()}',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          );
        },
      );
    } catch (e) {
      debugPrint("❌ Exception in _listenPortfolio: $e");
      _loadingTimeout?.cancel();
      isLoading.value = false;
      Get.snackbar(
        'Portfolio',
        'Error: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  void _calculateStats() {
    totalDesigns.value = portfolio.length;

    publishedDesigns.value = portfolio
        .where(
          (e) => (e['status'] ?? '').toString().toLowerCase() == 'published',
        )
        .length;

    draftDesigns.value = portfolio
        .where(
          (e) => (e['status'] ?? '').toString().toLowerCase() == 'draft',
        )
        .length;

    final categories = <String>{};

    int orders = 0;
    double ratingSum = 0;
    int ratingCount = 0;

    for (final service in portfolio) {
      final category = service['categoryName']?.toString() ?? '';

      if (category.isNotEmpty) {
        categories.add(category);
      }

      orders += (service['ordersCount'] ?? 0) as int;

      final rating = (service['rating'] ?? 0).toDouble();

      if (rating > 0) {
        ratingSum += rating;
        ratingCount++;
      }
    }

    totalCategories.value = categories.length;
    totalOrders.value = orders;
    averageRating.value = ratingCount == 0 ? 0 : ratingSum / ratingCount;

    debugPrint("📊 Stats - Total: $totalDesigns, Published: $publishedDesigns, Draft: $draftDesigns, Orders: $totalOrders");
  }

  void _applySearch() {
    final query = searchText.value.trim().toLowerCase();

    if (query.isEmpty) {
      filteredPortfolio.assignAll(portfolio);
      return;
    }

    final result = portfolio.where((service) {
      final serviceName =
          (service['serviceName'] ?? '').toString().toLowerCase();

      final category = (service['categoryName'] ?? '').toString().toLowerCase();

      return serviceName.contains(query) || category.contains(query);
    }).toList();

    filteredPortfolio.assignAll(result);
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  void showAll() {
    filteredPortfolio.assignAll(portfolio);
  }

  void showPublished() {
    filteredPortfolio.assignAll(
      portfolio.where(
        (e) => (e['status'] ?? '').toString().toLowerCase() == 'published',
      ),
    );
  }

  void showDraft() {
    filteredPortfolio.assignAll(
      portfolio.where(
        (e) => (e['status'] ?? '').toString().toLowerCase() == 'draft',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete Service
  // ---------------------------------------------------------------------------

  Future<void> deleteService(
    String documentId, {
    VoidCallback? onDeleted,
  }) async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      await _firestore.collection('services').doc(documentId).delete();

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Deleted',
        'Service deleted successfully.',
      );

      onDeleted?.call();
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Delete Failed',
        e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Confirm Delete
  // ---------------------------------------------------------------------------

  void confirmDelete(
    String documentId, {
    VoidCallback? onDeleted,
  }) {
    Get.defaultDialog(
      title: 'Delete Service',
      middleText: 'Are you sure you want to delete this service?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Get.theme.colorScheme.onError,
      buttonColor: Get.theme.colorScheme.error,
      onConfirm: () async {
        Get.back();

        await deleteService(documentId, onDeleted: onDeleted);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void openPortfolio(
    Map<String, dynamic> service,
  ) {
    Get.toNamed(
      '/artistPortfolioDetails',
      arguments: service,
    );
  }

  void editService(
    Map<String, dynamic> service,
  ) {

    Get.to(() => const CreateServiceScreen(), arguments: service);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  int get publishedCount => publishedDesigns.value;

  int get draftCount => draftDesigns.value;

  int get totalCount => totalDesigns.value;
  bool hasGallery(
    Map<String, dynamic> service,
  ) {
    final images = service['galleryImageUrls'];

    if (images == null) {
      return false;
    }

    if (images is List) {
      return images.isNotEmpty;
    }

    return false;
  }

  int galleryCount(
    Map<String, dynamic> service,
  ) {
    final images = service['galleryImageUrls'];

    if (images is List) {
      return images.length;
    }

    return 0;
  }

  String coverImage(
    Map<String, dynamic> service,
  ) {
    return service['coverImageUrl'] ?? '';
  }

  String serviceName(
    Map<String, dynamic> service,
  ) {
    return service['serviceName'] ?? '';
  }

  String category(
    Map<String, dynamic> service,
  ) {
    return service['categoryName'] ?? '';
  }

  double price(
    Map<String, dynamic> service,
  ) {
    final value = service['startingPrice'] ?? 0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    return 0;
  }

  double rating(
    Map<String, dynamic> service,
  ) {
    final value = service['rating'] ?? 0;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    return 0;
  }

  int orders(
    Map<String, dynamic> service,
  ) {
    return service['ordersCount'] ?? 0;
  }

  String status(
    Map<String, dynamic> service,
  ) {
    return service['status'] ?? '';
  }

  bool isPublished(
    Map<String, dynamic> service,
  ) {
    return status(service).toLowerCase() == 'published';
  }

  bool isDraft(
    Map<String, dynamic> service,
  ) {
    return status(service).toLowerCase() == 'draft';
  }

  List<String> galleryImages(
    Map<String, dynamic> service,
  ) {
    final images = service['galleryImageUrls'];

    if (images is List) {
      return images.map((e) => e.toString()).toList();
    }

    return [];
  }

  String shortDescription(
    Map<String, dynamic> service,
  ) {
    return service['shortDescription'] ?? '';
  }

  int deliveryDays(
    Map<String, dynamic> service,
  ) {
    return service['deliveryDays'] ?? 0;
  }

  bool urgentDelivery(
    Map<String, dynamic> service,
  ) {
    return service['urgentDelivery'] ?? false;
  }

  bool homePickup(
    Map<String, dynamic> service,
  ) {
    return service['homePickupAvailable'] ?? false;
  }

  List<String> tags(
    Map<String, dynamic> service,
  ) {
    final data = service['generalTags'];

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }

    return [];
  }
}