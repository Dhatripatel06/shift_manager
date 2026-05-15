import 'package:get/get.dart';
import '../data/repositories/shift_repository.dart';
import '../models/shift_model.dart';

/// Data model for chart data points
class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint(this.label, this.value);
}

/// Controller for the Statistics screen.
/// Provides weekly and monthly earning/hours data for chart visualization.
class StatisticsController extends GetxController {
  final ShiftRepository _repository = ShiftRepository();

  // ─── Observable State ──────────────────────────────────────

  /// Weekly earnings chart data
  final RxList<ChartDataPoint> weeklyEarningsData = <ChartDataPoint>[].obs;

  /// Monthly earnings chart data
  final RxList<ChartDataPoint> monthlyEarningsData = <ChartDataPoint>[].obs;

  /// Weekly hours chart data
  final RxList<ChartDataPoint> weeklyHoursData = <ChartDataPoint>[].obs;

  /// Summary values
  final RxDouble totalEarningsAllTime = 0.0.obs;
  final RxDouble totalHoursAllTime = 0.0.obs;
  final RxDouble averagePayPerHour = 0.0.obs;
  final RxDouble averageHoursPerShift = 0.0.obs;
  final RxInt totalShiftsAllTime = 0.obs;

  /// Loading state
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStatistics();
  }

  /// Load all statistics data
  void loadStatistics() {
    isLoading.value = true;

    try {
      final allShifts = _repository.getAllShifts();

      // All-time summary
      totalShiftsAllTime.value = allShifts.length;
      totalEarningsAllTime.value =
          _repository.calculateTotalEarnings(allShifts);
      totalHoursAllTime.value = _repository.calculateTotalHours(allShifts);

      if (allShifts.isNotEmpty) {
        averagePayPerHour.value =
            totalEarningsAllTime.value / totalHoursAllTime.value;
        averageHoursPerShift.value =
            totalHoursAllTime.value / allShifts.length;
      }

      // Weekly earnings (last 7 days)
      _buildWeeklyData(allShifts);

      // Monthly earnings (last 6 months)
      _buildMonthlyData(allShifts);

      // Weekly hours data
      _buildWeeklyHoursData(allShifts);
    } catch (e) {
      // Handle gracefully
    } finally {
      isLoading.value = false;
    }
  }

  /// Build weekly earnings data (Mon-Sun for current week)
  void _buildWeeklyData(List<ShiftModel> allShifts) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final data = <ChartDataPoint>[];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );

      final dayShifts = allShifts.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);

      final earnings =
          dayShifts.fold(0.0, (sum, s) => sum + s.totalPay);

      data.add(ChartDataPoint(dayNames[i], earnings));
    }

    weeklyEarningsData.value = data;
  }

  /// Build monthly earnings data (last 6 months)
  void _buildMonthlyData(List<ShiftModel> allShifts) {
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final data = <ChartDataPoint>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthShifts = allShifts.where((s) =>
          s.date.year == month.year && s.date.month == month.month);

      final earnings =
          monthShifts.fold(0.0, (sum, s) => sum + s.totalPay);

      data.add(ChartDataPoint(monthNames[month.month - 1], earnings));
    }

    monthlyEarningsData.value = data;
  }

  /// Build weekly hours data
  void _buildWeeklyHoursData(List<ShiftModel> allShifts) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final data = <ChartDataPoint>[];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );

      final dayShifts = allShifts.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day);

      final hours =
          dayShifts.fold(0.0, (sum, s) => sum + s.netHours);

      data.add(ChartDataPoint(dayNames[i], hours));
    }

    weeklyHoursData.value = data;
  }
}
