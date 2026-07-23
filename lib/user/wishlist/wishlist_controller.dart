import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/models/wishlist_model.dart';
import 'package:smartstitch/models/design_model.dart';
import 'package:smartstitch/models/artist_model.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/services/firebase_service.dart';
import 'package:smartstitch/user/notification/notification_user_controller.dart';

class WishlistController extends GetxController {
  static WishlistController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  final Rx<WishlistModel?> wishlist = Rx<WishlistModel?>(null);
  final RxList<DesignModel> favoriteDesigns = <DesignModel>[].obs;
  final RxList<ArtistModel> favoriteArtists = <ArtistModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // ─── Build phase ke baad load karo ───────────────────────
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadWishlist();
    });
  }

  // ─── Load Wishlist ────────────────────────────────────────────────────────
  Future<void> loadWishlist() async {
    try {
      // ─── Agar user logged in nahi toh skip karo ───────────
      if (AuthController.to.currentUserId == null) return;

      isLoading.value = true;
      final uid = AuthController.to.currentUserId!;

      final doc = await _firebaseService.getDocument(
        collection: 'wishlists',
        docId: uid,
      );

      if (!doc.exists) {
        final newWishlist = WishlistModel(
          id: uid,
          userId: uid,
          updatedAt: DateTime.now(),
        );
        await _firebaseService.setDocument(
          collection: 'wishlists',
          docId: uid,
          data: newWishlist.toJson(),
        );
        wishlist.value = newWishlist;
        return;
      }

      wishlist.value = WishlistModel.fromJson(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id});

      await _loadFavoriteDesigns();
      await _loadFavoriteArtists();
    } catch (e) {
      // ─── Post frame mein show karo taake build phase se conflict na ho ───
      SchedulerBinding.instance.addPostFrameCallback((_) {
        AppHelpers.showError('Failed to load wishlist.');
      });
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Load Favorite Designs ────────────────────────────────────────────────
  // ✅ FIXED: Was querying 'portfolio_designs' — but portfolio items actually
  // live in the 'services' collection (same one ArtistDetailScreen reads
  // from). That mismatch meant favorited designs never loaded, even though
  // the ID was correctly saved into the wishlist doc's favoriteDesignIds.
  Future<void> _loadFavoriteDesigns() async {
    final ids = wishlist.value?.favoriteDesignIds ?? [];
    if (ids.isEmpty) {
      favoriteDesigns.clear();
      return;
    }
    try {
      final snapshot = await _firebaseService.firestore
          .collection('services') // ✅ FIXED: Was 'portfolio_designs'
          .where('__name__', whereIn: ids)
          .get();

      favoriteDesigns.value = snapshot.docs.map((doc) {
        final data = doc.data();

        // Build image list the same way PortfolioItem does for 'services' docs.
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
        // Fallback to any pre-existing imageUrls field if present.
        if (gallery.isEmpty && data['imageUrls'] is List) {
          for (final img in data['imageUrls'] as List) {
            if (img is String && img.isNotEmpty) gallery.add(img);
          }
        }
        String createdAtStr;
        final rawCreatedAt = data['createdAt'];
        if (rawCreatedAt is Timestamp) {
          createdAtStr = rawCreatedAt.toDate().toIso8601String();
        } else if (rawCreatedAt is String) {
          createdAtStr = rawCreatedAt;
        } else {
          createdAtStr = DateTime.now().toIso8601String();
        }

        return DesignModel.fromJson({
          ...data,
          'id': doc.id,
          'title': data['title'] ?? data['serviceName'] ?? '',
          // ✅ FIXED: 'services' docs store this as 'shortDescription', not
          // 'description' — DesignModel requires a non-null description.
          'description': data['description'] ?? data['shortDescription'] ?? '',
          'artistId': data['artistId'] ?? '',
          'estimatedPrice': data['estimatedPrice'] ??
              data['startingPrice'] ??
              data['price'] ??
              0,
          'imageUrls': gallery,
          'createdAt': createdAtStr,
        });
      }).toList();
    } catch (e) {
      print('⚠️ _loadFavoriteDesigns error: $e');
    }
  }
  // ─── Load Favorite Artists ────────────────────────────────────────────────
  Future<void> _loadFavoriteArtists() async {
    final ids = wishlist.value?.favoriteArtistIds ?? [];
    if (ids.isEmpty) {
      favoriteArtists.clear();
      return;
    }
    try {
      final snapshot = await _firebaseService.firestore
          .collection('artists')
          .where('__name__', whereIn: ids)
          .get();

      favoriteArtists.value = snapshot.docs
          .map((doc) => ArtistModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (_) {}
  }

  // ─── Toggle Design ────────────────────────────────────────────────────────
  Future<void> toggleDesign(String designId, {String designTitle = ''}) async {
    try {
      final uid = AuthController.to.currentUserId!;
      final current =
          List<String>.from(wishlist.value?.favoriteDesignIds ?? []);

      if (current.contains(designId)) {
        current.remove(designId);
        favoriteDesigns.removeWhere((d) => d.id == designId);
        AppHelpers.showSuccess('Removed from wishlist');

        if (designTitle.isNotEmpty) {
          await NotificationUserController.to.sendWishlistRemovedNotification(
            recipientId: uid,
            itemName: designTitle,
          );
        }
      } else {
        current.add(designId);
        AppHelpers.showSuccess('Added to wishlist!');

        if (designTitle.isNotEmpty) {
          await NotificationUserController.to.sendWishlistNotification(
            recipientId: uid,
            itemName: designTitle,
          );
        }
      }

      await _firebaseService.updateDocument(
        collection: 'wishlists',
        docId: uid,
        data: {
          'favoriteDesignIds': current,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      wishlist.value = WishlistModel(
        id: uid,
        userId: uid,
        favoriteDesignIds: current,
        favoriteArtistIds: wishlist.value?.favoriteArtistIds ?? [],
        updatedAt: DateTime.now(),
      );

      if (current.contains(designId)) {
        await _loadFavoriteDesigns();
      }
    } catch (e) {
      AppHelpers.showError('Failed to update wishlist.');
    }
  }

  // ─── Toggle Artist ────────────────────────────────────────────────────────
  Future<void> toggleArtist(String artistId, {String artistName = ''}) async {
    try {
      final uid = AuthController.to.currentUserId!;
      final current =
          List<String>.from(wishlist.value?.favoriteArtistIds ?? []);

      if (current.contains(artistId)) {
        current.remove(artistId);
        favoriteArtists.removeWhere((a) => a.id == artistId);
        AppHelpers.showSuccess('Removed from wishlist');

        if (artistName.isNotEmpty) {
          await NotificationUserController.to.sendWishlistRemovedNotification(
            recipientId: uid,
            itemName: artistName,
          );
        }
      } else {
        current.add(artistId);
        AppHelpers.showSuccess('Added to wishlist!');

        if (artistName.isNotEmpty) {
          await NotificationUserController.to.sendWishlistNotification(
            recipientId: uid,
            itemName: artistName,
          );
        }
      }

      await _firebaseService.updateDocument(
        collection: 'wishlists',
        docId: uid,
        data: {
          'favoriteArtistIds': current,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      wishlist.value = WishlistModel(
        id: uid,
        userId: uid,
        favoriteDesignIds: wishlist.value?.favoriteDesignIds ?? [],
        favoriteArtistIds: current,
        updatedAt: DateTime.now(),
      );

      if (current.contains(artistId)) {
        await _loadFavoriteArtists();
      }
    } catch (e) {
      AppHelpers.showError('Failed to update wishlist.');
    }
  }

  // ─── Check Helpers ────────────────────────────────────────────────────────
  bool isDesignFavorite(String designId) =>
      wishlist.value?.favoriteDesignIds.contains(designId) ?? false;

  bool isArtistFavorite(String artistId) =>
      wishlist.value?.favoriteArtistIds.contains(artistId) ?? false;
}