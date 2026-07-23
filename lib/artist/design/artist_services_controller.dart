import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ArtistServicesController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===============================
  // STATES
  // ===============================

  RxBool isLoading = true.obs;

  RxList<Map<String, dynamic>> allServices = <Map<String, dynamic>>[].obs;

  RxList<Map<String, dynamic>> filteredServices = <Map<String, dynamic>>[].obs;

  RxString selectedFilter = "All".obs;

  RxString searchQuery = "".obs;

  // ===============================
  // STATS
  // ===============================

  RxInt totalServices = 0.obs;

  RxInt publishedServices = 0.obs;

  RxInt draftServices = 0.obs;

  String get artistId => _auth.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();

    listenArtistServices();
  }

  // ===============================
  // REALTIME FIRESTORE LISTENER
  // ===============================

  void listenArtistServices() {
    _firestore
        .collection("services")
        .where(
          "artistId",
          isEqualTo: artistId,
        )
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();

      // latest first

      data.sort((a, b) {
        final aDate = a["createdAt"] ?? "";

        final bDate = b["createdAt"] ?? "";

        return bDate.toString().compareTo(
              aDate.toString(),
            );
      });

      allServices.value = data;

      calculateStats();

      applyFilters();

      isLoading.value = false;
    });
  }

  // ===============================
  // SEARCH + FILTER
  // ===============================

  void updateSearch(String value) {
    searchQuery.value = value;

    applyFilters();
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;

    applyFilters();
  }

  void applyFilters() {
    List<Map<String, dynamic>> result = List.from(allServices);

    // status filter

    if (selectedFilter.value != "All") {
      result = result.where((service) {
        return service["status"].toString().toLowerCase() ==
            selectedFilter.value.toLowerCase();
      }).toList();
    }

    // search

    if (searchQuery.value.isNotEmpty) {
      result = result.where((service) {
        final name = service["serviceName"].toString().toLowerCase();

        final category = service["categoryName"].toString().toLowerCase();

        final query = searchQuery.value.toLowerCase();

        return name.contains(query) || category.contains(query);
      }).toList();
    }

    filteredServices.value = result;
  }

  // ===============================
  // CALCULATE DASHBOARD STATS
  // ===============================

  void calculateStats() {
    totalServices.value = allServices.length;

    publishedServices.value = allServices
        .where(
          (e) => e["status"] == "published",
        )
        .length;

    draftServices.value = allServices
        .where(
          (e) => e["status"] == "draft",
        )
        .length;
  }

  // ===============================
  // DELETE SERVICE
  // ===============================

  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection("services").doc(serviceId).delete();

      Get.snackbar(
        "Deleted",
        "Service removed successfully",
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
      );
    }
  }

  // ===============================
  // PUBLISH / UNPUBLISH
  // ===============================

  Future<void> togglePublish(
    String serviceId,
    String currentStatus,
  ) async {
    final newStatus = currentStatus == "published" ? "draft" : "published";

    await _firestore.collection("services").doc(serviceId).update({
      "status": newStatus,
    });
  }

  // ===============================
  // DUPLICATE SERVICE
  // ===============================

  Future<void> duplicateService(Map<String, dynamic> service) async {
    try {
      final copy = Map<String, dynamic>.from(service);

      copy.remove("id");

      copy["serviceName"] = "${copy["serviceName"]} Copy";

      copy["status"] = "draft";

      copy["createdAt"] = DateTime.now().toIso8601String();

      copy["revisionCount"] = 0;

      await _firestore.collection("services").add(copy);

      Get.snackbar(
        "Copied",
        "Service duplicated as draft",
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
      );
    }
  }
  // ===============================
  // REFRESH
  // ===============================

  Future<void> refreshServices() async {
    listenArtistServices();
  }
}
