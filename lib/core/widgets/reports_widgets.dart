import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartstitch/admin/report/reports_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';


class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SectionCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final shadowColor = isDark ? Colors.black : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.soft(shadowColor),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h4.copyWith(color: textPrimary)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ReportTypeCard extends StatelessWidget {
  final ReportTypeData data;
  final bool isSelected;
  final VoidCallback onTap;

  const ReportTypeCard({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  IconData _iconFromString(String name) {
    switch (name) {
      case 'attach_money':
        return Icons.attach_money_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'people':
        return Icons.people_alt_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'two_wheeler':
        return Icons.two_wheeler_rounded;
      case 'design_services':
        return Icons.design_services_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'report_problem':
        return Icons.report_problem_rounded;
      default:
        return Icons.insert_chart_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgUnselected = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;
    final cardWhite = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textDark = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textGrey = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gradient = isDark ? AppColors.darkGradient : AppColors.primaryGradient;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : bgUnselected,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isSelected ? Colors.transparent : border,
          ),
          boxShadow: isSelected ? AppShadows.medium(AppColors.primary) : [],
        ),
        // mainAxisSize.min + bounded text lines below means this Column's
        // intrinsic height is fixed and predictable — it will never exceed
        // the fixed `mainAxisExtent` the grid gives it (see reports_screen.dart),
        // regardless of screen width, font scaling, or text length.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : cardWhite,
                borderRadius: AppRadius.small,
              ),
              child: Icon(
                _iconFromString(data.icon),
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : textDark,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                height: 1.25,
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const GradientActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.darkGradient : AppColors.primaryGradient;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: AppRadius.medium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppRadius.medium,
          boxShadow: AppShadows.medium(AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class OutlinedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.primary;
    final cardWhite = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: AppRadius.medium,
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: c, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class DateFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DateFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgUnselected = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textGrey = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final gradient = isDark ? AppColors.darkGradient : AppColors.primaryGradient;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.small,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : bgUnselected,
          borderRadius: AppRadius.small,
          border: Border.all(
            color: isSelected ? Colors.transparent : border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : textGrey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class FileTypeBadge extends StatelessWidget {
  final String type;

  const FileTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPdf = type == 'pdf';
    final color = isPdf ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.xs,
      ),
      child: Text(
        isPdf ? 'PDF' : 'EXCEL',
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

class RecentReportsTable extends StatelessWidget {
  final List<RecentReport> reports;
  final void Function(RecentReport) onDownload;

  const RecentReportsTable({
    super.key,
    required this.reports,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy  h:mm a');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this width the fixed-column table itself would overflow
        // horizontally on any phone — switch to a stacked card layout.
        final isNarrow = constraints.maxWidth < 640;
        if (isNarrow) {
          return Column(
            children: reports
                .map((r) => _buildMobileCard(context, r, df))
                .toList(),
          );
        }
        return Column(
          children: [
            _buildHeaderRow(context),
            const SizedBox(height: 8),
            ...reports.map((r) => _buildDataRow(context, r, df)),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.small,
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('Report Name')),
          Expanded(flex: 2, child: _HeaderText('Generated By')),
          Expanded(flex: 2, child: _HeaderText('Generated Date')),
          Expanded(flex: 1, child: _HeaderText('File Size')),
          Expanded(flex: 1, child: _HeaderText('Type')),
          SizedBox(width: 60, child: _HeaderText('Action')),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, RecentReport r, DateFormat df) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWhite = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textDark = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textGrey = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: AppRadius.small,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              r.name,
              style: AppTextStyles.labelMedium.copyWith(fontSize: 13.5, color: textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              r.generatedBy,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              df.format(r.generatedDate),
              style: AppTextStyles.caption.copyWith(fontSize: 12.5, color: textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              r.fileSize,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: textGrey),
            ),
          ),
          Expanded(
            flex: 1,
            child: FileTypeBadge(type: r.fileType),
          ),
          SizedBox(
            width: 60,
            child: IconButton(
              onPressed: () => onDownload(r),
              icon: const Icon(Icons.download_rounded, size: 20),
              color: AppColors.primary,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile fallback: stacked card instead of a fixed-column row ──────────
  Widget _buildMobileCard(BuildContext context, RecentReport r, DateFormat df) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWhite = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textDark = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textGrey = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: AppRadius.small,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: AppTextStyles.labelMedium.copyWith(fontSize: 14, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FileTypeBadge(type: r.fileType),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${r.generatedBy} · ${df.format(r.generatedDate)}',
            style: AppTextStyles.caption.copyWith(fontSize: 12, color: textGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.fileSize,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5, color: textGrey),
              ),
              InkWell(
                onTap: () => onDownload(r),
                borderRadius: AppRadius.small,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.small,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 15, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        'Download',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textGrey = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        fontSize: 12,
        color: textGrey,
        letterSpacing: 0.3,
      ),
    );
  }
}

class PreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const PreviewTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;
    final textDark = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textGrey = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No data available',
            style: AppTextStyles.bodyMedium.copyWith(color: textGrey),
          ),
        ),
      );
    }

    final headers = data.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(bg),
        columns: headers
            .map((h) => DataColumn(
                  label: Text(
                    h,
                    style: AppTextStyles.labelMedium.copyWith(fontSize: 12.5, color: textDark),
                  ),
                ))
            .toList(),
        rows: data
            .map(
              (row) => DataRow(
                cells: headers
                    .map(
                      (h) => DataCell(
                        Text(
                          row[h]?.toString() ?? '',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5, color: textGrey),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}