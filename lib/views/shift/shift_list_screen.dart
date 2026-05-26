import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/shift_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/shift_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

/// Shift list screen with filter tabs and search functionality.
class ShiftListScreen extends StatelessWidget {
  const ShiftListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShiftController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Shifts',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${controller.filteredShifts.length} shifts',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Search Bar ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                onChanged: controller.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search by event or role...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: Obx(() {
                    if (controller.searchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.setSearchQuery('');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // ─── Filter Tabs ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ShiftFilter.values.map((filter) {
                      final isActive = controller.currentFilter.value == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_filterLabel(filter)),
                          selected: isActive,
                          onSelected: (_) => controller.setFilter(filter),
                          selectedColor: AppColors.accent.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: AppColors.accent,
                          labelStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? AppColors.accent
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                          ),
                          side: BorderSide(
                            color: isActive
                                ? AppColors.accent.withValues(alpha: 0.3)
                                : (isDark
                                      ? AppColors.primaryLight.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.grey.withValues(alpha: 0.2)),
                          ),
                          backgroundColor: isDark
                              ? AppColors.cardDark
                              : AppColors.cardLight,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ─── Shift List ─────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: LoadingShimmer(itemCount: 4, height: 140),
                  );
                }

                if (controller.filteredShifts.isEmpty) {
                  return EmptyState(
                    icon: Icons.work_off_outlined,
                    title: 'No shifts found',
                    subtitle: controller.searchQuery.value.isNotEmpty
                        ? 'Try a different search term'
                        : 'Start by adding your first shift',
                    actionLabel: 'Add Shift',
                    onAction: () {
                      controller.prepareNew();
                      Get.toNamed(AppRoutes.addShift);
                    },
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: controller.filteredShifts.length,
                  itemBuilder: (context, index) {
                    final shift = controller.filteredShifts[index];
                    return ShiftCard(
                      shift: shift,
                      index: index,
                      onEdit: () {
                        controller.prepareEdit(shift);
                        Get.toNamed(AppRoutes.editShift);
                      },
                      onDelete: () => controller.deleteShift(shift.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'shift-list-add-shift-fab',
        onPressed: () {
          controller.prepareNew();
          Get.toNamed(AppRoutes.addShift);
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  String _filterLabel(ShiftFilter filter) {
    switch (filter) {
      case ShiftFilter.all:
        return 'All';
      case ShiftFilter.daily:
        return 'Today';
      case ShiftFilter.weekly:
        return 'This Week';
      case ShiftFilter.monthly:
        return 'This Month';
    }
  }
}
