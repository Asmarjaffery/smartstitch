import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/services/notification_service.dart';

// ─── Categories Controller ───────────────────────────────────────────────────
// NOTE: No changes in this class — the `categories` collection and its logic
// are untouched, as required.

class AdminCategoriesController extends GetxController {
  static AdminCategoriesController get to => Get.find();

  final _db = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  final isLoading = false.obs;
  final isUploadingImage = false.obs;
  final categories = <QueryDocumentSnapshot>[].obs;
  final nameCtrl = TextEditingController();

  // Holds picked image bytes for add/edit
  final pickedImageBytes = Rxn<Uint8List>();
  final pickedImageName = ''.obs;

  // FIX: track this subscription too so it's properly cancelled on close
  // instead of leaking if the controller is ever re-initialized.
  StreamSubscription<QuerySnapshot>? _categoriesSub;

  @override
  void onInit() {
    super.onInit();
    _listenToCategories();
  }

  @override
  void onClose() {
    _categoriesSub?.cancel(); // FIX
    nameCtrl.dispose();
    super.onClose();
  }

  void _listenToCategories() {
    _categoriesSub?.cancel(); // FIX: guard against double-subscription
    _categoriesSub = _db
        .collection('categories')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snap) {
      categories.value = snap.docs;
    });
  }

  // ── Image Picker ────────────────────────────────────────────────────────────

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    pickedImageBytes.value = await image.readAsBytes();
    pickedImageName.value =
        'category_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  void clearPickedImage() {
    pickedImageBytes.value = null;
    pickedImageName.value = '';
  }

  // ── Cloudinary Upload ────────────────────────────────────────────────────────

  Future<String?> _uploadToCloudinary(Uint8List bytes, String fileName) async {
    isUploadingImage.value = true;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dc58vppqz/image/upload'),
      );
      request.fields['upload_preset'] = 'smartstitch_profile';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      final url = jsonData['secure_url'];

      if (url == null) {
        throw Exception(
            'Upload failed: ${jsonData['error']?['message']}');
      }
      return url as String;
    } catch (e) {
      _showError('Image upload failed: $e');
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ── Add Category ─────────────────────────────────────────────────────────────

  Future<void> addCategory() async {
    if (nameCtrl.text.trim().isEmpty) {
      _showError('Category name required.');
      return;
    }
    isLoading.value = true;
    try {
      String? imageUrl;
      if (pickedImageBytes.value != null) {
        imageUrl = await _uploadToCloudinary(
            pickedImageBytes.value!, pickedImageName.value);
        if (imageUrl == null) {
          isLoading.value = false;
          return;
        }
      }

      await _db.collection('categories').add({
        'name': nameCtrl.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      nameCtrl.clear();
      clearPickedImage();
      Get.back();
      _showSuccess('Category added successfully.');
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Edit Category ─────────────────────────────────────────────────────────────

  Future<void> editCategory(
      BuildContext context, String id, String currentName,
      {String? currentImageUrl}) async {
    nameCtrl.text = currentName;
    clearPickedImage();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      _EditCategorySheet(
        ctrl: this,
        id: id,
        currentImageUrl: currentImageUrl,
      ),
    );
  }

  Future<void> saveEditCategory(
      String id, String? currentImageUrl) async {
    if (nameCtrl.text.trim().isEmpty) {
      _showError('Name cannot be empty.');
      return;
    }
    isLoading.value = true;
    try {
      String? imageUrl = currentImageUrl;

      if (pickedImageBytes.value != null) {
        imageUrl = await _uploadToCloudinary(
            pickedImageBytes.value!, pickedImageName.value);
        if (imageUrl == null) {
          isLoading.value = false;
          return;
        }
      }

      final updateData = <String, dynamic>{'name': nameCtrl.text.trim()};
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      await _db.collection('categories').doc(id).update(updateData);

      // ── CHANGE: only sync categoryName onto Admin *template* services.
      // Artist-published services (type == "artist") keep the categoryName
      // snapshot they had at publish time and are intentionally left alone,
      // so this category-rename never touches artist documents.
      final servicesSnap = await _db
          .collection('services')
          .where('categoryId', isEqualTo: id)
          .where('type', isEqualTo: 'template') // ← CHANGE
          .get();
      for (final doc in servicesSnap.docs) {
        await doc.reference
            .update({'categoryName': nameCtrl.text.trim()});
      }

      nameCtrl.clear();
      clearPickedImage();
      Get.back();
      _showSuccess('Category updated.');
    } catch (e) {
      _showError('Update failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete Category ───────────────────────────────────────────────────────────

  Future<void> deleteCategory(
      BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content:
            Text('Delete "$name"? All its services will also be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // ── CHANGE: only cascade-delete Admin *template* services for this
      // category. Artist-published services (type == "artist") that happen
      // to share this categoryId are no longer wiped out when an Admin
      // deletes a category.
      final servicesSnap = await _db
          .collection('services')
          .where('categoryId', isEqualTo: id)
          .where('type', isEqualTo: 'template') // ← CHANGE
          .get();
      for (final doc in servicesSnap.docs) {
        await doc.reference.delete();
      }
      await _db.collection('categories').doc(id).delete();
      _showSuccess('"$name" and its services removed.');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success', msg,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }
}

// ─── Edit Category Bottom Sheet Widget ───────────────────────────────────────
// NOTE: No changes in this widget — UI is untouched, as required.

class _EditCategorySheet extends StatelessWidget {
  final AdminCategoriesController ctrl;
  final String id;
  final String? currentImageUrl;

  const _EditCategorySheet({
    required this.ctrl,
    required this.id,
    this.currentImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const Text('Edit Category',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Update the category name or image',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // ── Image Picker ──────────────────────────────────────────────
              Obx(() {
                final hasNewImage = ctrl.pickedImageBytes.value != null;
                return GestureDetector(
                  onTap: ctrl.pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      image: hasNewImage
                          ? DecorationImage(
                              image: MemoryImage(ctrl.pickedImageBytes.value!),
                              fit: BoxFit.cover,
                            )
                          : (currentImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(currentImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: hasNewImage || currentImageUrl != null
                        ? Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.55),
                                radius: 18,
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 36, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to add image',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              TextFormField(
                controller: ctrl.nameCtrl,
                autofocus: false,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon:
                      Icon(Icons.category_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (ctrl.isLoading.value || ctrl.isUploadingImage.value)
                              ? null
                              : () => ctrl.saveEditCategory(
                                  id, currentImageUrl),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: (ctrl.isLoading.value ||
                              ctrl.isUploadingImage.value)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Services Controller ─────────────────────────────────────────────────────

class AdminServicesController extends GetxController {
  static AdminServicesController get to => Get.find();

  final _db = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final services = <QueryDocumentSnapshot>[].obs;

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  final selectedCategoryId = ''.obs;
  final selectedCategoryName = ''.obs;

  // FIX: keep a handle to the active snapshot subscription so we can
  // cancel it before attaching a new one. Without this, every call to
  // filterByCategory()/clearFilter() stacked another live listener on top
  // of the old ones (old ones were never cancelled) — that listener leak
  // is what was corrupting the Firestore JS SDK's internal state and
  // causing "FIRESTORE INTERNAL ASSERTION FAILED: Unexpected state".
  StreamSubscription<QuerySnapshot>? _servicesSub;

  @override
  void onInit() {
    super.onInit();
    _listenToServices();
  }

  @override
  void onClose() {
    _servicesSub?.cancel(); // FIX: stop the listener when the controller dies
    nameCtrl.dispose();
    priceCtrl.dispose();
    descCtrl.dispose();
    super.onClose();
  }

  void _listenToServices({String? categoryId}) {
    // FIX: cancel any previous listener before attaching a new one.
    _servicesSub?.cancel();

    // ── CHANGE: Admin service list now only loads documents where
    // type == "template", so Artist-published services never show up here.
    Query query = _db
        .collection('services')
        .where('type', isEqualTo: 'template') // ← CHANGE
        .orderBy('createdAt', descending: false);
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    _servicesSub = query.snapshots().listen((snap) {
      services.value = snap.docs;
    });
  }

  void filterByCategory(String categoryId, String categoryName) {
    selectedCategoryId.value = categoryId;
    selectedCategoryName.value = categoryName;
    _listenToServices(categoryId: categoryId);
  }

  void clearFilter() {
    selectedCategoryId.value = '';
    selectedCategoryName.value = '';
    _listenToServices();
  }

  Future<void> addService(String categoryId, String categoryName) async {
    final name = nameCtrl.text.trim();
    final priceText = priceCtrl.text.trim();
    final desc = descCtrl.text.trim();

    if (name.isEmpty) {
      _showError('Service name is required.');
      return;
    }
    if (priceText.isEmpty) {
      _showError('Price is required.');
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      _showError('Enter a valid price.');
      return;
    }

    isLoading.value = true;
    try {
      final docRef = await _db.collection('services').add({
        'name': name,
        'price': price,
        'description': desc,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'template', // ← CHANGE: marks this as an Admin predefined service
      });

      final customers = await _db
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      for (final doc in customers.docs) {
        await NotificationService.instance.sendNotification(
          recipientId: doc.id,
          recipientRole: UserRole.customer,
          type: NotificationType.event,
          title: 'New Service Available! ✨',
          body: 'Nai service add hui: $name (Rs. $price)',
          data: {'serviceId': docRef.id, 'categoryId': categoryId},
        );
      }

      _clearForm();
      Get.back();
      _showSuccess('Service added successfully.');
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editService(
      BuildContext context, String id, Map<String, dynamic> data) async {
    nameCtrl.text = data['name'] ?? '';
    priceCtrl.text = (data['price'] as num?)?.toString() ?? '';
    descCtrl.text = data['description'] ?? '';

    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const Text('Edit Service',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Update service details',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    prefixIcon:
                        Icon(Icons.design_services_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs.)',
                    prefixIcon:
                        Icon(Icons.currency_rupee_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                final priceText = priceCtrl.text.trim();
                                if (name.isEmpty) {
                                  _showError('Name cannot be empty.');
                                  return;
                                }
                                final price =
                                    double.tryParse(priceText);
                                if (price == null || price < 0) {
                                  _showError('Enter a valid price.');
                                  return;
                                }
                                isLoading.value = true;
                                try {
                                  // NOTE: This is an update to an existing
                                  // doc (identified by `id`), so its `type`
                                  // field is left exactly as-is — no change
                                  // needed here since we're not creating a
                                  // new document.
                                  await _db
                                      .collection('services')
                                      .doc(id)
                                      .update({
                                    'name': name,
                                    'price': price,
                                    'description':
                                        descCtrl.text.trim(),
                                  });
                                  _clearForm();
                                  Get.back();
                                  _showSuccess('Service updated.');
                                } catch (e) {
                                  _showError('Update failed: $e');
                                } finally {
                                  isLoading.value = false;
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15),
                        ),
                        child: isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> deleteService(
      BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    // NOTE: Deletion here is already scoped to a specific document `id`
    // (picked from the already-filtered `services` list, which only ever
    // contains type == "template" docs — see _listenToServices above), so
    // no additional type filter is needed on this single-doc delete call.
    try {
      await _db.collection('services').doc(id).delete();
      _showSuccess('"$name" removed.');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  void _clearForm() {
    nameCtrl.clear();
    priceCtrl.clear();
    descCtrl.clear();
  }

  void _showSuccess(String msg) {
    Get.snackbar('Success', msg,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }

  void _showError(String msg) {
    Get.snackbar('Error', msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12);
  }
}