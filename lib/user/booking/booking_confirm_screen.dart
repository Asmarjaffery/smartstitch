import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/models/enums.dart';
import 'package:smartstitch/routes/routes.dart';
import 'package:smartstitch/services/pdf_service.dart';
import 'package:smartstitch/user/booking/booking_controller.dart';

class BookingConfirmScreen extends StatelessWidget {
  final bool isSuccess;
  final bool isPending;

  const BookingConfirmScreen({
    super.key,
    this.isSuccess = false,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor =
        isDark ? AppColors.darkBackground : theme.scaffoldBackgroundColor;
    final surfaceColor =
        isDark ? AppColors.darkSurface : theme.colorScheme.surface;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    const primary = AppColors.primary;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;

    // ─── Payment Processing (Pending) Screen ───────────────────────
    if (isPending) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 25),
                Text(
                  "Payment Processing...",
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 10),
                Text(
                  "Please wait while we verify your payment.\nThis may take a few seconds.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── Step 4: Success Screen ───────────────────────────────────
    if (isSuccess) {
      return Scaffold(
        backgroundColor: bgColor,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(AppRoutes.customerHome),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium)),
              icon: const Icon(Icons.home_outlined,
                  color: Colors.white, size: 22),
              label: Text('Go to Home',
                  style:
                      AppTextStyles.labelLarge.copyWith(color: Colors.white)),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              const SizedBox(height: 48),
              const _StepIndicator(currentStep: 4),
              const SizedBox(height: 40),
              _SuccessIllustration(isDark: isDark),
              const SizedBox(height: 32),
              Text(
                'Booking Confirmed!',
                style: AppTextStyles.h2
                    .copyWith(fontWeight: FontWeight.w800, color: textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your booking has been placed successfully.\nArtist will confirm shortly.',
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // ─── Download & Share PDF ─────────────────────────────
              Obx(() {
                final booking = ctrl.lastBooking.value;
                if (booking == null) return const SizedBox();

                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isLoading.value
                            ? null
                            : () async {
                                try {
                                  ctrl.isLoading.value = true;
                                  await PdfService.instance.generateBookingPdf(
                                    bookingId: booking.id,
                                    serviceTitle: booking.serviceTitle,
                                    appointmentDate: booking.appointmentDate,
                                    timeSlot: booking.timeSlot,
                                    isHomeVisit: booking.isHomeVisit,
                                    paymentMethod: booking.paymentMethod ??
                                        PaymentMethod.wallet,
                                    servicePrice: booking.servicePrice,
                                  );
                                  ctrl.isLoading.value = false;
                                  if (kIsWeb) {
                                    AppHelpers.showSuccess(
                                        'PDF downloaded successfully!');
                                  } else {
                                    AppHelpers.showSuccess(
                                        'PDF saved to documents!');
                                  }
                                } catch (e) {
                                  ctrl.isLoading.value = false;
                                  AppHelpers.showError(
                                      'Failed to generate PDF: $e');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.medium)),
                        icon: ctrl.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded,
                                color: Colors.white, size: 22),
                        label: Text('Download PDF',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final b = ctrl.lastBooking.value;
                            if (b == null) {
                              AppHelpers.showError('No booking data available');
                              return;
                            }
                            final pdfResult =
                                await PdfService.instance.generateBookingPdf(
                              bookingId: b.id,
                              serviceTitle: b.serviceTitle,
                              appointmentDate: b.appointmentDate,
                              timeSlot: b.timeSlot,
                              isHomeVisit: b.isHomeVisit,
                              paymentMethod:
                                  b.paymentMethod ?? PaymentMethod.wallet,
                              servicePrice: b.servicePrice,
                            );
                            await PdfService.instance.sharePdf(
                              file: pdfResult.file,
                              bytes: pdfResult.bytes,
                              fileName: pdfResult.fileName,
                            );
                          } catch (e) {
                            AppHelpers.showError('Failed to share PDF: $e');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primary),
                            shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.medium)),
                        icon: const Icon(Icons.share_rounded,
                            color: primary, size: 22),
                        label: Text('Share PDF',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: primary)),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // ─── Notification Info Card ──────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: primarySoft,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.calendar_month_rounded,
                          color: primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'We will notify you once the artist confirms your booking.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Booking Details Card ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: AppRadius.large,
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Details',
                        style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 16),
                    Obx(() => _DetailRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Service',
                        value: ctrl.lastBooking.value?.serviceTitle ?? '-',
                        isDark: isDark)),
                    _Divider(isDark: isDark),
                    Obx(() => _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: ctrl.lastBooking.value != null
                            ? _formatDate(
                                ctrl.lastBooking.value!.appointmentDate)
                            : '-',
                        isDark: isDark)),
                    _Divider(isDark: isDark),
                    Obx(() => _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value:
                            ctrl.lastBooking.value?.timeSlot.isNotEmpty == true
                                ? ctrl.lastBooking.value!.timeSlot
                                : 'Not specified',
                        isDark: isDark)),
                    _Divider(isDark: isDark),
                    Obx(() => _DetailRow(
                        icon: (ctrl.lastBooking.value?.isHomeVisit ?? false)
                            ? Icons.home_outlined
                            : Icons.store_outlined,
                        label: 'Visit Type',
                        value: (ctrl.lastBooking.value?.isHomeVisit ?? false)
                            ? 'Home Visit'
                            : 'Drop Off',
                        isDark: isDark)),
                    _Divider(isDark: isDark),
                    Obx(() => _DetailRow(
                        icon: Icons.payment_rounded,
                        label: 'Payment Method',
                        value: ctrl.lastBooking.value?.paymentMethod != null
                            ? _paymentLabel(
                                ctrl.lastBooking.value!.paymentMethod!)
                            : '-',
                        isDark: isDark)),
                    _Divider(isDark: isDark),

                    // ✅ Price breakdown success screen
                    Obx(() {
                      final booking = ctrl.lastBooking.value;
                      final isHome = booking?.isHomeVisit ?? false;
                      final total = booking?.servicePrice.toInt() ?? 0;
                      final deliveryFee = isHome ? 200 : 0;
                      final basePrice = total - deliveryFee;

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Service Price',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textSecondary)),
                              Text('Rs $basePrice',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textPrimary)),
                            ],
                          ),
                          if (isHome) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Delivery Fee',
                                    style: AppTextStyles.labelMedium
                                        .copyWith(color: textSecondary)),
                                Text('Rs $deliveryFee',
                                    style: AppTextStyles.labelMedium
                                        .copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ],
                          Divider(height: 16, color: borderColor),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount',
                                  style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary)),
                              Text(
                                'Rs $total',
                                style: AppTextStyles.h4.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    // ─── Step 3: Confirm Screen ───────────────────────────────────
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: primarySoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: primary, size: 16),
          ),
        ),
        title: Column(
          children: [
            Text('Confirm Booking',
                style: AppTextStyles.h4.copyWith(color: textPrimary)),
            Text('Step 3 of 4',
                style: AppTextStyles.caption.copyWith(color: textSecondary)),
          ],
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
      ),
      bottomNavigationBar: _BottomButtons(isDark: isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StepIndicator(currentStep: 3),
            const SizedBox(height: 28),

            // ─── Booking Summary Card ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: AppRadius.large,
                border: Border.all(color: borderColor),
                boxShadow: AppShadows.soft(primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: AppRadius.medium),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Booking Summary',
                          style: AppTextStyles.h4.copyWith(color: textPrimary)),
                    ],
                  ),
                  Divider(height: 28, color: borderColor),
                  Obx(() => _SummaryRow(
                      icon: Icons.checkroom_rounded,
                      label: 'Service',
                      value: ctrl.selectedService.value?.title ?? '-',
                      isDark: isDark)),
                  const SizedBox(height: 12),
                  Obx(() => _SummaryRow(
                      icon: ctrl.isHomeVisit.value
                          ? Icons.home_outlined
                          : Icons.store_outlined,
                      label: 'Visit Type',
                      value: ctrl.isHomeVisit.value ? 'Home Visit' : 'Drop Off',
                      isDark: isDark)),
                  const SizedBox(height: 12),
                  Obx(() => _SummaryRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: ctrl.selectedDate.value != null
                          ? _formatDate(ctrl.selectedDate.value!)
                          : '-',
                      isDark: isDark)),
                  const SizedBox(height: 12),
                  Obx(() => _SummaryRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: ctrl.selectedTimeSlot.value.isNotEmpty
                          ? ctrl.selectedTimeSlot.value
                          : 'Not specified',
                      isDark: isDark)),
                  Obx(() {
                    if (!ctrl.isHomeVisit.value) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _SummaryRow(
                        icon: Icons.location_on_rounded,
                        label: 'Your Address',
                        value: ctrl.selectedAddress.value != null
                            ? '${ctrl.selectedAddress.value!.fullAddress}, ${ctrl.selectedAddress.value!.city}'
                            : '-',
                        isDark: isDark,
                      ),
                    );
                  }),
                  Obx(() {
                    final m = ctrl.selectedMeasurement.value;
                    if (m == null) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _SummaryRow(
                        icon: Icons.straighten_rounded,
                        label: 'Measurement',
                        value: m.isAiGenerated ? 'AI Scan' : 'Manual Entry',
                        isDark: isDark,
                      ),
                    );
                  }),
                  // ─── Design images (now supports multiple) ────────
                  Obx(() {
                    if (ctrl.designImageUrls.isEmpty) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Design (${ctrl.designImageUrls.length})',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: textSecondary),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: ctrl.designImageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) => ClipRRect(
                                borderRadius: AppRadius.medium,
                                child: Image.network(
                                  ctrl.designImageUrls[i],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Obx(() {
                    if (ctrl.specialInstructions.value.isEmpty) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _SummaryRow(
                        icon: Icons.notes_rounded,
                        label: 'Instructions',
                        value: ctrl.specialInstructions.value,
                        isDark: isDark,
                      ),
                    );
                  }),
                  Divider(height: 28, color: borderColor),

                  // ✅ Price breakdown Step 3 — now includes design image
                  // fee (Rs 200 per image, doubling with each extra
                  // upload) and a flat Rs 200 special-instructions fee.
                  Obx(() {
                    final basePrice =
                        ctrl.selectedService.value?.basePrice.toInt() ?? 0;
                    final isHome = ctrl.isHomeVisit.value;
                    final deliveryFee = isHome ? 200 : 0;
                    final designFee = ctrl.designImageFee.toInt();
                    final instructionsFee =
                        ctrl.specialInstructionsFee.toInt();
                    final total =
                        basePrice + deliveryFee + designFee + instructionsFee;

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Service Price',
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: textSecondary)),
                            Text('Rs $basePrice',
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: textPrimary)),
                          ],
                        ),
                        if (isHome) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Fee',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textSecondary)),
                              Text('Rs $deliveryFee',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                        if (designFee > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Design Upload Fee (${ctrl.designImageUrls.length}x)',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textSecondary)),
                              Text('Rs $designFee',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                        if (instructionsFee > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Special Instructions Fee',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: textSecondary)),
                              Text('Rs $instructionsFee',
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                        Divider(height: 20, color: borderColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount',
                                style: AppTextStyles.labelLarge.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700)),
                            Text('Rs $total',
                                style:
                                    AppTextStyles.h4.copyWith(color: primary)),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Info Note ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: primarySoft, borderRadius: AppRadius.medium),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Final price may vary based on design complexity. Artist will confirm after review.',
                      style: AppTextStyles.bodySmall.copyWith(color: primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ─── Payment Method ───────────────────────────────────
            Text('Payment Method',
                style: AppTextStyles.h4.copyWith(color: textPrimary)),
            const SizedBox(height: 4),
            Text('Select how you want to pay',
                style: AppTextStyles.bodySmall.copyWith(color: textSecondary)),
            const SizedBox(height: 14),

            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _PaymentOption(
                        icon: Icons.money_rounded,
                        label: 'Cash',
                        isSelected: ctrl.selectedPaymentMethod.value ==
                            PaymentMethod.wallet,
                        onTap: () => ctrl.selectedPaymentMethod.value =
                            PaymentMethod.wallet,
                        isDark: isDark,
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PaymentOption(
                        icon: Icons.credit_card_rounded,
                        label: 'Card',
                        isSelected: ctrl.selectedPaymentMethod.value ==
                            PaymentMethod.stripe,
                        onTap: () => ctrl.selectedPaymentMethod.value =
                            PaymentMethod.stripe,
                        isDark: isDark,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                )),

            const SizedBox(height: 16),

            Obx(() {
              if (ctrl.selectedPaymentMethod.value != PaymentMethod.wallet) {
                return const SizedBox();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: primarySoft, borderRadius: AppRadius.medium),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cash payment will be collected at the time of service.',
                      style: AppTextStyles.caption.copyWith(color: primary),
                    ),
                  ),
                ]),
              );
            }),

            Obx(() {
              if (ctrl.selectedPaymentMethod.value != PaymentMethod.stripe) {
                return const SizedBox();
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: primarySoft, borderRadius: AppRadius.medium),
                child: Row(children: [
                  const Icon(Icons.credit_card_rounded,
                      color: primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will be redirected to Safepay\'s secure page to pay by debit/credit card.',
                      style: AppTextStyles.caption.copyWith(color: primary),
                    ),
                  ),
                ]),
              );
            }),

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

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return 'Cash on Delivery';
      case PaymentMethod.jazzCash:
        return 'JazzCash';
      case PaymentMethod.easyPaisa:
        return 'EasyPaisa';
      case PaymentMethod.stripe:
        return 'Card';
      case PaymentMethod.debitCard:
        throw UnimplementedError();
      case PaymentMethod.creditCard:
        throw UnimplementedError();
    }
  }
}

// ─── Success Illustration ─────────────────────────────────────────────────────
class _SuccessIllustration extends StatelessWidget {
  final bool isDark;
  const _SuccessIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
        ),
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;
    const primary = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: primarySoft, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: AppTextStyles.labelMedium
                    .copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Divider(height: 1, thickness: 0.8, color: borderColor);
  }
}

// ─── Bottom Buttons ───────────────────────────────────────────────────────────
class _BottomButtons extends StatelessWidget {
  final bool isDark;
  const _BottomButtons({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ctrl = BookingController.to;
    const primary = AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: ctrl.isLoading.value
                      ? null
                      : () {
                          // Guard: don't allow confirming a booking that's
                          // missing service / date / time / (address for
                          // home visits) — createBooking() also checks
                          // this, but validating here gives an instant
                          // error without a network round trip.
                          if (!ctrl.validateBeforeConfirm()) return;
                          ctrl.createBooking();
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.medium)),
                  child: ctrl.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Confirm Booking',
                                style: AppTextStyles.labelLarge
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                ),
              )),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primary),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.medium)),
              child: Text('Go Back',
                  style: AppTextStyles.labelLarge.copyWith(color: primary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _SummaryRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    const primary = AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption.copyWith(color: textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Payment Option ───────────────────────────────────────────────────────────
class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isFullWidth;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor =
        isDark ? AppColors.darkSurface : Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: isFullWidth ? 60 : 90,
        padding: isFullWidth
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.12) : surfaceColor,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Icon(icon,
                      color: isSelected ? primary : textSecondary, size: 24),
                  const SizedBox(width: 12),
                  Text(label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? primary : textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: primary, size: 20),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      color: isSelected ? primary : textSecondary, size: 28),
                  const SizedBox(height: 6),
                  Text(label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? primary : textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center),
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
    final steps = ['Details', 'Address', 'Confirm', 'Done'];
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    const primary = AppColors.primary;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = (i ~/ 2) + 1;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: stepIndex < currentStep ? primary : textSecondary,
            ),
          );
        }
        final stepIndex = i ~/ 2 + 1;
        final isActive = stepIndex <= currentStep;
        final isDone = stepIndex < currentStep;
        // FIX: wrap in Expanded so each step only takes its fair share of
        // the row's width instead of its natural (label-text) width —
        // this is what was causing the RenderFlex overflow on narrow
        // screens/windows.
        return Expanded(
          child: _Step(
            number: stepIndex,
            label: steps[stepIndex - 1],
            isActive: isActive,
            isDone: isDone,
          ),
        );
      }),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;
  const _Step(
      {required this.number,
      required this.label,
      required this.isActive,
      required this.isDone});

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
                color: isActive ? primary : textSecondary, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$number',
                    style: AppTextStyles.labelMedium.copyWith(
                        color: isActive ? Colors.white : textSecondary),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? primary : textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}