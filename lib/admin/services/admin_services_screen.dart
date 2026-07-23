import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/services/admin_service_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

// ─── Categories Screen ───────────────────────────────────────────────────────

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminCategoriesController.to;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showAddSheet(context, ctrl),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.medium),
                textStyle: AppTextStyles.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.category_rounded,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text('No Categories Yet',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.lightTextPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Tap "Add" to create a category',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final doc = ctrl.categories[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final imageUrl = data['imageUrl'] as String?;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: AppRadius.medium,
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: AppShadows.soft(AppColors.primary),
              ),
              child: ListTile(
                onTap: () => Get.to(
                  () => AdminServicesScreen(
                    categoryId: doc.id,
                    categoryName: name,
                  ),
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultCategoryIcon(),
                        )
                      : _defaultCategoryIcon(),
                ),
                title: Text(
                  name,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.lightTextPrimary),
                ),
                subtitle: Text(
                  'Tap to manage services',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.lightTextSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.primary),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary),
                      onPressed: () => ctrl.editCategory(
                        context,
                        doc.id,
                        name,
                        currentImageUrl: imageUrl,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      onPressed: () =>
                          ctrl.deleteCategory(context, doc.id, name),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _defaultCategoryIcon() {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.category_rounded,
          color: AppColors.primary, size: 18),
    );
  }

  void _showAddSheet(BuildContext context, AdminCategoriesController ctrl) {
    ctrl.nameCtrl.clear();
    ctrl.clearPickedImage();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
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
                      decoration: const BoxDecoration(
                        color: AppColors.lightBorder,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                ),
                Text('Add Category',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.lightTextPrimary)),
                const SizedBox(height: 4),
                Text('Enter a name and optional image',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.lightTextSecondary)),
                const SizedBox(height: 24),

                // ── Image Picker ─────────────────────────────────────────────
                Obx(() {
                  final hasImage = ctrl.pickedImageBytes.value != null;
                  return GestureDetector(
                    onTap: ctrl.pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightBorder),
                        image: hasImage
                            ? DecorationImage(
                                image: MemoryImage(ctrl.pickedImageBytes.value!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasImage
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
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 36,
                                    color: AppColors.primary),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add image (optional)',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                TextFormField(
                  controller: ctrl.nameCtrl,
                  autofocus: true,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.lightTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Bridal, Casual, Formal',
                    prefixIcon:
                        Icon(Icons.category_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (ctrl.isLoading.value ||
                                ctrl.isUploadingImage.value)
                            ? null
                            : ctrl.addCategory,
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
                            : const Text('Add Category'),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Services Screen ─────────────────────────────────────────────────────────

class AdminServicesScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const AdminServicesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminServicesController.to;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.filterByCategory(categoryId, categoryName);
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Services'),
            Text(
              categoryName,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.lightTextSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showAddSheet(context, ctrl),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.medium),
                textStyle: AppTextStyles.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.services.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.design_services_rounded,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text('No Services Yet',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.lightTextPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Tap "Add" to create a service with price',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final doc = ctrl.services[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final price = (data['price'] as num?)?.toDouble() ?? 0.0;
            final desc = data['description'] ?? '';

            return Container(
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: AppRadius.medium,
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: AppShadows.soft(AppColors.primary),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.design_services_rounded,
                      color: AppColors.primary, size: 18),
                ),
                title: Text(
                  name,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.lightTextPrimary),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.lightTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        'Rs. ${price.toStringAsFixed(0)}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primary),
                      onPressed: () =>
                          ctrl.editService(context, doc.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      onPressed: () =>
                          ctrl.deleteService(context, doc.id, name),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showAddSheet(BuildContext context, AdminServicesController ctrl) {
    ctrl.nameCtrl.clear();
    ctrl.priceCtrl.clear();
    ctrl.descCtrl.clear();

    Get.bottomSheet(
      Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
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
                      decoration: const BoxDecoration(
                        color: AppColors.lightBorder,
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                ),
                Text('Add Service',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.lightTextPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Adding to: $categoryName',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: ctrl.nameCtrl,
                  autofocus: true,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.lightTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    hintText: 'e.g. Bridal Lehenga, Shalwar Kameez',
                    prefixIcon:
                        Icon(Icons.design_services_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl.priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.lightTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Price (Rs.)',
                    hintText: 'e.g. 2500',
                    prefixIcon:
                        Icon(Icons.currency_rupee_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl.descCtrl,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.lightTextPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Brief description of the service',
                    prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ctrl.isLoading.value
                            ? null
                            : () =>
                                ctrl.addService(categoryId, categoryName),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: ctrl.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Text('Add Service'),
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
}