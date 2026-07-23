import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/user/review/review_controller.dart';
import '../../core/theme/app.theme.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  final _picker = ImagePicker();
  final ReviewController _controller = Get.find<ReviewController>();

  final Rx<Map<String, dynamic>?> _selectedBooking =
      Rx<Map<String, dynamic>?>(null);

  int _mainRating = 4;
  final Map<String, int> _subRatings = {
    'Stitching Quality': 5,
    'Communication'    : 5,
    'Delivery Time'    : 4,
    'Value for Money'  : 5,
  };
  final List<Uint8List> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    final userId = AuthController.to.currentUser.value?.id ?? '';
    if (userId.isNotEmpty) {
      _controller.loadEligibleBookings(userId);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 70);
    for (final img in picked) {
      if (_selectedImages.length >= 4) break;
      final bytes = await img.readAsBytes();
      setState(() => _selectedImages.add(bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Write Review',
            style: AppTextStyles.h4.copyWith(
                color: theme.colorScheme.onSurface)),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── SELECT BOOKING ──────────────────────────
            Text('Select Booking',
                style: AppTextStyles.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Obx(() {
              if (_controller.isLoadingBookings.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (_controller.eligibleBookings.isEmpty) {
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
                          "Reviews can only be written for completed bookings that haven't been reviewed yet.",
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        value: _selectedBooking.value,
                        dropdownColor: theme.colorScheme.surface,
                        hint: Text(
                          "Select a completed booking...",
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: theme.colorScheme.onSurfaceVariant),
                        items: _controller.eligibleBookings.map((b) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: b,
                            child: Text(
                              "#${b['shortId']}  •  ${b['artistName']}  •  ${b['serviceTitle']}",
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => _selectedBooking.value = val,
                      ),
                    ),
                  ),

                  // Selected booking preview
                  Obx(() {
                    final b = _selectedBooking.value;
                    if (b == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: AppRadius.small,
                        border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: b['artistImageUrl'] != null
                                ? NetworkImage(b['artistImageUrl'])
                                : null,
                            child: b['artistImageUrl'] == null
                                ? Text(
                                    b['artistName'][0].toUpperCase(),
                                    style: AppTextStyles.h4.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['artistName'],
                                    style: AppTextStyles.labelLarge.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600)),
                                Text(b['serviceTitle'],
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant)),
                                Text("#${b['shortId']}",
                                    style: AppTextStyles.caption.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant)),
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

            const SizedBox(height: 24),

            // ── Rate Your Experience ────────────────────
            Text('Rate Your Experience',
                style: AppTextStyles.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _mainRating = star),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      star <= _mainRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── Comment ─────────────────────────────────
            Text('Comment',
                style: AppTextStyles.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
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

            const SizedBox(height: 20),

            // ── Upload Images ────────────────────────────
            Text('Upload Images',
                style: AppTextStyles.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 28),
                      const SizedBox(height: 4),
                      Text('Add Photos',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: theme.colorScheme.onPrimaryContainer)),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedImages.map(
                    (bytes) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(bytes,
                              width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selectedImages.remove(bytes)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedImages.length < 4)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.add_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 28),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 24),

            // ── Detailed Ratings ─────────────────────────
            Text('Detailed Ratings',
                style: AppTextStyles.labelLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._subRatings.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _subRatings[entry.key] = star),
                          child: Icon(
                            star <= entry.value
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 22,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ).toList(),

            const SizedBox(height: 28),

            // ── Submit Button ────────────────────────────
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_controller.isSubmitting.value ||
                            _controller.isUploadingImages.value)
                        ? null
                        : () async {
                            if (_selectedBooking.value == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Please select a booking first"),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final b = _selectedBooking.value!;

                            await _controller.submitReview(
                              orderId   : b['id'],
                              artistId  : b['artistId'],
                              artistName: b['artistName'],
                              rating    : _mainRating,
                              comment   : _commentController.text,
                              images    : _selectedImages,
                              subRatings: _subRatings,
                            );

                            if (mounted) {
                              setState(() {
                                _mainRating = 4;
                                _selectedImages.clear();
                                _subRatings.updateAll((key, _) => 5);
                                _selectedBooking.value = null;
                              });
                              _commentController.clear();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: (_controller.isSubmitting.value ||
                            _controller.isUploadingImages.value)
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text('Submit Review',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                )),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}