import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/statistics_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_shimmer.dart';

/// Statistics screen with animated charts for earnings and hours.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    StatisticsController controller;
    try {
      controller = Get.find<StatisticsController>();
    } catch (_) {
      controller = Get.put(StatisticsController());
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.primaryDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: LoadingShimmer(itemCount: 3, height: 200),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ──────────────────────────────
                Text(
                  'Statistics',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your performance at a glance',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Summary Cards ───────────────────────
                _buildSummaryRow(controller, isDark),
                const SizedBox(height: 24),

                // ─── Weekly Earnings Chart ───────────────
                _buildChartCard(
                  title: 'Weekly Earnings',
                  subtitle: 'This week\'s daily earnings',
                  isDark: isDark,
                  child: _buildBarChart(
                    controller.weeklyEarningsData,
                    AppColors.accent,
                    isDark,
                    isCurrency: true,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Monthly Earnings Chart ──────────────
                _buildChartCard(
                  title: 'Monthly Earnings',
                  subtitle: 'Last 6 months earnings trend',
                  isDark: isDark,
                  child: _buildBarChart(
                    controller.monthlyEarningsData,
                    AppColors.chartGreen,
                    isDark,
                    isCurrency: true,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Weekly Hours Chart ──────────────────
                _buildChartCard(
                  title: 'Hours Worked',
                  subtitle: 'This week\'s daily hours',
                  isDark: isDark,
                  child: _buildBarChart(
                    controller.weeklyHoursData,
                    AppColors.chartBlue,
                    isDark,
                    isCurrency: false,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Summary Row ─────────────────────────────────────────

  Widget _buildSummaryRow(StatisticsController controller, bool isDark) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                'Total Earnings',
                Formatters.formatCurrency(
                    controller.totalEarningsAllTime.value),
                AppColors.accent,
                isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                'Total Hours',
                Formatters.formatHoursMinutes(
                    controller.totalHoursAllTime.value),
                AppColors.chartBlue,
                isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                'Avg/Shift',
                Formatters.formatHoursMinutes(
                    controller.averageHoursPerShift.value),
                AppColors.chartPurple,
                isDark,
              ),
            ),
          ],
        ));
  }

  Widget _buildMiniStat(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Chart Card ──────────────────────────────────────────

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primaryLight.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Bar Chart ───────────────────────────────────────────

  Widget _buildBarChart(
    List<ChartDataPoint> data,
    Color barColor,
    bool isDark, {
    bool isCurrency = false,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.outfit(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    final maxY = data.fold(0.0, (max, d) => d.value > max ? d.value : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY * 1.2 : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = data[group.x.toInt()].label;
              final value = isCurrency
                  ? Formatters.formatCurrency(rod.toY)
                  : '${rod.toY.toStringAsFixed(1)}h';
              return BarTooltipItem(
                '$label\n$value',
                GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: barColor,
                width: data.length <= 7 ? 20 : 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY > 0 ? maxY * 1.2 : 100,
                  color: barColor.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }
}
