import 'dart:async';
import 'package:get/get.dart';
import 'package:smartstitch/services/firebase_service.dart';

class AdminSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'user' | 'order' | 'service'

  AdminSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
  });
}

class AdminSearchController extends GetxController {
  static AdminSearchController get to => Get.find();

  final FirebaseService _firebaseService = FirebaseService();

  final RxString query = ''.obs;
  final RxBool isSearching = false.obs;

  final RxList<AdminSearchResult> userResults = <AdminSearchResult>[].obs;
  final RxList<AdminSearchResult> orderResults = <AdminSearchResult>[].obs;
  final RxList<AdminSearchResult> serviceResults = <AdminSearchResult>[].obs;

  Timer? _debounce;

  //────────────────────────────────────────────────────────────
  // Called on every keystroke; actual search is debounced so we
  // don't hit Firestore on every character.
  //────────────────────────────────────────────────────────────

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      clearResults();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value.trim());
    });
  }

  void clearResults() {
    userResults.clear();
    orderResults.clear();
    serviceResults.clear();
    isSearching.value = false;
  }

  Future<void> _runSearch(String term) async {
    try {
      isSearching.value = true;
      final lower = term.toLowerCase();

      // Users first — bookings need the matched user IDs to let a search
      // by customer name surface the right bookings too.
      final usersSnap = await _firebaseService.firestore
          .collection('users')
          .limit(200)
          .get();

      final matchingUsers = usersSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();
        final phone = (data['phone'] as String? ?? '').toLowerCase();
        return name.contains(lower) ||
            email.contains(lower) ||
            phone.contains(lower);
      }).toList();

      final matchingUserIds = matchingUsers.map((d) => d.id).toSet();

      userResults.value = matchingUsers.take(8).map((doc) {
        final data = doc.data();
        return AdminSearchResult(
          id: doc.id,
          title: (data['name'] as String?) ?? 'Unnamed user',
          subtitle:
              '${data['role'] ?? ''}${(data['email'] as String?)?.isNotEmpty == true ? ' • ${data['email']}' : ''}',
          category: 'user',
        );
      }).toList();

      // Bookings — matches on serviceTitle/status/booking id directly,
      // or via the matched customer IDs found above.
      final bookingsSnap = await _firebaseService.firestore
          .collection('bookings')
          .limit(200)
          .get();

      orderResults.value = bookingsSnap.docs.where((doc) {
        final data = doc.data();
        final serviceTitle =
            (data['serviceTitle'] as String? ?? '').toLowerCase();
        final status = (data['status'] as String? ?? '').toLowerCase();
        final customerId = data['customerId'] as String? ?? '';
        return serviceTitle.contains(lower) ||
            status.contains(lower) ||
            doc.id.toLowerCase().contains(lower) ||
            matchingUserIds.contains(customerId);
      }).take(8).map((doc) {
        final data = doc.data();
        return AdminSearchResult(
          id: doc.id,
          title: (data['serviceTitle'] as String?) ?? 'Booking ${doc.id}',
          subtitle:
              '${data['status'] ?? ''}${data['totalAmount'] != null ? ' • Rs. ${data['totalAmount']}' : ''}',
          category: 'order',
        );
      }).toList();

      // Services — two collections cover this: `services` (individual
      // priced catalog items, e.g. "Abaya Stitching") and `categories`
      // (broad groupings, e.g. "Alteration Services"). Both feed the
      // same "Services" result section.
      final servicesSnap = await _firebaseService.firestore
          .collection('services')
          .limit(200)
          .get();

      final serviceMatches = servicesSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final categoryName =
            (data['categoryName'] as String? ?? '').toLowerCase();
        final description =
            (data['description'] as String? ?? '').toLowerCase();
        return name.contains(lower) ||
            categoryName.contains(lower) ||
            description.contains(lower);
      }).map((doc) {
        final data = doc.data();
        return AdminSearchResult(
          id: doc.id,
          title: (data['name'] as String?) ?? 'Unnamed service',
          subtitle:
              '${data['categoryName'] ?? ''}${data['price'] != null ? ' • Rs. ${data['price']}' : ''}',
          category: 'service',
        );
      }).toList();

      final categoriesSnap = await _firebaseService.firestore
          .collection('categories')
          .limit(200)
          .get();

      final categoryMatches = categoriesSnap.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        return name.contains(lower);
      }).map((doc) {
        final data = doc.data();
        return AdminSearchResult(
          id: doc.id,
          title: (data['name'] as String?) ?? 'Unnamed category',
          subtitle: 'Category',
          category: 'service',
        );
      }).toList();

      serviceResults.value =
          [...serviceMatches, ...categoryMatches].take(8).toList();
    } catch (_) {
      // Search is a convenience feature — fail quietly rather than
      // throwing a toast on every keystroke.
      userResults.clear();
      orderResults.clear();
      serviceResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}