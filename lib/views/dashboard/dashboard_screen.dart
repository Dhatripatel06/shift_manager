import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/earning_card.dart';
import '../../widgets/clock_widget.dart';
import '../../widgets/shift_card.dart';
import '../../widgets/sync_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

/// Dashboard screen showing summary stats, live clocks, and recent shifts.
/// Clean modern blue & white design for Shiftly
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashCtrl = Get.find<DashboardController>();
    final shiftCtrl = Get.find<ShiftController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            dashCtrl.loadDashboardData();
            shiftCtrl.loadShifts();
          },
          color: primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ─── Header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome 👋', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(dashCtrl.userName, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      ]),
                      const SyncIndicator(),
                    ]),
                    const SizedBox(height: 8),
                    Text(AppConstants.appSubtitle, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor, letterSpacing: 1)),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ─── Live Clocks ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(children: [
                    Expanded(child: ClockWidget(flag: '🇮🇳', label: 'India Time', time: dashCtrl.indiaTime)),
                    const SizedBox(width: 12),
                    Expanded(child: ClockWidget(flag: '🇬🇧', label: 'London Time', time: dashCtrl.londonTime)),
                  ]),
                ),
              ),

              // ─── Earnings Grid ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Obx(() {
                    if (dashCtrl.isLoading.value) {
                      return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05, children: List.generate(4, (_) => const ShimmerStatCard()));
                    }
                    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05, children: [
                      EarningCard(title: 'Weekly Earnings', value: Formatters.formatCurrency(dashCtrl.weeklyEarnings.value), icon: Icons.payments_outlined, iconColor: AppColors.chartGreen, index: 0),
                      EarningCard(title: 'Monthly Earnings', value: Formatters.formatCurrency(dashCtrl.monthlyEarnings.value), icon: Icons.account_balance_wallet_outlined, iconColor: AppColors.primary, index: 1),
                      EarningCard(title: 'Hours This Week', value: Formatters.formatHoursMinutes(dashCtrl.totalHoursThisWeek.value), icon: Icons.schedule_outlined, iconColor: AppColors.chartBlue, index: 2),
                      EarningCard(title: 'Total Shifts', value: dashCtrl.totalShiftCount.value.toString(), icon: Icons.work_outline_rounded, iconColor: AppColors.chartPurple, index: 3),
                    ]);
                  }),
                ),
              ),

              // ─── Recent Shifts Header ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Recent Shifts', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text('View All', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor)),
                  ]),
                ),
              ),

              // ─── Recent Shifts List ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Obx(() {
                    if (dashCtrl.isLoading.value) return const LoadingShimmer(itemCount: 2, height: 140);
                    if (dashCtrl.recentShifts.isEmpty) return const EmptyState(icon: Icons.work_off_outlined, title: 'No shifts yet', subtitle: 'Start tracking your shifts by tapping the + button');
                    return Column(children: dashCtrl.recentShifts.asMap().entries.map((entry) {
                      return ShiftCard(
                        shift: entry.value, index: entry.key,
                        onEdit: () { shiftCtrl.prepareEdit(entry.value); Get.toNamed(AppRoutes.editShift); },
                        onDelete: () => shiftCtrl.deleteShift(entry.value.id),
                      );
                    }).toList());
                  }),
                ),
              ),

              // ─── Motivational Section ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor.withValues(alpha: 0.08), primaryColor.withValues(alpha: 0.03)]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(children: [
                      const Text('🙏', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(AppConstants.motivationalQuote, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor, fontStyle: FontStyle.italic, height: 1.5)),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { shiftCtrl.prepareNew(); Get.toNamed(AppRoutes.addShift); },
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Shift', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
        elevation: 4,
      ),
    );
  }
}
