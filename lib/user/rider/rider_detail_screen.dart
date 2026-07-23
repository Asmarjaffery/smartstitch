import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstitch/user/chat/chat_room_screen.dart';
import '../../controllers/chat_controller.dart';
import '../../core/theme/app.theme.dart';

// ─── Rider Detail Screen ──────────────────────────────────────────────────────
// Artist yahan rider ki profile dekhta hai aur message kar sakta hai

class RiderDetailScreen extends StatelessWidget {
  const RiderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final String riderId = args['riderId'] ?? '';
    final String riderName = args['riderName'] ?? 'Rider';
    final String? riderImage = args['riderImage'];
    final double rating = (args['rating'] ?? 4.8).toDouble();
    final int totalDeliveries = args['totalDeliveries'] ?? 0;
    final String? phoneNumber = args['phoneNumber'];
    final bool isOnline = args['isOnline'] ?? false;
    final String vehicle = args['vehicle'] ?? 'Bike';
    final String area = args['area'] ?? 'Karachi';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ─── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Profile image + online dot
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12)
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: riderImage != null
                                ? NetworkImage(riderImage)
                                : null,
                            child: riderImage == null
                                ? Text(riderName[0].toUpperCase(),
                                    style: AppTextStyles.h1.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(riderName,
                        style: AppTextStyles.h3.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining_rounded,
                            color: Colors.white.withValues(alpha: 0.85), size: 16),
                        const SizedBox(width: 4),
                        Text('$vehicle • $area',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderStat(
                            value: rating.toStringAsFixed(1),
                            label: 'Rating',
                            icon: Icons.star_rounded),
                        _VerticalDivider(),
                        _HeaderStat(
                            value: '$totalDeliveries+',
                            label: 'Deliveries',
                            icon: Icons.local_shipping_rounded),
                        _VerticalDivider(),
                        _HeaderStat(
                            value: isOnline ? 'Online' : 'Offline',
                            label: 'Status',
                            icon: Icons.circle,
                            valueColor: isOnline
                                ? AppColors.success
                                : Colors.white.withValues(alpha: 0.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Body ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Message + Call Buttons ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _openChat(riderId, riderName, riderImage),
                          icon: const Icon(Icons.chat_bubble_rounded,
                              color: Colors.white, size: 20),
                          label: const Text('Message',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: phoneNumber != null
                              ? () => Get.toNamed('/call',
                                  arguments: {'phone': phoneNumber})
                              : null,
                          icon: const Icon(Icons.call_rounded,
                              color: AppColors.primary, size: 20),
                          label: const Text('Call',
                              style: TextStyle(color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Rider Info ─────────────────────────────────────────
                  Text('Rider Info',
                      style: AppTextStyles.h5.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoRow(
                          icon: Icons.delivery_dining_rounded,
                          label: 'Vehicle',
                          value: vehicle),
                      _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Service Area',
                          value: area),
                      _InfoRow(
                          icon: Icons.local_shipping_rounded,
                          label: 'Total Deliveries',
                          value: '$totalDeliveries+'),
                      _InfoRow(
                          icon: Icons.star_rounded,
                          label: 'Rating',
                          value: '${rating.toStringAsFixed(1)} / 5.0'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Reviews ────────────────────────────────────────────
                  Text('Reviews',
                      style: AppTextStyles.h5.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...List.generate(3, (i) => _ReviewTile(index: i)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom Message Button ──────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border:
              const Border(top: BorderSide(color: AppColors.lightBorder, width: 1)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3))
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _openChat(riderId, riderName, riderImage),
            icon: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 22),
            label: const Text('Message Rider',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(
      String riderId, String riderName, String? riderImage) async {
    // FIX: guard empty ID
    if (riderId.isEmpty) {
      Get.snackbar('Error', 'Rider ID nahi mila',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final controller = Get.find<ChatController>();
    await controller.openChat(riderId);
    Get.to(() => ChatRoomScreen(
          otherUserId: riderId,
          roomName: riderName,
          profileImageUrl: riderImage,
        ));
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? valueColor;
  const _HeaderStat(
      {required this.value,
      required this.label,
      required this.icon,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: valueColor ?? Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(value,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: valueColor ?? Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3));
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children:
            children.expand((w) => [w, const Divider(height: 16)]).toList()
              ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.lightTextSecondary)),
        ),
        Text(value,
            style: AppTextStyles.labelMedium
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final int index;
  const _ReviewTile({required this.index});

  static const _names = ['Zara Designs', 'Noor Stitches', 'Hina Couture'];
  static const _reviews = [
    'Delivery time pe aur package safe tha. Bohot professional!',
    'Bahut acha rider hai, hamesha on time aata hai.',
    'Trusted rider, order safely deliver kiya. Recommend karungi!',
  ];
  static const _ratings = [5, 5, 4];
  static const _times = ['3 days ago', '1 week ago', '2 weeks ago'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(_names[index][0],
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_names[index], style: AppTextStyles.labelMedium),
                    Text(_times[index],
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.lightTextHint)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 14,
                      color: i < _ratings[index]
                          ? AppColors.warning
                          : AppColors.lightBorder),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_reviews[index],
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}
