import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/artist_main_screen.dart';
import 'package:smartstitch/artist/design/design_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/design_widgets.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  late final ServiceController controller;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = UniqueKey().toString();
    controller = Get.put(ServiceController(), tag: _tag, permanent: true);
    controller.controllerTag = _tag;

    // ─── EDIT MODE: pre-fill the form from the passed-in service ──
    final args = Get.arguments;
    if (args is Map<String, dynamic> && args['id'] != null) {
      controller.loadServiceForEdit(args['id'] as String);
    }
  }

  @override
  void dispose() {
    Get.delete<ServiceController>(tag: _tag, force: true);
    super.dispose();
  }

  double _contentMaxWidth(double width) {
    if (width >= 900) return 700;
    return width;
  }

  double _galleryTileSize(double width) {
    if (width < 360) return 84;
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Obx(() => Text(
            controller.isEditing.value ? 'Edit Service' : 'Create Service')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Takes the artist straight back to their dashboard tab.
            Get.offAll(() => const ArtistMainScreen());
          },
        ),
        // ─── Preview-success eye icon removed (not needed) ───
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final maxContentWidth = _contentMaxWidth(width);
          final galleryTileSize = _galleryTileSize(width);

          return Column(
            children: [
              Obx(() => StepProgressHeader(
                  currentStep: controller.currentStep.value, isDark: isDark)),
              const Divider(height: 1),
              Expanded(
                child: Obx(() {
                  final step = controller.currentStep.value;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: SingleChildScrollView(
                      key: ValueKey(step),
                      padding: EdgeInsets.symmetric(
                        horizontal: width >= 900 ? 0 : 20,
                        vertical: 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: _currentStepWidget(
                            controller,
                            isDark,
                            step,
                            galleryTileSize,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Obx(() => Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: ServiceBottomNav(
                        currentStep: controller.currentStep.value,
                        totalSteps: ServiceController.totalSteps,
                        isDark: isDark,
                        isBusy: controller.isPublishing.value ||
                            controller.isSavingDraft.value,
                        onBack: controller.previousStep,
                        onNext: () {
                          if (controller.currentStep.value ==
                              ServiceController.totalSteps - 1) {
                            // ─── AUTO-DETECT: Create vs Edit ──────────
                            if (controller.isEditing.value) {
                              controller.updateService();
                            } else {
                              controller.publishService();
                            }
                          } else {
                            controller.nextStep();
                          }
                        },
                        onSaveDraft: controller.currentStep.value <
                                ServiceController.totalSteps - 1
                            ? controller.saveDraft
                            : null,
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _currentStepWidget(
    ServiceController c,
    bool isDark,
    int step,
    double galleryTileSize,
  ) {
    if (step == 0) return _buildImagesStep(c, isDark, galleryTileSize);
    if (step == 1) return _buildBasicInfoStep(c, isDark);
    if (step == 2) return _buildDetailsStep(c, isDark);
    if (step == 3) return _buildPricingStep(c, isDark);
    return _buildPublishStep(c, isDark);
  }

  // ─── STEP 1: Images ─────────────────────────────────────────
  Widget _buildImagesStep(
    ServiceController c,
    bool isDark,
    double galleryTileSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Cover Image',
          subtitle: 'This is the first image customers will see',
          isDark: isDark,
          child: Obx(() {
            final hasLocalCover = c.coverImage.value != null;
            final hasExistingCover = c.existingCoverImageUrl.value.isNotEmpty;

            if (!hasLocalCover && !hasExistingCover) {
              return GestureDetector(
                onTap: c.pickCoverImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface2
                        : AppColors.lightSurface2,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 36, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text('Tap to upload cover image',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)),
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.medium,
                    child: hasLocalCover
                        ? XFileThumb(
                            file: c.coverImage.value!, size: double.infinity)
                        : CachedNetworkImage(
                            imageUrl: c.existingCoverImageUrl.value,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? AppColors.darkSurface2
                                  : Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: c.pickCoverImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        SectionCard(
          title: 'Gallery Images',
          subtitle: 'Add 3–8 images of your sample work',
          isDark: isDark,
          child: Obx(() {
            final totalCount = c.existingGalleryImageUrls.length +
                c.galleryImages.length;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // ─── Existing (already-uploaded) gallery images ─────
                ...List.generate(c.existingGalleryImageUrls.length, (i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.medium,
                        child: CachedNetworkImage(
                          imageUrl: c.existingGalleryImageUrls[i],
                          width: galleryTileSize,
                          height: galleryTileSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => c.removeExistingGalleryImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // ─── Newly picked gallery images ─────────────────────
                ...List.generate(c.galleryImages.length, (i) {
                  return XFileThumb(
                    file: c.galleryImages[i],
                    onRemove: () => c.removeGalleryImage(i),
                  );
                }),
                if (totalCount < 8)
                  GestureDetector(
                    onTap: c.pickGalleryImages,
                    child: Container(
                      width: galleryTileSize,
                      height: galleryTileSize,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface2
                            : AppColors.lightSurface2,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                      child: Icon(Icons.add,
                          color: AppColors.primary, size: 28),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ─── STEP 2: Category + Service Selection (auto-fills fields) ───
  Widget _buildBasicInfoStep(ServiceController c, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Category',
          isDark: isDark,
          child: Obx(() => Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
                  borderRadius: AppRadius.medium,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.isCategoryLoading.value
                            ? 'Loading...'
                            : c.artistCategory.value,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              )),
        ),

        // In edit mode there's no template re-selection — the fields
        // below are already filled from the existing service.
        Obx(() {
          if (c.isEditing.value) return const SizedBox.shrink();
          return SectionCard(
            title: 'Select Service',
            subtitle:
                'Choose one of the predefined services for your category',
            isDark: isDark,
            child: Obx(() => SearchableServiceDropdown(
                  services: c.availableServices,
                  selected: c.selectedService.value,
                  isLoading: c.isServicesLoading.value,
                  isDark: isDark,
                  onSelect: c.selectService,
                )),
          );
        }),

        // Service name — editable directly when editing an existing
        // service (there's no template to derive it from).
        Obx(() {
          if (!c.isEditing.value) return const SizedBox.shrink();
          return SectionCard(
            title: 'Service Name',
            isDark: isDark,
            child: TextField(
              controller: c.serviceNameController,
              decoration: const InputDecoration(
                  hintText: 'e.g. Bridal Maxi Stitching'),
            ),
          );
        }),

        // Description — auto-filled from the selected service when
        // creating, editable when editing an existing service.
        SectionCard(
          title: 'Description',
          subtitle: 'Auto-filled from the selected service',
          isDark: isDark,
          child: Obx(() => TextField(
                controller: c.shortDescController,
                readOnly: !c.isEditing.value,
                maxLines: 3,
                style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                decoration: const InputDecoration(
                    hintText:
                        'Select a service above to auto-fill this field'),
              )),
        ),

        SectionCard(
          title: 'Starting Price (Auto-filled)',
          isDark: isDark,
          child: Obx(() => TextField(
                controller: c.startingPriceController,
                readOnly: !c.isEditing.value,
                keyboardType: TextInputType.number,
                style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                decoration: const InputDecoration(prefixText: 'Rs. '),
              )),
        ),
        SectionCard(
          title: 'Additional Notes (Optional)',
          subtitle: 'Anything extra you want customers to know',
          isDark: isDark,
          child: TextField(
            controller: c.longDescController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
                hintText:
                    'e.g. I only use premium thread, extra charges for rush orders...'),
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: Dynamic Category Details ─────────────────────────
  Widget _buildDetailsStep(ServiceController c, bool isDark) {
    return Obx(() {
      final fields = c.currentCategoryFields;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields.map((field) {
          return SectionCard(
            title: field.label,
            isDark: isDark,
            child: Obx(() {
              final currentValue = c.categoryFields[field.key];
              return ChipGroup(
                options: field.options,
                isDark: isDark,
                isSelected: (opt) => field.type == ServiceFieldType.chipSingle
                    ? currentValue == opt
                    : (currentValue is List && currentValue.contains(opt)),
                onTap: (opt) => field.type == ServiceFieldType.chipSingle
                    ? c.setSingleField(field.key, opt)
                    : c.toggleMultiField(field.key, opt),
              );
            }),
          );
        }).toList(),
      );
    });
  }

  // ─── STEP 4: Pricing ────────────────────────────────────────────
  Widget _buildPricingStep(ServiceController c, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Starting Price (Adjustable)',
          subtitle:
              'Pre-filled from the service you selected — change if needed',
          isDark: isDark,
          child: TextField(
            controller: c.startingPriceController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(prefixText: 'Rs. ', hintText: '5000'),
          ),
        ),
        SectionCard(
          title: 'Estimated Completion Days',
          isDark: isDark,
          child: TextField(
            controller: c.deliveryDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '7'),
          ),
        ),
        SectionCard(
          title: 'Revision Count',
          isDark: isDark,
          child: TextField(
            controller: c.revisionCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '2'),
          ),
        ),
        SectionCard(
          title: 'Additional Options',
          isDark: isDark,
          child: Column(
            children: [
              Obx(() => ToggleSettingTile(
                    icon: Icons.bolt,
                    title: 'Urgent Delivery',
                    subtitle: 'Offer faster delivery at extra cost',
                    value: c.urgentDelivery.value,
                    onChanged: (v) => c.urgentDelivery.value = v,
                    isDark: isDark,
                  )),
              const SizedBox(height: 10),
              Obx(() => ToggleSettingTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Home Pickup Available',
                    subtitle: "Pick up fabric from customer's home",
                    value: c.homePickupAvailable.value,
                    onChanged: (v) => c.homePickupAvailable.value = v,
                    isDark: isDark,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STEP 5: Enhanced Publish/Preview Screen ──────────────────────────────
  Widget _buildPublishStep(ServiceController c, bool isDark) {
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── PREMIUM PREVIEW CARD ───────────────────────────────────────
        SectionCard(
          title: 'Preview',
          subtitle:
              'Review your service before ${c.isEditing.value ? 'updating' : 'publishing'}',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Cover Image (Handles Create & Edit) ────────────────
              Obx(() {
                final hasNewImage = c.coverImage.value != null;
                final hasExistingImage =
                    c.existingCoverImageUrl.value.isNotEmpty;

                return ClipRRect(
                  borderRadius: AppRadius.medium,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: isDark
                        ? AppColors.darkSurface2
                        : AppColors.lightSurface2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasNewImage)
                          // ─── New locally-picked cover ────────────────
                          XFileThumb(
                            file: c.coverImage.value!,
                            size: double.infinity,
                          )
                        else if (hasExistingImage)
                          // ─── EDIT MODE: existing cover from Firestore ──
                          CachedNetworkImage(
                            imageUrl: c.existingCoverImageUrl.value,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: textSecondary,
                              ),
                            ),
                          )
                        else
                          // ─── NO IMAGE ────────────────────────────────
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: textSecondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ─── Service Title ──────────────────────────────────────
              Text(
                c.serviceNameController.text.trim().isEmpty
                    ? 'Untitled Service'
                    : c.serviceNameController.text.trim(),
                style: AppTextStyles.h4.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 8),

              // ─── Category Badge ─────────────────────────────────────
              Obx(() => Chip(
                    label: Text(
                      c.artistCategory.value,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  )),
              const SizedBox(height: 12),

              // ─── Short Description ──────────────────────────────────
              Text(
                c.shortDescController.text.trim().isEmpty
                    ? 'No description provided'
                    : c.shortDescController.text.trim(),
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // ─── Long Description (if any) ──────────────────────────
              if (c.longDescController.text.trim().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Notes',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.longDescController.text.trim(),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // ─── Pricing & Delivery Info (Premium Layout) ───────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Starting Price',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: textSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'Rs. ${c.startingPriceController.text.isEmpty ? '0' : c.startingPriceController.text}',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.h5.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // Delivery Days & Revisions Row
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 16,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery',
                                  style: AppTextStyles.caption.copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                                Text(
                                  '${c.deliveryDaysController.text.isEmpty ? '-' : c.deliveryDaysController.text} days',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_outlined,
                              size: 16,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Revisions',
                                  style: AppTextStyles.caption.copyWith(
                                    color: textSecondary,
                                  ),
                                ),
                                Text(
                                  c.revisionCountController.text.isEmpty
                                      ? '0'
                                      : c.revisionCountController.text,
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ─── Add-ons (Urgent Delivery & Home Pickup) ────────────
              Obx(() {
                final hasAddOns =
                    c.urgentDelivery.value || c.homePickupAvailable.value;
                if (!hasAddOns) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Add-ons',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (c.urgentDelivery.value)
                          _buildAddOnChip('⚡ Urgent Delivery', isDark),
                        if (c.homePickupAvailable.value)
                          _buildAddOnChip('🚚 Home Pickup', isDark),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

              // ─── Category Fields Display (Chips) ────────────────────
              Obx(() {
                final fields = c.currentCategoryFields;
                final selectedFields = c.categoryFields;

                if (selectedFields.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Details',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    ...fields.map((field) {
                      final value = selectedFields[field.key];
                      if (value == null) return const SizedBox.shrink();

                      final displayValues =
                          field.type == ServiceFieldType.chipSingle
                              ? [value.toString()]
                              : (value is List
                                  ? List<String>.from(value)
                                  : [value.toString()]);

                      if (displayValues.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: displayValues.map((v) {
                              return Chip(
                                label: Text(
                                  v,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ],
                );
              }),
            ],
          ),
        ),

        // ─── INFO BANNER (Context-aware) ─────────────────────────────
        Obx(() => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.medium,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.isEditing.value
                          ? 'Updates will be applied immediately. You can edit or unpublish from My Services.'
                          : 'Once published, customers will be able to book this service. You can edit or unpublish it anytime from My Services.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ─── Helper Widget for Add-ons ──────────────────────────────────────────
  Widget _buildAddOnChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        border: Border.all(color: AppColors.primary),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}