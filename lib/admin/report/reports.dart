import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/report/reports_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/widgets/reports_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
     final controller = Get.isRegistered<ReportsController>()
      ? Get.find<ReportsController>()
      : Get.put(ReportsController());
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(context),
              const SizedBox(height: 24),
              _buildGenerateReportSection(controller, isMobile, isTablet),
              const SizedBox(height: 24),
              Obx(() => controller.isPreviewVisible.value
                  ? Column(
                      children: [
                        _buildPreviewSection(controller),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox.shrink()),
              _buildRecentReportsSection(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        isDark ? AppColors.darkGradient : AppColors.primaryGradient;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(
                  'Reports',
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Generate, preview and export business reports',
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateReportSection(
      ReportsController controller, bool isMobile, bool isTablet) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Generate Reports',
            subtitle: 'Select a report type and date range to generate',
          ),
          const SizedBox(height: 20),
          _buildReportTypeGrid(controller, isMobile, isTablet),
          const SizedBox(height: 24),
          _buildDateFilters(controller),
          const SizedBox(height: 24),
          _buildActionButtons(controller, isMobile),
        ],
      ),
    );
  }

  /// FIXED: observable is now read directly inside the Obx builder
  /// (not lazily inside GridView's itemBuilder), so GetX can track it.
  Widget _buildReportTypeGrid(
      ReportsController controller, bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 5);

    return Obx(
      () {
        final selectedType =
            controller.selectedReportType.value; // tracked here

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.reportTypes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio:
                isMobile ? 0.92 : 1.0, // was 1.15 : 1.05 — taller cells
          ),
          itemBuilder: (context, index) {
            final data = controller.reportTypes[index];
            return ReportTypeCard(
              data: data,
              isSelected: selectedType == data.type,
              onTap: () => controller.selectReportType(data.type),
            );
          },
        );
      },
    );
  }

  Widget _buildDateFilters(ReportsController controller) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textDark =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: AppTextStyles.labelLarge
                  .copyWith(fontSize: 13, color: textDark),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  DateFilterChip(
                    label: 'Today',
                    isSelected:
                        controller.selectedDateFilter.value == DateFilter.today,
                    onTap: () => controller.selectDateFilter(DateFilter.today),
                  ),
                  DateFilterChip(
                    label: 'Last 7 Days',
                    isSelected:
                        controller.selectedDateFilter.value == DateFilter.last7,
                    onTap: () => controller.selectDateFilter(DateFilter.last7),
                  ),
                  DateFilterChip(
                    label: 'Last 30 Days',
                    isSelected: controller.selectedDateFilter.value ==
                        DateFilter.last30,
                    onTap: () => controller.selectDateFilter(DateFilter.last30),
                  ),
                  DateFilterChip(
                    label:
                        controller.selectedDateFilter.value == DateFilter.custom
                            ? controller.dateRangeLabel
                            : 'Custom Date Range',
                    isSelected: controller.selectedDateFilter.value ==
                        DateFilter.custom,
                    onTap: () => _showCustomDatePicker(controller),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCustomDatePicker(ReportsController controller) async {
    final context = Get.context!;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.lightSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      controller.setCustomDateRange(
        DateTimeRange(start: range.start, end: range.end),
      );
    }
  }

  Widget _buildActionButtons(ReportsController controller, bool isMobile) {
    return Obx(
      () => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          GradientActionButton(
            label: 'Generate Report',
            icon: Icons.auto_graph_rounded,
            isLoading: controller.isGenerating.value,
            onTap: controller.generateReport,
          ),
          OutlinedActionButton(
            label: 'Preview',
            icon: Icons.visibility_outlined,
            onTap: controller.previewReport,
          ),
          OutlinedActionButton(
            label: 'Download PDF',
            icon: Icons.picture_as_pdf_outlined,
            color: AppColors.error,
            onTap: controller.downloadPdf,
          ),
          OutlinedActionButton(
            label: 'Download Excel',
            icon: Icons.table_chart_outlined,
            color: AppColors.success,
            onTap: controller.downloadExcel,
          ),
          OutlinedActionButton(
            label: 'Print',
            icon: Icons.print_outlined,
            onTap: controller.printReport,
          ),
          OutlinedActionButton(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            onTap: controller.shareReport,
          ),
        ],
      ),
    );
  }

 Widget _buildPreviewSection(ReportsController controller) {
  return Builder(
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      final textGrey =
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => SectionTitle(
                title: controller.currentReportData?.title ?? 'Report Preview',
                subtitle: 'Date Range: ${controller.dateRangeLabel}',
                trailing: IconButton(
                  onPressed: () => controller.isPreviewVisible.value = false,
                  icon: const Icon(Icons.close_rounded),
                  color: textGrey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: border),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: controller.previewData,
              builder: (context, data, _) => PreviewTable(data: data),
            ),
          ],
        ),
      );
    },
  );
}

  /// FIXED: Access .value on RxList to enable proper GetX observable tracking
  Widget _buildRecentReportsSection(ReportsController controller) {
  return SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Recent Reports',
          subtitle: 'Previously generated reports',
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<List<RecentReport>>(
          valueListenable: controller.recentReports,
          builder: (context, reports, _) => RecentReportsTable(
            reports: reports,
            onDownload: controller.downloadFromRecent,
          ),
        ),
      ],
    ),
  );
}
}