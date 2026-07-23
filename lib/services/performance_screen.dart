import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/Performance/artist_detail_page.dart';
import 'package:smartstitch/admin/Performance/performance_controller.dart';
import 'package:smartstitch/admin/Performance/rider_detail_page.dart';
import 'package:smartstitch/core/widgets/performance_widgets.dart';


// ─── PERFORMANCE SCREEN ───────────────────────────────────────────────────────

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PerformanceController());
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _PerformanceAppBar(controller: controller),
          ],
          body: TabBarView(
            children: [
              _ArtistTab(controller: controller),
              _RiderTab(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── APP BAR ─────────────────────────────────────────────────────────────────

class _PerformanceAppBar extends StatefulWidget {
  final PerformanceController controller;
  const _PerformanceAppBar({required this.controller});

  @override
  State<_PerformanceAppBar> createState() => _PerformanceAppBarState();
}

class _PerformanceAppBarState extends State<_PerformanceAppBar> {
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: _searching ? 0 : null,
      backgroundColor: isDark
          ? const Color(0xFF141414)
          : theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
      title: _searching
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontFamily: 'Poppins',
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              onChanged: widget.controller.onSearch,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Performance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Monitor Artist and Rider Performance',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
      centerTitle: false,
      actions: [
        if (_searching)
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              setState(() => _searching = false);
              _searchCtrl.clear();
              widget.controller.onSearch('');
            },
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => setState(() => _searching = true),
            tooltip: 'Search',
          ),
          Obx(() => IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.tune_rounded),
                    if (widget.controller.filterOption.value !=
                        FilterOption.all)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () =>
                    _showFilterBottomSheet(context, widget.controller),
                tooltip: 'Filter & Sort',
              )),
        ],
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF222222)
                    : const Color(0xFFE7F6F7),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.palette_rounded,
                        size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text('Artists'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.electric_moped_rounded,
                        size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text('Riders'),
                  ],
                ),
              ),
            ],
            labelColor: colorScheme.primary,
            unselectedLabelColor: isDark
                ? const Color(0xFF666666)
                : const Color(0xFF8DAFB1),
            indicatorColor: colorScheme.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            dividerColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(
      BuildContext context, PerformanceController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSortSheet(controller: controller),
    );
  }
}

// ─── FILTER / SORT SHEET ─────────────────────────────────────────────────────

class _FilterSortSheet extends StatelessWidget {
  final PerformanceController controller;
  const _FilterSortSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFD8F1F2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Sort By',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SortOption.values.map((opt) {
                  final selected = controller.sortOption.value == opt;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ChoiceChip(
                      label: Text(_sortLabel(opt)),
                      selected: selected,
                      onSelected: (_) => controller.onSortChanged(opt),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : theme.textTheme.bodySmall?.color,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE6F8F8),
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Filter Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FilterOption.values.map((opt) {
                  final selected = controller.filterOption.value == opt;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ChoiceChip(
                      label: Text(_filterLabel(opt)),
                      selected: selected,
                      onSelected: (_) => controller.onFilterChanged(opt),
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : theme.textTheme.bodySmall?.color,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFE6F8F8),
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _sortLabel(SortOption opt) {
    switch (opt) {
      case SortOption.totalOrders:
        return 'Total Orders';
      case SortOption.rating:
        return 'Rating';
      case SortOption.earnings:
        return 'Earnings';
      case SortOption.latest:
        return 'Latest';
    }
  }

  String _filterLabel(FilterOption opt) {
    switch (opt) {
      case FilterOption.all:
        return 'All';
      case FilterOption.active:
        return 'Active';
      case FilterOption.inactive:
        return 'Inactive';
    }
  }
}

// ─── ARTIST TAB ──────────────────────────────────────────────────────────────

class _ArtistTab extends StatelessWidget {
  final PerformanceController controller;
  const _ArtistTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Obx(() {
      if (controller.isLoadingArtists.value) {
        return const PerformanceLoadingState();
      }
      if (controller.hasArtistError.value) {
        return PerformanceErrorState(
          message: controller.artistError.value,
          onRetry: () => controller.onInit(),
        );
      }
      if (controller.filteredArtists.isEmpty) {
        return const PerformanceEmptyState(
          icon: Icons.palette_outlined,
          title: 'No Artists Found',
          subtitle: 'Try adjusting your search or filter settings.',
        );
      }

      final artists = controller.filteredArtists;

      if (isTablet) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: artists.length,
          itemBuilder: (context, i) => ArtistCard(
            artist: artists[i],
            rank: i,
            onTap: () => Get.to(() => ArtistDetailPage(artist: artists[i])),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => ArtistCard(
          artist: artists[i],
          rank: i,
          onTap: () => Get.to(() => ArtistDetailPage(artist: artists[i])),
        ),
      );
    });
  }
}

// ─── RIDER TAB ───────────────────────────────────────────────────────────────

class _RiderTab extends StatelessWidget {
  final PerformanceController controller;
  const _RiderTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Obx(() {
      if (controller.isLoadingRiders.value) {
        return const PerformanceLoadingState();
      }
      if (controller.hasRiderError.value) {
        return PerformanceErrorState(
          message: controller.riderError.value,
          onRetry: () => controller.onInit(),
        );
      }
      if (controller.filteredRiders.isEmpty) {
        return const PerformanceEmptyState(
          icon: Icons.electric_moped_outlined,
          title: 'No Riders Found',
          subtitle: 'Try adjusting your search or filter settings.',
        );
      }

      final riders = controller.filteredRiders;

      if (isTablet) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: riders.length,
          itemBuilder: (context, i) => RiderCard(
            rider: riders[i],
            rank: i,
            onTap: () => Get.to(() => RiderDetailPage(rider: riders[i])),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: riders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => RiderCard(
          rider: riders[i],
          rank: i,
          onTap: () => Get.to(() => RiderDetailPage(rider: riders[i])),
        ),
      );
    });
  }
}