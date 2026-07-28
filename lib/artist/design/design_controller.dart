import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartstitch/artist/artist_main_screen.dart';

/// ─── Dynamic Field Type ──────────────────────────────────────
enum ServiceFieldType { chipSingle, chipMulti }

/// ─── Dynamic Field Definition ────────────────────────────────
class ServiceFieldConfig {
  final String key;
  final String label;
  final ServiceFieldType type;
  final List<String> options;

  const ServiceFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    required this.options,
  });
}

/// ─── SERVICE CONTROLLER (GetX) ───────────────────────────────
class ServiceController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get artistId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Step Management ────────────────────────────────────────
  // 🆕 REORDERED to match the screen: 0=Basic,1=Details,2=Pricing,3=Images,4=Publish
  final currentStep = 0.obs;
  static const int totalSteps = 5;

  // ─── Category (Locked, fetched from artist profile) ─────────
  final artistCategory = ''.obs;
  final isCategoryLoading = false.obs;
  final isEditing = false.obs;
  String? editingServiceId;
  String controllerTag = '';
  final RxList<Map<String, dynamic>> availableServices =
      <Map<String, dynamic>>[].obs;
  final isServicesLoading = false.obs;
  final Rx<Map<String, dynamic>?> selectedService =
      Rx<Map<String, dynamic>?>(null);

  // ─── Images ──────────────────────────────────────────────────
  final Rx<XFile?> coverImage = Rx<XFile?>(null);
  final RxList<XFile> galleryImages = <XFile>[].obs;
  // Existing (already-uploaded) images when editing a service — shown
  // in the UI until the artist replaces/removes them.
  final existingCoverImageUrl = ''.obs;
  final RxList<String> existingGalleryImageUrls = <String>[].obs;
  final _picker = ImagePicker();

  // ─── Basic Info ──────────────────────────────────────────────
  final serviceNameController = TextEditingController();
  final shortDescController = TextEditingController();
  final longDescController = TextEditingController();

  // ─── Dynamic Category Fields ─────────────────────────────────
  final RxMap<String, dynamic> categoryFields = <String, dynamic>{}.obs;

  // ─── Pricing ─────────────────────────────────────────────────
  final startingPriceController = TextEditingController();
  final deliveryDaysController = TextEditingController();
  final revisionCountController = TextEditingController(text: '2');
  final urgentDelivery = false.obs;
  final homePickupAvailable = false.obs;

  // ─── Publishing / Draft States ───────────────────────────────
  final isPublishing = false.obs;
  final isSavingDraft = false.obs;

  static const _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/dc58vppqz/image/upload';
  static const _uploadPreset = 'smartstitch_profile';

  // ─── Category → Dynamic Field Definitions ────────────────────
  // Add more categories here freely — the UI auto-generates from this map.
  static const Map<String, List<ServiceFieldConfig>> categoryFieldConfigs = {
    "Women's Stitching": [
      ServiceFieldConfig(
          key: 'dressType',
          label: 'Dress Type',
          type: ServiceFieldType.chipSingle,
          options: ['Maxi', 'Kurti', 'Abaya', 'Bridal', 'Kids']),
      ServiceFieldConfig(
          key: 'neckStyles',
          label: 'Neck Styles',
          type: ServiceFieldType.chipMulti,
          options: ['Round', 'V-Neck', 'Boat', 'Collar', 'Halter']),
      ServiceFieldConfig(
          key: 'sleeves',
          label: 'Sleeves',
          type: ServiceFieldType.chipMulti,
          options: ['Full', 'Half', 'Sleeveless', 'Bell', 'Puff']),
      ServiceFieldConfig(
          key: 'fabricSuggestions',
          label: 'Fabric Suggestions',
          type: ServiceFieldType.chipMulti,
          options: ['Lawn', 'Cotton', 'Silk', 'Chiffon', 'Velvet']),
      ServiceFieldConfig(
          key: 'availableSizes',
          label: 'Available Sizes',
          type: ServiceFieldType.chipMulti,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Custom']),
    ],
    'Embroidery': [
      ServiceFieldConfig(
          key: 'embroideryType',
          label: 'Embroidery Type',
          type: ServiceFieldType.chipMulti,
          options: ['Hand', 'Machine', 'Mirror', 'Thread']),
      ServiceFieldConfig(
          key: 'availableSizes',
          label: 'Available Sizes',
          type: ServiceFieldType.chipMulti,
          options: ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Custom']),
    ],
    'Crochet': [
      ServiceFieldConfig(
          key: 'productType',
          label: 'Product Type',
          type: ServiceFieldType.chipSingle,
          options: ['Scarf', 'Bag', 'Dress', 'Baby Wear', 'Home Decor']),
      ServiceFieldConfig(
          key: 'yarnType',
          label: 'Yarn Type',
          type: ServiceFieldType.chipSingle,
          options: ['Cotton', 'Wool', 'Acrylic', 'Silk']),
      ServiceFieldConfig(
          key: 'hookSize',
          label: 'Hook Size',
          type: ServiceFieldType.chipSingle,
          options: ['2mm', '3mm', '4mm', '5mm', '6mm+']),
    ],
    'Tailoring': [
      ServiceFieldConfig(
          key: 'garmentType',
          label: 'Garment Type',
          type: ServiceFieldType.chipMulti,
          options: ['Shirt', 'Pant', 'Suit', 'Blazer', 'Alteration']),
      ServiceFieldConfig(
          key: 'fitType',
          label: 'Fit Type',
          type: ServiceFieldType.chipSingle,
          options: ['Slim', 'Regular', 'Loose']),
    ],
  };

  /// Fields shown in the Details step, based on the artist's locked
  /// category. Falls back to generic tags if the category has no
  /// specific config.
  List<ServiceFieldConfig> get currentCategoryFields =>
      categoryFieldConfigs[artistCategory.value] ??
      const [
        ServiceFieldConfig(
            key: 'generalTags',
            label: 'Service Tags',
            type: ServiceFieldType.chipMulti,
            options: [
              'Custom Fit',
              'Premium Finish',
              'Fast Delivery',
              'Alteration Included'
            ]),
      ];

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchArtistCategory();
    await fetchServicesForCategory();
  }

  // ─── Fetch Artist's Locked Category ──────────────────────────
  Future<void> fetchArtistCategory() async {
    if (artistId.isEmpty) return;
    try {
      isCategoryLoading.value = true;
      final doc = await _db.collection('artists').doc(artistId).get().timeout(
            const Duration(seconds: 12),
          ); // FIX: same timeout safety net as fetchServicesForCategory
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final specializations = data['specializations'] as List?;
        artistCategory.value =
            (specializations != null && specializations.isNotEmpty)
                ? specializations[0].toString()
                : "Women's Stitching";
      } else {
        artistCategory.value = "Women's Stitching";
      }
    } catch (e) {
      debugPrint('fetchArtistCategory failed: $e');
      _warn('Could not load your category — showing default.');
      artistCategory.value = "Women's Stitching";
    } finally {
      isCategoryLoading.value = false;
    }
  }

  // ─── Fetch Predefined Services For The Locked Category ────────
  Future<void> fetchServicesForCategory() async {
    if (artistCategory.value.isEmpty) return;
    try {
      isServicesLoading.value = true;
      final snap = await _db
          .collection('services')
          .where('categoryName', isEqualTo: artistCategory.value)
          .where('type', isEqualTo: 'template')
          .get()
          .timeout(const Duration(seconds: 12));
      availableServices.value =
          snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    } catch (e) {
      debugPrint('fetchServicesForCategory failed: $e');
      _warn('Could not load services. Pull to refresh or reopen this screen.');
    } finally {
      isServicesLoading.value = false;
    }
  }

  void selectService(Map<String, dynamic> service) {
    selectedService.value = service;
    serviceNameController.text = service['name'] ?? '';
    shortDescController.text = service['description'] ?? '';
    startingPriceController.text = (service['price'] ?? '').toString();
  }

  // ─── Load Existing Service For Editing ───────────────────────
  Future<void> loadServiceForEdit(String serviceId) async {
    try {
      final doc = await _db.collection('services').doc(serviceId).get();

      if (!doc.exists) {
        _warn('Service not found');
        return;
      }

      final data = doc.data()!;

      editingServiceId = serviceId;
      isEditing.value = true;

      serviceNameController.text = data['serviceName'] ?? '';
      shortDescController.text = data['shortDescription'] ?? '';
      longDescController.text = data['longDescription'] ?? '';

      startingPriceController.text = (data['startingPrice'] ?? '').toString();

      deliveryDaysController.text = (data['deliveryDays'] ?? '').toString();

      revisionCountController.text = (data['revisionCount'] ?? '2').toString();

      urgentDelivery.value = data['urgentDelivery'] ?? false;
      homePickupAvailable.value = data['homePickupAvailable'] ?? false;

      categoryFields.assignAll(
        Map<String, dynamic>.from(
          data['categoryFields'] ?? {},
        ),
      );

      // Existing images — shown in the Images step until replaced/removed.
      existingCoverImageUrl.value = data['coverImageUrl'] ?? '';
      existingGalleryImageUrls.assignAll(
        List<String>.from(data['galleryImageUrls'] ?? []),
      );
      coverImage.value = null;
      galleryImages.clear();

      currentStep.value = 0;
    } catch (e) {
      _warn('Failed to load service');
    }
  }

  // ─── Step Navigation ──────────────────────────────────────────
  void nextStep() {
    if (!validateStep(currentStep.value)) return;
    if (currentStep.value < totalSteps - 1) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void goToStep(int step) {
    if (step <= currentStep.value) currentStep.value = step;
  }

  // 🆕 REMAPPED to the new step order: 0=Basic,1=Details,2=Pricing,3=Images,4=Publish
  bool validateStep(int step) {
    switch (step) {
      case 0: // Basic Info
        // Template selection only applies when creating a brand-new
        // service — an existing service being edited already has its
        // own name/description/price filled in.
        if (!isEditing.value && selectedService.value == null) {
          _warn('Please select a service from the list');
          return false;
        }
        return true;
      case 1: // Details
        return true;
      case 2: // Pricing
        final price = double.tryParse(startingPriceController.text.trim());
        if (price == null || price <= 0) {
          _warn('Enter a valid starting price');
          return false;
        }
        final days = int.tryParse(deliveryDaysController.text.trim());
        if (days == null || days <= 0) {
          _warn('Enter valid delivery days');
          return false;
        }
        return true;
      case 3: // Images
        final hasCover = coverImage.value != null ||
            (isEditing.value && existingCoverImageUrl.value.isNotEmpty);
        if (!hasCover) {
          _warn('Please add a cover image for your service');
          return false;
        }
        final totalGalleryCount = galleryImages.length +
            (isEditing.value ? existingGalleryImageUrls.length : 0);
        if (totalGalleryCount < 2) {
          _warn('Please add at least 3 images in total (cover + 2 gallery)');
          return false;
        }
        return true;
      default: // Publish
        return true;
    }
  }

  // ─── Image Handling ────────────────────────────────────────────
  Future<void> pickCoverImage() async {
    final img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      coverImage.value = img;
      // A freshly picked cover replaces the existing one on save.
      existingCoverImageUrl.value = '';
    }
  }

  Future<void> pickGalleryImages() async {
    final remaining =
        8 - galleryImages.length - existingGalleryImageUrls.length;
    if (remaining <= 0) {
      _warn('Maximum 8 gallery images allowed');
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      galleryImages.addAll(picked.take(remaining));
    }
  }

  void removeGalleryImage(int index) => galleryImages.removeAt(index);

  void removeExistingGalleryImage(int index) =>
      existingGalleryImageUrls.removeAt(index);

  void reorderGalleryImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = galleryImages.removeAt(oldIndex);
    galleryImages.insert(newIndex, item);
  }

  // ─── Dynamic Category Field Handling ────────────────────────────
  void setSingleField(String key, String value) {
    categoryFields[key] = value;
  }

  void toggleMultiField(String key, String value) {
    final current = List<String>.from(categoryFields[key] ?? <String>[]);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    categoryFields[key] = current;
  }

  bool isMultiSelected(String key, String value) {
    final current = List<String>.from(categoryFields[key] ?? <String>[]);
    return current.contains(value);
  }

  // ─── Cloudinary Upload Engine ─────────────────────────────────
  Future<String> _uploadSingleImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUrl))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: file.name));
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonData = jsonDecode(responseData);
    final url = jsonData['secure_url'];
    if (url == null) throw Exception('Image upload failed');
    return url as String;
  }

  Future<Map<String, dynamic>> _uploadAllImages() async {
    final coverUrl = await _uploadSingleImage(coverImage.value!);
    final List<String> galleryUrls = [];
    for (final img in galleryImages) {
      galleryUrls.add(await _uploadSingleImage(img));
    }
    return {'coverImageUrl': coverUrl, 'galleryImageUrls': galleryUrls};
  }

  // ─── Publish Service ────────────────────────────────────────────
  Future<void> publishService() async {
    for (int i = 0; i < totalSteps - 1; i++) {
      if (!validateStep(i)) {
        currentStep.value = i;
        return;
      }
    }
    try {
      isPublishing.value = true;
      final images = await _uploadAllImages();
      await _db.collection('services').add({
        'artistId': artistId,
        'category': artistCategory.value,
        'predefinedServiceId': selectedService.value?['id'],
        'categoryId': selectedService.value?['categoryId'],
        'serviceName': serviceNameController.text.trim(),
        'shortDescription': shortDescController.text.trim(),
        'longDescription': longDescController.text.trim(),
        'categoryFields': categoryFields,
        'startingPrice': double.parse(startingPriceController.text.trim()),
        'deliveryDays': int.parse(deliveryDaysController.text.trim()),
        'revisionCount': int.tryParse(revisionCountController.text.trim()) ?? 2,
        'urgentDelivery': urgentDelivery.value,
        'homePickupAvailable': homePickupAvailable.value,
        'coverImageUrl': images['coverImageUrl'],
        'galleryImageUrls': images['galleryImageUrls'],
        'status': 'published',
        'rating': 0.0,
        'ordersCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'artist',
      });

      // 🆕 Skip the success screen — go straight to the Portfolio tab
      // (index 1) so the artist immediately sees their new service.
      Get.snackbar(
        'Published',
        'Your service is now live',
        backgroundColor: const Color(0xFF22C55E),
        colorText: Colors.white,
      );
      Get.offAll(() => const ArtistMainScreen(initialIndex: 1));

    } catch (e) {
      _warn('Failed to publish: $e');
    } finally {
      isPublishing.value = false;
    }
  }

// ─── Update Existing Service ───────────────────────────────
  Future<void> updateService() async {
    if (editingServiceId == null) return;

    try {
      isPublishing.value = true;

      // Cover: use a freshly picked one if present, else keep whatever
      // is still marked as the existing cover.
      String coverUrl = existingCoverImageUrl.value;
      List<String> galleryUrls = List<String>.from(existingGalleryImageUrls);

      if (coverImage.value != null) {
        coverUrl = await _uploadSingleImage(coverImage.value!);
      }

      if (galleryImages.isNotEmpty) {
        for (final img in galleryImages) {
          galleryUrls.add(await _uploadSingleImage(img));
        }
      }

      await _db.collection('services').doc(editingServiceId).update({
        'serviceName': serviceNameController.text.trim(),
        'shortDescription': shortDescController.text.trim(),
        'longDescription': longDescController.text.trim(),
        'categoryFields': categoryFields,
        'startingPrice': double.parse(startingPriceController.text),
        'deliveryDays': int.parse(deliveryDaysController.text),
        'revisionCount': int.parse(revisionCountController.text),
        'urgentDelivery': urgentDelivery.value,
        'homePickupAvailable': homePickupAvailable.value,
        'coverImageUrl': coverUrl,
        'galleryImageUrls': galleryUrls,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      Get.back();

      Get.snackbar(
        'Updated',
        'Service updated successfully',
        backgroundColor: const Color(0xFF22C55E),
        colorText: Colors.white,
      );

      isEditing.value = false;
      editingServiceId = null;
    } catch (e) {
      _warn('Failed to update service');
    } finally {
      isPublishing.value = false;
    }
  }

  // ─── Save As Draft ──────────────────────────────────────────────
  Future<void> saveDraft() async {
    if (serviceNameController.text.trim().isEmpty) {
      _warn('Add a service name before saving as draft');
      return;
    }
    try {
      isSavingDraft.value = true;
      String coverUrl = '';
      List<String> galleryUrls = [];
      if (coverImage.value != null) {
        final images = await _uploadAllImages();
        coverUrl = images['coverImageUrl'];
        galleryUrls = List<String>.from(images['galleryImageUrls']);
      }
      await _db.collection('services').add({
        'artistId': artistId,
        'category': artistCategory.value,
        'predefinedServiceId': selectedService.value?['id'],
        'categoryId': selectedService.value?['categoryId'],
        'serviceName': serviceNameController.text.trim(),
        'shortDescription': shortDescController.text.trim(),
        'longDescription': longDescController.text.trim(),
        'categoryFields': categoryFields,
        'startingPrice':
            double.tryParse(startingPriceController.text.trim()) ?? 0,
        'deliveryDays': int.tryParse(deliveryDaysController.text.trim()) ?? 0,
        'revisionCount': int.tryParse(revisionCountController.text.trim()) ?? 2,
        'urgentDelivery': urgentDelivery.value,
        'homePickupAvailable': homePickupAvailable.value,
        'coverImageUrl': coverUrl,
        'galleryImageUrls': galleryUrls,
        'status': 'draft',
        'rating': 0.0,
        'ordersCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'artist',
      });
      Get.back();
      Get.snackbar('Saved', 'Service saved as draft',
          backgroundColor: const Color(0xFF0E8F95),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      _warn('Failed to save draft: $e');
    } finally {
      isSavingDraft.value = false;
    }
  }

  void _warn(String msg) {
    Get.snackbar('Check Again', msg,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP);
  }

  @override
  void onClose() {
    serviceNameController.dispose();
    shortDescController.dispose();
    longDescController.dispose();
    startingPriceController.dispose();
    deliveryDaysController.dispose();
    revisionCountController.dispose();
    super.onClose();
  }
  // ─── Reset Controller For New Service ────────────────────────
  void resetForNewService() {
    coverImage.value = null;
    galleryImages.clear();
    existingCoverImageUrl.value = '';
    existingGalleryImageUrls.clear();
    serviceNameController.clear();
    shortDescController.clear();
    longDescController.clear();
    categoryFields.clear();
    startingPriceController.clear();
    deliveryDaysController.clear();
    revisionCountController.text = '2';
    urgentDelivery.value = false;
    homePickupAvailable.value = false;
    selectedService.value = null;
    isEditing.value = false;
    editingServiceId = null;
    currentStep.value = 0;
  }
}