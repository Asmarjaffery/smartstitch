import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/user/complaint/complaint_controller.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  late final ComplaintController controller;
  final ImagePicker _picker = ImagePicker();

  final List<String> _issueTypes = [
    "Wrong Stitching",
    "Late Delivery",
    "Fabric Damage",
    "Measurement Issue",
    "Other",
  ];

  final RxString _selectedIssue = "Wrong Stitching".obs;
  final RxString _priority = "Medium".obs;
  final RxList<XFile> _images = <XFile>[].obs;
  final RxList<XFile> _videos = <XFile>[].obs;

  // Dropdown ki value ab poore Map object ki bajaye sirf bookingId (String)
  // hai. DropdownButton apni value ko object identity (==) se match karta
  // hai — Map identity list rebuild hone par toot jati hai aur crash deti
  // hai. String id hamesha value-equality se sahi match hoti hai.
  final RxnString _selectedBookingId = RxnString();

  Map<String, dynamic>? get _selectedBooking {
    final id = _selectedBookingId.value;
    if (id == null) return null;
    for (final b in controller.eligibleBookings) {
      if (b['id'] == id) return b;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    controller = Get.find<ComplaintController>();
    final userId = AuthController.to.currentUser.value?.id ?? '';
    if (userId.isNotEmpty) {
      controller.loadEligibleBookings(userId);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        _images.add(image);
        AppHelpers.showSuccess("Image added");
      }
    } catch (e) {
      AppHelpers.showError("Could not pick image: $e");
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        _videos.add(video);
        AppHelpers.showSuccess("Video added");
      }
    } catch (e) {
      AppHelpers.showError("Could not pick video: $e");
    }
  }

  Future<void> _handleSubmit() async {
    // Poora submit flow try/catch mein — koi bhi unexpected exception
    // (network, null field, navigation) ab red error screen ki bajaye
    // ek normal error message dikhayegi.
    try {
      final booking = _selectedBooking;

      if (booking == null) {
        AppHelpers.showError("Please select a booking first");
        return;
      }

      if (booking['hasComplaint'] == true) {
        AppHelpers.showError(
            "You have already submitted a complaint for this booking.");
        return;
      }

      final user = AuthController.to.currentUser.value;
      final userId = user?.id ?? '';
      final userName = user?.name ?? '';

      if (userId.isEmpty) {
        AppHelpers.showError("User not logged in");
        return;
      }

      controller.orderIdController.text = booking['shortId'] ?? '';
      controller.subjectController.text = booking['artistName'] ?? '';

      final success = await controller.submitComplaint(
        userId: userId,
        userName: userName,
        issueType: _selectedIssue.value,
        priority: _priority.value,
        images: _images,
        videos: _videos,
        bookingId: booking['id'],
        artistId: booking['artistId'],
      );

      if (!mounted) return;

      if (success) {
        AppHelpers.showSuccess("Complaint submitted");
        Navigator.of(context).pop();
      } else {
        AppHelpers.showError(
          controller.errorMessage.value ?? "Something went wrong",
        );
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showError("Something went wrong: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          "Create Complaint",
          style: AppTextStyles.h4
              .copyWith(color: theme.colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── SELECT BOOKING ─────────────────────────
              _sectionCard(
                context: context,
                title: "Select Booking",
                child: Obx(() {
                  if (controller.isLoadingBookings.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (controller.eligibleBookings.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: AppRadius.small,
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "No eligible bookings found.\n"
                              "• Completed / delivered orders can always be complained about\n"
                              "• Other orders are eligible once payment is made online",
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Choose the booking related to your complaint",
                        style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: AppRadius.medium,
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedBookingId.value,
                            dropdownColor: theme.colorScheme.surface,
                            hint: Text(
                              "Select a booking...",
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: theme.colorScheme.onSurfaceVariant),
                            items: controller.eligibleBookings.map((b) {
                              final bool hasComplaint =
                                  b['hasComplaint'] == true;
                              return DropdownMenuItem<String>(
                                value: b['id'] as String,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "#${b['shortId']}  •  ${b['artistName']}  •  ${b['serviceTitle']}",
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                          color: hasComplaint
                                              ? theme
                                                  .colorScheme.onSurfaceVariant
                                              : theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasComplaint) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        "Already Complained",
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id == null) return;
                              final match = controller.eligibleBookings
                                  .firstWhere((x) => x['id'] == id);
                              if (match['hasComplaint'] == true) {
                                AppHelpers.showError(
                                    "You have already submitted a complaint for this booking.");
                                return;
                              }
                              _selectedBookingId.value = id;
                            },
                          ),
                        ),
                      ),

                      // Selected booking info
                      Obx(() {
                        // _selectedBookingId.value read yahan taake Obx
                        // is Rx ko track kare aur selection badalne par
                        // rebuild ho
                        _selectedBookingId.value;
                        final b = _selectedBooking;
                        if (b == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: AppRadius.small,
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                backgroundImage: b['artistImageUrl'] != null
                                    ? NetworkImage(b['artistImageUrl'])
                                    : null,
                                child: b['artistImageUrl'] == null
                                    ? Text(
                                        (b['artistName'] as String)
                                                .isNotEmpty
                                            ? b['artistName'][0].toUpperCase()
                                            : '?',
                                        style: AppTextStyles.h4.copyWith(
                                            color: theme.colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(b['artistName'],
                                        style: AppTextStyles.labelLarge
                                            .copyWith(
                                                color: theme.colorScheme
                                                    .onSurface,
                                                fontWeight:
                                                    FontWeight.w600)),
                                    Text(b['serviceTitle'],
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant)),
                                    Text("#${b['shortId']}",
                                        style: AppTextStyles.caption.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 20),

              // ── ISSUE TYPE ─────────────────────────────
              _sectionCard(
                context: context,
                title: "Issue Type",
                child: Obx(() => Column(
                      children: _issueTypes.map((issue) {
                        return Row(
                          children: [
                            Radio<String>(
                              value: issue,
                              groupValue: _selectedIssue.value,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (v) =>
                                  _selectedIssue.value = v!,
                            ),
                            Text(issue,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: theme.colorScheme.onSurface)),
                          ],
                        );
                      }).toList(),
                    )),
              ),

              const SizedBox(height: 20),

              // ── DESCRIPTION ────────────────────────────
              _sectionCard(
                context: context,
                title: "Description",
                child: TextField(
                  controller: controller.descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: "Describe your complaint...",
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 1.5),
                    ),
                    counterStyle: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── ATTACHMENTS ────────────────────────────
              _sectionCard(
                context: context,
                title: "Attachments",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _uploadButton(
                          context: context,
                          icon: Icons.image_outlined,
                          label: "Add Image",
                          onTap: _pickImage,
                        ),
                        const SizedBox(width: 10),
                        _uploadButton(
                          context: context,
                          icon: Icons.videocam_outlined,
                          label: "Add Video",
                          onTap: _pickVideo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (_images.isEmpty && _videos.isEmpty) {
                        return Text(
                          "No files selected",
                          style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        );
                      }
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ..._images.map((img) => _fileChip(
                                context: context,
                                icon: Icons.image_rounded,
                                name: img.name,
                                onRemove: () => _images.remove(img),
                              )),
                          ..._videos.map((vid) => _fileChip(
                                context: context,
                                icon: Icons.videocam_rounded,
                                name: vid.name,
                                onRemove: () => _videos.remove(vid),
                              )),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── PRIORITY ────────────────────────────────
              _sectionCard(
                context: context,
                title: "Priority",
                child: Obx(() => Row(
                      children: ["Low", "Medium", "High"].map((p) {
                        return Row(
                          children: [
                            Radio<String>(
                              value: p,
                              groupValue: _priority.value,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (v) => _priority.value = v!,
                            ),
                            Text(p,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: theme.colorScheme.onSurface)),
                            const SizedBox(width: 12),
                          ],
                        );
                      }).toList(),
                    )),
              ),

              const SizedBox(height: 24),

              // ── SUBMIT BUTTON ──────────────────────────
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          controller.isSubmitting.value ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                        elevation: 0,
                        textStyle: AppTextStyles.button,
                      ),
                      child: controller.isSubmitting.value
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text("Submit Complaint"),
                    ),
                  )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.medium,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: AppRadius.medium,
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.h5
                    .copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _uploadButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        label: Text(label,
            style: AppTextStyles.labelMedium
                .copyWith(color: theme.colorScheme.onSurfaceVariant)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.outline),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
    );
  }

  Widget _fileChip({
    required BuildContext context,
    required IconData icon,
    required String name,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(
        name.length > 20 ? '${name.substring(0, 20)}...' : name,
        style: AppTextStyles.labelSmall
            .copyWith(color: theme.colorScheme.onSurface),
      ),
      deleteIcon:
          Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface),
      onDeleted: onRemove,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outline),
    );
  }
}