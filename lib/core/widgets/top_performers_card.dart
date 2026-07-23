import 'package:flutter/material.dart';
import 'package:smartstitch/models/top_performer_entry.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/glass_card.dart';

class TopPerformersCard extends StatelessWidget {
  final String title;
  final List<TopPerformerEntry> entries;
  final IconData icon;

  const TopPerformersCard({
    Key? key,
    required this.title,
    required this.entries,
    required this.icon,
  }) : super(key: key);

  Gradient? _medalGradient(int rank) {
    switch (rank) {
      case 0:
        return AppColors.goldGradient;
      case 1:
        return AppColors.silverGradient;
      case 2:
        return AppColors.bronzeGradient;
      default:
        return null;
    }
  }

  String? _medalEmoji(int rank) {
    switch (rank) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 19),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.sectionTitle.copyWith(color: textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No performers in this period',
                  style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = entries[idx];
                final medalGradient = _medalGradient(idx);
                final medal = _medalEmoji(idx);
                // Rank-derived ratio for the progress bar — avoids depending on a
                // `revenue` field that may not exist on TopPerformerEntry.
                final ratio = entries.length <= 1 ? 1.0 : (entries.length - idx) / entries.length;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.medium,
                    gradient: medalGradient != null
                        ? LinearGradient(
                            colors: [
                              (medalGradient.colors.first).withValues(alpha: isDark ? 0.14 : 0.10),
                              Colors.transparent,
                            ],
                          )
                        : null,
                    color: medalGradient == null ? (isDark ? AppColors.darkSurface2 : AppColors.lightSurface2) : null,
                    border: Border.all(
                      color: medalGradient != null
                          ? (medalGradient.colors.first).withValues(alpha: 0.35)
                          : AppColors.glassBorder(isDark),
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: medalGradient ?? AppColors.tealGlow,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                              backgroundImage: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                  ? NetworkImage(item.imageUrl!)
                                  : null,
                              child: item.imageUrl == null || item.imageUrl!.isEmpty
                                  ? Text(
                                      item.name.isNotEmpty ? item.name[0].toUpperCase() : 'U',
                                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                    )
                                  : null,
                            ),
                          ),
                          if (medal != null)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Text(medal, style: const TextStyle(fontSize: 14)),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: AppTextStyles.labelLarge.copyWith(color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '#${idx + 1}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: medalGradient != null ? medalGradient.colors.first : textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: AppTextStyles.caption.copyWith(color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: ratio),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, t, _) => LinearProgressIndicator(
                                  value: t,
                                  minHeight: 5,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    medalGradient != null ? medalGradient.colors.first : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}