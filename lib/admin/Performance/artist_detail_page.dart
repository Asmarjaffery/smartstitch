import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstitch/core/widgets/performance_widgets.dart';
import 'package:smartstitch/admin/Performance/performance_controller.dart';

class ArtistDetailPage extends StatelessWidget {
  final ArtistModel artist;
  const ArtistDetailPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF141414) : theme.colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(
                imageUrl: artist.imageUrl,
                name: artist.name,
                rating: artist.rating,
                isActive: artist.isActive,
                activeLabel: 'Active',
                inactiveLabel: 'Inactive',
                isDark: isDark,
                primary: primary,
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: primary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Performance Overview'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      DetailStatCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Total Orders',
                        value: artist.totalOrders.toString(),
                        color: primary,
                      ),
                      DetailStatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed',
                        value: artist.completedOrders.toString(),
                        color: const Color(0xFF22C55E),
                      ),
                      DetailStatCard(
                        icon: Icons.cancel_outlined,
                        label: 'Cancelled',
                        value: artist.cancelledOrders.toString(),
                        color: const Color(0xFFEF4444),
                      ),
                      DetailStatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Total Earnings',
                        value: 'Rs ${_fmt(artist.totalEarnings)}',
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),

                  if (artist.totalOrders > 0) ...[
                    const SectionHeader(title: 'Completion Rate'),
                    _CompletionRate(
                      completed: artist.completedOrders,
                      cancelled: artist.cancelledOrders,
                      total: artist.totalOrders,
                      primary: primary,
                      isDark: isDark,
                    ),
                  ],

                  const SectionHeader(title: 'Recent Orders'),
                  _RecentOrdersList(artistId: artist.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── HERO HEADER ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double rating;
  final bool isActive;
  final String activeLabel;
  final String inactiveLabel;
  final bool isDark;
  final Color primary;

  const _HeroHeader({
    required this.imageUrl,
    required this.name,
    required this.rating,
    required this.isActive,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF141414), const Color(0xFF1E1E1E)]
              : [
                  primary.withValues(alpha: 0.08),
                  primary.withValues(alpha: 0.03)
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Row(
            children: [
              ProfileAvatar(imageUrl: imageUrl, size: 72),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0A0A0A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StarRating(rating: rating),
                        const SizedBox(width: 8),
                        StatusChip(
                          isActive: isActive,
                          activeLabel: activeLabel,
                          inactiveLabel: inactiveLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── COMPLETION RATE ─────────────────────────────────────────────────────────

class _CompletionRate extends StatelessWidget {
  final int completed;
  final int cancelled;
  final int total;
  final Color primary;
  final bool isDark;

  const _CompletionRate({
    required this.completed,
    required this.cancelled,
    required this.total,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final completedPct = (completed / total).clamp(0.0, 1.0);
    final cancelledPct = (cancelled / total).clamp(0.0, 1.0);
    final other = (1 - completedPct - cancelledPct).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0FBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD8F1F2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendDot(
                color: const Color(0xFF22C55E),
                label: 'Completed',
                value: '${(completedPct * 100).toStringAsFixed(1)}%',
              ),
              _LegendDot(
                color: const Color(0xFFEF4444),
                label: 'Cancelled',
                value: '${(cancelledPct * 100).toStringAsFixed(1)}%',
              ),
              _LegendDot(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFD8F1F2),
                label: 'Other',
                value: '${(other * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Flexible(
                    flex: (completedPct * 100).round(),
                    child: Container(color: const Color(0xFF22C55E)),
                  ),
                  Flexible(
                    flex: (cancelledPct * 100).round(),
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
                  Flexible(
                    flex: (other * 100).round(),
                    child: Container(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFD8F1F2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendDot(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── RECENT ORDERS ────────────────────────────────────────────────────────────
// NOTE: queries the top-level `bookings` collection filtered by artistId,
// matching how performance_controller.dart computes artist stats.
// If your booking documents use different field names than the fallbacks
// below (serviceName / totalAmount), adjust the _OrderTile field lookups.

class _RecentOrdersList extends StatelessWidget {
  final String artistId;
  const _RecentOrdersList({required this.artistId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('artistId', isEqualTo: artistId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No recent orders found.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _OrderTile(data: data);
          }).toList(),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OrderTile({required this.data});

  // Simple in-memory cache so scrolling/rebuilding the list doesn't
  // re-fetch the same customer doc repeatedly.
  static final Map<String, String> _customerNameCache = {};

  static Future<String> _fetchCustomerName(String customerId) async {
    if (customerId.isEmpty) return '';
    if (_customerNameCache.containsKey(customerId)) {
      return _customerNameCache[customerId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      final name = doc.data()?['fullName']?.toString() ??
          doc.data()?['name']?.toString() ??
          '';
      _customerNameCache[customerId] = name;
      return name;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final isCompleted = status == 'completed' || status == 'delivered';
    final isCancelled = status == 'cancelled';

    Color statusColor;
    IconData statusIcon;
    if (isCompleted) {
      statusColor = const Color(0xFF22C55E);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isCancelled) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.schedule_rounded;
    }

    final title = data['serviceTitle']?.toString() ?? 'Order';

    final amount = data['totalAmount'];

    final address = data['address'] as Map<String, dynamic>?;
    final locationLabel = address?['label']?.toString().isNotEmpty == true
        ? address!['label'].toString()
        : address?['city']?.toString();

    final customerId = data['customerId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD8F1F2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                FutureBuilder<String>(
                  future: _fetchCustomerName(customerId),
                  builder: (context, snapshot) {
                    final customerName = snapshot.data;
                    final subtitle = (customerName != null &&
                            customerName.isNotEmpty)
                        ? (locationLabel != null && locationLabel.isNotEmpty
                            ? '$customerName · $locationLabel'
                            : customerName)
                        : (locationLabel ?? '');
                    if (subtitle.isEmpty) return const SizedBox.shrink();
                    return Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                Text(
                  _formatDate(data['createdAt']),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (amount != null)
                Text(
                  'Rs $amount',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatStatus(status),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    // Splits camelCase like "riderAssigned" -> "RIDER ASSIGNED"
    final spaced = status.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return spaced.toUpperCase();
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is String) {
        dt = DateTime.parse(ts);
      } else {
        return '';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}