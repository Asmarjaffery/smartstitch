import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/helpers.dart';
import 'package:smartstitch/user/complaint/complaint_controller.dart';
import 'package:smartstitch/user/complaint/complaint_detail_screen.dart';
import 'package:smartstitch/user/complaint/create_complaint_screen.dart';
import 'package:smartstitch/models/complaint_model.dart';

class ComplaintCenterScreen extends StatefulWidget {
  const ComplaintCenterScreen({super.key});

  @override
  State<ComplaintCenterScreen> createState() => _ComplaintCenterScreenState();
}

class _ComplaintCenterScreenState extends State<ComplaintCenterScreen> {
  final controller = Get.put(ComplaintController());
  final RxString _searchQuery = ''.obs;
  final RxString _filterValue = 'All Status'.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = AuthController.to.currentUser.value;
      if (user != null) controller.loadComplaints(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textPrimary   = isDark ? AppColors.darkTextPrimary   : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint      = isDark ? AppColors.darkTextHint      : AppColors.lightTextHint;
    final surfaceColor  = isDark ? AppColors.darkSurface       : AppColors.lightSurface;
    final borderColor   = isDark ? AppColors.darkBorder        : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text(
          "Complaint Center",
          style: AppTextStyles.h4.copyWith(color: textPrimary),
        ),
        centerTitle: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await Get.to(() => const CreateComplaintScreen());
              final user = AuthController.to.currentUser.value;
              if (user != null) controller.loadComplaints(user.id);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Create Complaint"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              textStyle: AppTextStyles.labelMedium,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Raise a complaint or track the status of your existing complaints.",
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _searchBar(isDark, textPrimary, textHint, surfaceColor, borderColor)),
                const SizedBox(width: 10),
                _filterDropdown(isDark, textPrimary, textSecondary, surfaceColor, borderColor),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query  = _searchQuery.value.toLowerCase();
                final filter = _filterValue.value;

                final list = controller.complaints.where((c) {
                  final matchSearch = query.isEmpty ||
                      c.id.toLowerCase().contains(query) ||
                      c.description.toLowerCase().contains(query) ||
                      (c.issueType?.toLowerCase().contains(query) ?? false) ||
                      (c.orderId?.toString().contains(query) ?? false);

                  final matchFilter = filter == 'All Status' ||
                      (filter == 'Pending'     && c.status.name == 'pending') ||
                      (filter == 'In Progress' && c.status.name == 'inProgress') ||
                      (filter == 'Resolved'    && c.status.name == 'resolved');

                  return matchSearch && matchFilter;
                }).toList();

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      "No complaints found",
                      style: AppTextStyles.bodyMedium.copyWith(color: textHint),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _complaintCard(
                    list[i], isDark, textPrimary, textSecondary, textHint, surfaceColor, borderColor,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ───────────────────────────────────────────
  Widget _searchBar(bool isDark, Color textPrimary, Color textHint,
      Color surfaceColor, Color borderColor) {
    return TextField(
      onChanged: (val) => _searchQuery.value = val,
      style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
      decoration: InputDecoration(
        hintText: "Search complaints...",
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textHint),
        prefixIcon: Icon(Icons.search, color: textHint),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── FILTER DROPDOWN ──────────────────────────────────────
  Widget _filterDropdown(bool isDark, Color textPrimary, Color textSecondary,
      Color surfaceColor, Color borderColor) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.medium,
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterValue.value,
              dropdownColor: surfaceColor,
              style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
              icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
              items: ["All Status", "Pending", "In Progress", "Resolved"]
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: AppTextStyles.bodyMedium.copyWith(color: textPrimary)),
                      ))
                  .toList(),
              onChanged: (val) => _filterValue.value = val ?? 'All Status',
            ),
          ),
        ));
  }

  // ── COMPLAINT CARD ───────────────────────────────────────
  Widget _complaintCard(
    ComplaintModel c,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textHint,
    Color surfaceColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () => Get.to(() => ComplaintDetailScreen(complaint: c)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadius.medium,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "#${c.id.substring(0, 6).toUpperCase()}",
                  style: AppTextStyles.h5.copyWith(color: textPrimary),
                ),
                Row(
                  children: [
                    _statusChip(c.status.name),
                    const SizedBox(width: 10),
                    Text(
                      c.submittedAt.toString().split(" ")[0],
                      style: AppTextStyles.bodySmall.copyWith(color: textHint),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (c.orderId != null)
              Text(
                "Order ID: ${c.orderId}    Artist: ${c.subject.isNotEmpty ? c.subject : '—'}",
                style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
              ),
            const SizedBox(height: 4),
            Text(
              "Issue: ${c.issueType ?? c.description}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _outlineButton(
                  label: "View Details",
                  textPrimary: textPrimary,
                  borderColor: borderColor,
                  onTap: () => Get.to(() => ComplaintDetailScreen(complaint: c)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: surfaceColor,
                        title: Text("Delete Complaint",
                            style: AppTextStyles.h5.copyWith(color: textPrimary)),
                        content: Text(
                          "Are you sure you want to delete this complaint?",
                          style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: Text("Cancel",
                                style: TextStyle(color: textSecondary)),
                          ),
                          ElevatedButton(
                            onPressed: () => Get.back(result: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final success = await controller.deleteComplaint(c.id);
                      if (success) {
                        AppHelpers.showSuccess("Complaint deleted");
                      } else {
                        AppHelpers.showError("Failed to delete");
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  label: Text(
                    "Delete",
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color textPrimary,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        textStyle: AppTextStyles.labelMedium,
      ),
      child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: textPrimary)),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case "pending":    color = AppColors.warning; label = "Pending";     break;
      case "inProgress": color = AppColors.info;    label = "In Progress"; break;
      case "resolved":   color = AppColors.success; label = "Resolved";    break;
      default:           color = AppColors.info;    label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }
}