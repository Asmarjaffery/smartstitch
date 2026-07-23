import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/artist/design/design_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class ServicePublishSuccessScreen extends StatefulWidget {
  final String tag;

  const ServicePublishSuccessScreen({
    super.key,
    required this.tag,
  });

  @override
  State<ServicePublishSuccessScreen> createState() =>
      _ServicePublishSuccessScreenState();
}

class _ServicePublishSuccessScreenState
    extends State<ServicePublishSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ─── SUCCESS CHECKMARK ANIMATION ────────────────────────
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── TITLE ──────────────────────────────────────────────
              Text(
                'Service Published Successfully 🎉',
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // ─── SUBTITLE ───────────────────────────────────────────
              Text(
                'Your tailoring service is now live.\nCustomers can discover and book your service.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // ─── SERVICE DETAILS CARD ───────────────────────────────
              _buildDetailsCard(isDark),
              const SizedBox(height: 24),

              // ─── SUCCESS TIPS CARD ──────────────────────────────────
              _buildTipsCard(isDark),
              const SizedBox(height: 32),

              // ─── ACTION BUTTONS ─────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  // Navigate to My Services
                  Get.offAllNamed('/artist/my-services');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('View My Services'),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  // Reset and create new service
                  Get.find<ServiceController>(tag: widget.tag).resetForNewService();
                  Get.offNamedUntil(
                    '/artist/create-service',
                    (route) => route.isFirst,
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Another Service'),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Get.offAllNamed('/artist/dashboard');
                },
                child: const Text('Go to Dashboard'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    final controller = Get.find<ServiceController>(tag: widget.tag);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            label: 'Service Name',
            value: controller.serviceNameController.text.trim().isEmpty
                ? 'Untitled Service'
                : controller.serviceNameController.text.trim(),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Category',
            value: controller.artistCategory.value,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Starting Price',
            value: 'Rs. ${controller.startingPriceController.text.isEmpty ? '0' : controller.startingPriceController.text}',
            isDark: isDark,
            isHighlight: true,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Delivery Days',
            value: '${controller.deliveryDaysController.text.isEmpty ? '-' : controller.deliveryDaysController.text} days',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Tips to Get More Bookings',
            style: AppTextStyles.labelLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem('Respond quickly to customer inquiries', isDark),
          _buildTipItem('Keep your portfolio updated', isDark),
          _buildTipItem('Deliver services on time', isDark),
          _buildTipItem('Maintain high ratings & reviews', isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: isHighlight
                ? AppColors.primary
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF22C55E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}