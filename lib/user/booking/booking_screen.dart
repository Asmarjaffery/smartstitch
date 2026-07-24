import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/service_model.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary, size: 16),
          ),
        ),
        title: Column(
          children: [
            const Text('Book a Service', style: AppTextStyles.h4),
            Text(
              'Choose your service and preferred time',
              style: AppTextStyles.caption
                  .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.notifications_none_rounded,
                      color: AppColors.primary, size: 20),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Step Indicator ────────────────────────────────────
            const _StepIndicator(currentStep: 1),
            const SizedBox(height: 28),

            // ─── Select Service ────────────────────────────────────
            const _SectionHeader(title: 'Select Service'),
            const SizedBox(height: 14),
            Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = ctrl.filteredServices;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No services available for this artist.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final displayList = list.length > 3 ? list.sublist(0, 3) : list;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ServiceTile(service: displayList[i]),
              );
            }),

            const SizedBox(height: 8),
            // View more services
            Obx(() {
              final list = ctrl.filteredServices;
              if (list.length <= 3) return const SizedBox();
              return Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary, size: 18),
                  label: Text(
                    'View more services',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // ─── Visit Type ────────────────────────────────────────
            const _SectionHeader(title: 'Visit Type'),
            const SizedBox(height: 14),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _VisitTypeCard(
                        icon: Icons.store_outlined,
                        label: 'Drop Off',
                        subtitle: 'Bring clothes\nto the artist',
                        isSelected: !ctrl.isHomeVisit.value,
                        onTap: () => ctrl.isHomeVisit.value = false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VisitTypeCard(
                        icon: Icons.home_outlined,
                        label: 'Home Visit',
                        subtitle: 'Artist comes\nto your place',
                        isSelected: ctrl.isHomeVisit.value,
                        onTap: () => ctrl.isHomeVisit.value = true,
                      ),
                    ),
                  ],
                )),

            // ─── Artist Shop Address (Drop Off Only) ───────────────
            Obx(() {
              if (ctrl.isHomeVisit.value) return const SizedBox();
              final address = ctrl.selectedArtist.value?.shopAddress;
              if (address == null || address.fullAddress.isEmpty) {
                return const SizedBox();
              }
              return Column(
                children: [
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.medium,
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: AppRadius.small,
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Artist Shop Location',
                                style: AppTextStyles.caption.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                address.fullAddress,
                                style: AppTextStyles.labelMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (address.city.isNotEmpty)
                                Text(
                                  '${address.city}, ${address.province}',
                                  style: AppTextStyles.caption.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            }),

            // ─── Home Visit Info Message ───────────────────────────
            Obx(() {
              if (!ctrl.isHomeVisit.value) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.medium,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Artist will visit your location. You can provide your address in the next step.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // ─── Select Date (Preferred) ────────────────────────────
            const _SectionHeader(title: 'Preferred Date'),
            const SizedBox(height: 14),
            Obx(() => GestureDetector(
                  onTap: () => ctrl.pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: ctrl.selectedDate.value != null
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: AppRadius.small,
                          ),
                          child: const Icon(Icons.calendar_month_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Date',
                              style: AppTextStyles.caption.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ctrl.selectedDate.value != null
                                  ? _formatDate(ctrl.selectedDate.value!)
                                  : 'Tap to select date',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: ctrl.selectedDate.value != null
                                    ? theme.colorScheme.onSurface
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.lightTextHint),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today_outlined,
                              color: AppColors.primary, size: 16),
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 28),

            // ─── Select Time Slot (Required) ────────────────────────
            const _SectionHeader(title: 'Preferred Time'),
            const SizedBox(height: 6),
            Text(
              'Select a time slot. Artist will confirm it after reviewing your booking.',
              style: AppTextStyles.caption
                  .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 14),
            _TimeSlotDropdown(),

            const SizedBox(height: 28),

            // ─── Upload Design (multiple — each image adds Rs 200,
            // doubling with every extra upload: 1 img = 200, 2 = 400,
            // 3 = 600, ...) ────────────────────────────────────────
            Row(
              children: [
                const _SectionHeader(title: 'Upload Design (Optional)'),
                const SizedBox(width: 8),
                Obx(() {
                  if (ctrl.designImageUrls.isEmpty) return const SizedBox();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+Rs ${ctrl.designImageFee.toInt()}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Each design image adds Rs 200 to your total.',
              style: AppTextStyles.caption
                  .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 14),

            // Uploaded images grid
            Obx(() {
              if (ctrl.designImageUrls.isEmpty) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (int i = 0; i < ctrl.designImageUrls.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.medium,
                            child: Image.network(
                              ctrl.designImageUrls[i],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => ctrl.removeDesignImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),

            // Upload box / add more button
            Obx(() => GestureDetector(
                  onTap: ctrl.isUploadingImage.value
                      ? null
                      : ctrl.uploadDesignImage,
                  child: Container(
                    width: double.infinity,
                    height: ctrl.designImageUrls.isEmpty ? 200 : 90,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: ctrl.uploadFailed.value
                            ? AppColors.error
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: ctrl.isUploadingImage.value
                        ? const Center(child: CircularProgressIndicator())
                        : ctrl.uploadFailed.value
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_off_outlined,
                                      color: AppColors.error, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload failed',
                                    style: AppTextStyles.labelMedium
                                        .copyWith(color: AppColors.error),
                                  ),
                                  Text(
                                    'Tap to try again',
                                    style: AppTextStyles.caption.copyWith(
                                        color:
                                            Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ctrl.designImageUrls.isEmpty
                                        ? Icons.cloud_upload_outlined
                                        : Icons.add_photo_alternate_outlined,
                                    color: AppColors.primary,
                                    size: ctrl.designImageUrls.isEmpty ? 36 : 26,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ctrl.designImageUrls.isEmpty
                                        ? 'Upload your design'
                                        : 'Add another design (+Rs 200)',
                                    style: AppTextStyles.labelMedium
                                        .copyWith(color: AppColors.primary),
                                  ),
                                  if (ctrl.designImageUrls.isEmpty)
                                    Text(
                                      'JPG, PNG supported',
                                      style: AppTextStyles.caption.copyWith(
                                          color:
                                              Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                ],
                              ),
                  ),
                )),

            const SizedBox(height: 28),

            // ─── Special Instructions ──────────────────────────────
            Row(
              children: [
                const _SectionHeader(title: 'Special Instructions (Optional)'),
                const SizedBox(width: 8),
                Obx(() {
                  if (ctrl.specialInstructions.value.trim().isEmpty) {
                    return const SizedBox();
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+Rs ${ctrl.specialInstructionsFee.toInt()}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Adding instructions adds a flat Rs 200 to your total.',
              style: AppTextStyles.caption
                  .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => ctrl.specialInstructions.value = v,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requirements...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.lightTextHint)),
                border: const OutlineInputBorder(borderRadius: AppRadius.medium),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: 6),
        Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Price',
                style: AppTextStyles.caption
                    .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 2),
              // Includes base price + design-image fee + special
              // instructions fee, so the customer sees the real running
              // total as soon as they add either one.
              Obx(() {
                final base = ctrl.selectedService.value?.basePrice ?? 0;
                final total = base + ctrl.extraChargesFee;
                return Text(
                  ctrl.selectedService.value != null
                      ? 'PKR ${total.toInt()}'
                      : 'PKR 0',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                );
              }),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading.value
                        ? null
                        : () {
                            if (ctrl.selectedService.value == null) {
                              AppHelpers.showError('Please select a service.');
                              return;
                            }
                            if (ctrl.selectedDate.value == null) {
                              AppHelpers.showError('Please select a date.');
                              return;
                            }
                            if (ctrl.selectedTimeSlot.value.isEmpty) {
                              AppHelpers.showError(
                                  'Please select a time slot.');
                              return;
                            }
                            Get.toNamed(AppRoutes.bookingAddressMeasurement);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium),
                    ),
                    child: ctrl.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Next Step',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Time Slot Dropdown ───────────────────────────────────────────────────────
class _TimeSlotDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    final theme = Theme.of(context);

    return Obx(() {
      final selected = ctrl.selectedTimeSlot.value;
      final hintColor = Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkTextHint
          : AppColors.lightTextHint;
      return GestureDetector(
        onTap: () => _showTimeSlotSheet(context, ctrl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: selected.isNotEmpty
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.small,
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Preferred Time',
                    style: AppTextStyles.caption
                        .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 2),
                  // Shows the actual selected slot only. No fake
                  // placeholder value — if nothing is selected yet it
                  // says so clearly, so the customer isn't misled into
                  // thinking a slot is already chosen.
                  Text(
                    selected.isNotEmpty ? selected : 'Tap to select time slot',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: selected.isNotEmpty ? null : hintColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).textTheme.bodySmall?.color),
            ],
          ),
        ),
      );
    });
  }

  void _showTimeSlotSheet(BuildContext context, BookingController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Time Slot', style: AppTextStyles.h4),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ctrl.timeSlots
                  .map((slot) => _TimeSlotChip(slot: slot))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Service', 'Details', 'Address', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = (i ~/ 2) + 1;
            return Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 20),
                color: stepIndex < currentStep
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outline,
              ),
            );
          }
          final stepIndex = i ~/ 2 + 1;
          final isActive = stepIndex <= currentStep;
          final isDone = stepIndex < currentStep;
          return _Step(
            number: stepIndex,
            label: steps[stepIndex - 1],
            isActive: isActive,
            isDone: isDone,
          );
        }),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;
  const _Step({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : Theme.of(context).colorScheme.outline,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$number',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isActive
                          ? Colors.white
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Service Tile ─────────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    return Obx(() {
      final isSelected = ctrl.selectedService.value?.id == service.id;
      return GestureDetector(
        onTap: () => ctrl.selectService(service),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.small,
                child: service.imageUrl.isNotEmpty
                    ? Image.network(
                        service.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : null,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '3 – 4 Days',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PKR ${service.basePrice.toInt()}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _imgPlaceholder() => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppRadius.small,
        ),
        child: const Icon(Icons.checkroom_rounded,
            color: AppColors.primary, size: 20),
      );
}

// ─── Visit Type Card ──────────────────────────────────────────────────────────
class _VisitTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisitTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time Slot Chip ───────────────────────────────────────────────────────────
class _TimeSlotChip extends StatelessWidget {
  final String slot;
  const _TimeSlotChip({required this.slot});

  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    return Obx(() {
      final isSelected = ctrl.selectedTimeSlot.value == slot;
      return GestureDetector(
        onTap: () {
          ctrl.selectTimeSlot(slot);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            slot,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }
}