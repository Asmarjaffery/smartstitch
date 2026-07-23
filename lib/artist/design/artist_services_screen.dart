import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/core/widgets/empty_state.dart';
import 'package:smartstitch/core/widgets/service_card.dart';
import 'package:smartstitch/core/widgets/service_search_bar.dart';
import 'package:smartstitch/core/widgets/service_shimmer.dart';

import 'artist_services_controller.dart';

class ArtistServicesScreen extends StatelessWidget {
  ArtistServicesScreen({super.key});
  final ArtistServicesController controller = Get.put(
    ArtistServicesController(),
  );

  // ─── RESPONSIVE HELPERS ───────────────────────────────────────
  // Breakpoints: <600 = mobile, 600-899 = tablet, 900-1199 = small desktop/web,
  // >=1200 = large desktop/web
  int _crossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _childAspectRatio(double width) {
    if (width >= 1200) return 0.72;
    if (width >= 900) return 0.66;
    if (width >= 600) return 0.64;
    return 0.62;
  }

  double _contentMaxWidth(double width) {
    // Cap content width on large screens so cards don't stretch too wide.
    if (width >= 1400) return 1200;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("My Services"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.refreshServices();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // CreateServiceScreen route
          Get.toNamed("/create-service");
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = _crossAxisCount(width);
          final childAspectRatio = _childAspectRatio(width);
          final maxContentWidth = _contentMaxWidth(width);
          final horizontalPadding = width >= 600 ? 24.0 : 16.0;

          return RefreshIndicator(
            onRefresh: controller.refreshServices,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ServiceShimmer();
              }

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 16,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _dashboardStats(context, width),
                            const SizedBox(height: 20),
                            ServiceSearchBar(controller: controller),
                            const SizedBox(height: 16),
                            _filters(),
                            const SizedBox(height: 20),
                          ]),
                        ),
                      ),
                      controller.filteredServices.isEmpty
                          ? const SliverFillRemaining(
                              child: EmptyState(),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                              ),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final service =
                                        controller.filteredServices[index];

                                    return ServiceCard(
                                      service: service,
                                      controller: controller,
                                    );
                                  },
                                  childCount:
                                      controller.filteredServices.length,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                ),
                              ),
                            )
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _dashboardStats(BuildContext context, double width) {
    return Obx(() {
      final stats = [
        _StatData("Total", controller.totalServices.value,
            Icons.design_services),
        _StatData("Published", controller.publishedServices.value,
            Icons.check_circle),
        _StatData("Draft", controller.draftServices.value, Icons.edit_note),
      ];

      // On very narrow screens, wrap stats into two rows instead of
      // squeezing three cards into one row.
      if (width < 340) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: stats
              .map((s) => SizedBox(
                    width: (width - 10) / 2,
                    child: _statCard(s.title, s.count, s.icon),
                  ))
              .toList(),
        );
      }

      return Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i != 0) const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                stats[i].title,
                stats[i].count,
                stats[i].icon,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _statCard(String title, int count, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Obx(() {
      final filters = [
        "All",
        "Published",
        "Draft",
      ];

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((filter) {
          return ChoiceChip(
            label: Text(filter),
            selected: controller.selectedFilter.value ==
                filter.toLowerCase(),
            onSelected: (value) {
              controller.changeFilter(filter.toLowerCase());
            },
          );
        }).toList(),
      );
    });
  }
}

class _StatData {
  final String title;
  final int count;
  final IconData icon;
  _StatData(this.title, this.count, this.icon);
}