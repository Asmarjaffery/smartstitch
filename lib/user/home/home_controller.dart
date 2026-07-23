import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smartstitch/models/artist_model.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/core/utils/helpers.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  // ─── Artists ──────────────────────────────────────────────
  final RxList<ArtistModel> topArtists = <ArtistModel>[].obs;
  final RxBool isLoadingArtists = false.obs;

  // ─── Categories ───────────────────────────────────────────
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxBool isCategoriesLoading = false.obs;

  // ─── On Init ──────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchTopArtists();
    fetchCategories();
  }

  // ─── Fetch Artists ────────────────────────────────────────
Future<void> fetchTopArtists() async {
    try {
      isLoadingArtists.value = true;

      final snapshot = await _firebaseService.firestore
          .collection('artists')
          .where('isAvailable', isEqualTo: true)
          .limit(10)
          .get();

      final artists = snapshot.docs.map((doc) {
        final data = {...doc.data(), 'id': doc.id};
        return ArtistModel.fromJson(data);
      }).toList();

      topArtists.value = artists;
    } catch (e) {
      AppHelpers.showError('Failed to load artists.');
    } finally {
      isLoadingArtists.value = false;
    }
  }

  // ─── Fetch Categories ─────────────────────────────────────
  Future<void> fetchCategories() async {
    try {
      isCategoriesLoading.value = true;

      final snapshot = await _firebaseService.firestore
          .collection('categories')
          .orderBy('createdAt')
          .get();

      print('✅ Categories fetched: ${snapshot.docs.length}');

      categories.value = snapshot.docs.map((doc) {
        final data = doc.data();
        print('📂 Category data: $data');
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'categoryName': data['name'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      AppHelpers.showError('Categories load karne mein masla hua.');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  // ─── Refresh ──────────────────────────────────────────────
  @override
  Future<void> refresh() async {
    await Future.wait([
      fetchTopArtists(),
      fetchCategories(),
    ]);
  }
}
