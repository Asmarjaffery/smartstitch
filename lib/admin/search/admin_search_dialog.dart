import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'admin_search_controller.dart';

/// Global search dialog for the admin panel. Searches users, orders, and
/// services at once, and jumps to the relevant tab in [AdminMainScreen]
/// when a result is tapped.
class AdminSearchDialog extends StatelessWidget {
  const AdminSearchDialog({super.key, required this.onSelectTab});

  /// Called with the tab index to switch to when a result is selected.
  final ValueChanged<int> onSelectTab;

  // Must match the tab order in AdminMainScreen._navItems / _pages.
  static const _tabForCategory = {
    'user': 6, // Users
    'order': 3, // Orders
    'service': 2, // Services
  };

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AdminSearchController());
    final search = AdminSearchController.to;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 90, left: 24, right: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                autofocus: true,
                onChanged: search.onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search users, orders, services…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                  border: OutlineInputBorder(borderRadius: AppRadius.medium),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Obx(() {
                  if (search.query.value.trim().isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Start typing to search')),
                    );
                  }

                  if (search.isSearching.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final hasResults = search.userResults.isNotEmpty ||
                      search.orderResults.isNotEmpty ||
                      search.serviceResults.isNotEmpty;

                  if (!hasResults) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No results found')),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    children: [
                      if (search.userResults.isNotEmpty)
                        _ResultSection(
                          title: 'Users',
                          results: search.userResults,
                          onTap: _select,
                        ),
                      if (search.orderResults.isNotEmpty)
                        _ResultSection(
                          title: 'Orders',
                          results: search.orderResults,
                          onTap: _select,
                        ),
                      if (search.serviceResults.isNotEmpty)
                        _ResultSection(
                          title: 'Services',
                          results: search.serviceResults,
                          onTap: _select,
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(AdminSearchResult r) {
    final tab = _tabForCategory[r.category];
    Get.back();
    if (tab != null) onSelectTab(tab);
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.results,
    required this.onTap,
  });

  final String title;
  final List<AdminSearchResult> results;
  final ValueChanged<AdminSearchResult> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.lightTextSecondary),
          ),
        ),
        ...results.map(
          (r) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(r.title),
            subtitle: r.subtitle.isNotEmpty ? Text(r.subtitle) : null,
            onTap: () => onTap(r),
          ),
        ),
      ],
    );
  }
}
