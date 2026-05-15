import 'dart:async';
import 'package:get/get.dart';
import '../data/repositories/shift_repository.dart';
import '../models/shift_model.dart';

/// Controller for the Dashboard screen.
/// Manages summary statistics, live clocks, and recent shifts.
class DashboardController extends GetxController {
  final ShiftRepository _repository = ShiftRepository();

  // ─── Observable State ──────────────────────────────────────

  /// Earning summaries
  final RxDouble weeklyEarnings = 0.0.obs;
  final RxDouble monthlyEarnings = 0.0.obs;
  final RxDouble totalHoursThisWeek = 0.0.obs;
  final RxDouble totalHoursThisMonth = 0.0.obs;
  final RxInt weeklyShiftCount = 0.obs;
  final RxInt monthlyShiftCount = 0.obs;
  final RxInt totalShiftCount = 0.obs;

  /// Recent shifts
  final RxList<ShiftModel> recentShifts = <ShiftModel>[].obs;

  /// Live clocks
  final Rx<DateTime> indiaTime = DateTime.now().obs;
  final Rx<DateTime> londonTime = DateTime.now().obs;

  /// Loading state
  final RxBool isLoading = true.obs;

  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    _startClocks();
  }

  /// Load all dashboard data
  void loadDashboardData() {
    isLoading.value = true;

    try {
      // Weekly stats
      final weekShifts = _repository.getThisWeekShifts();
      weeklyEarnings.value = _repository.calculateTotalEarnings(weekShifts);
      totalHoursThisWeek.value = _repository.calculateTotalHours(weekShifts);
      weeklyShiftCount.value = weekShifts.length;

      // Monthly stats
      final monthShifts = _repository.getThisMonthShifts();
      monthlyEarnings.value = _repository.calculateTotalEarnings(monthShifts);
      totalHoursThisMonth.value = _repository.calculateTotalHours(monthShifts);
      monthlyShiftCount.value = monthShifts.length;

      // Total shifts
      totalShiftCount.value = _repository.getAllShifts().length;

      // Recent shifts (last 5)
      final allShifts = _repository.getAllShifts();
      recentShifts.value =
          allShifts.take(5).toList();
    } catch (e) {
      // Handle gracefully
    } finally {
      isLoading.value = false;
    }
  }

  /// Start live clocks for India and London
  void _startClocks() {
    _updateClocks();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClocks();
    });
  }

  /// Update clock times
  void _updateClocks() {
    final now = DateTime.now().toUtc();

    // India: UTC+5:30
    indiaTime.value = now.add(const Duration(hours: 5, minutes: 30));

    // London: UTC+0 (or UTC+1 during BST)
    // BST: Last Sunday of March to last Sunday of October
    final isBST = _isBritishSummerTime(now);
    londonTime.value = isBST
        ? now.add(const Duration(hours: 1))
        : now;
  }

  /// Check if current date falls in British Summer Time
  bool _isBritishSummerTime(DateTime utcNow) {
    // BST starts last Sunday of March, ends last Sunday of October
    final year = utcNow.year;

    // Find last Sunday of March
    final marchEnd = DateTime.utc(year, 3, 31);
    final bstStart = marchEnd.subtract(
      Duration(days: marchEnd.weekday % 7),
    );

    // Find last Sunday of October
    final octEnd = DateTime.utc(year, 10, 31);
    final bstEnd = octEnd.subtract(
      Duration(days: octEnd.weekday % 7),
    );

    return utcNow.isAfter(bstStart) && utcNow.isBefore(bstEnd);
  }

  /// Refresh dashboard data
  void refreshData() {
    loadDashboardData();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }
}
