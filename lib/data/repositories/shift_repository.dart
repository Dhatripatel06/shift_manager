import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../models/shift_model.dart';
import '../providers/hive_provider.dart';
import '../../services/sync_service.dart';

/// Repository pattern implementation for shift data operations.
/// Abstracts data source details from the business logic layer.
/// Always saves to Hive first (offline-first), then triggers Firestore sync.
class ShiftRepository {
  final HiveProvider _hiveProvider = Get.find<HiveProvider>();
  final _uuid = const Uuid();

  /// Get sync service (lazy to avoid circular dependency)
  SyncService get _syncService => Get.find<SyncService>();

  /// Create a new shift
  Future<ShiftModel> createShift({
    required DateTime date,
    required String eventName,
    required String jobRole,
    required String startTime,
    required String endTime,
    required double breakHours,
    required double payPerHour,
    String? notes,
  }) async {
    // Calculate derived values
    final netHours =
        ShiftModel.calculateNetHours(startTime, endTime, breakHours);
    final totalPay = ShiftModel.calculateTotalPay(netHours, payPerHour);
    final now = DateTime.now();

    final shift = ShiftModel(
      id: _uuid.v4(),
      date: date,
      eventName: eventName,
      jobRole: jobRole,
      startTime: startTime,
      endTime: endTime,
      breakHours: breakHours,
      netHours: netHours,
      payPerHour: payPerHour,
      totalPay: totalPay,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    // 1. Save locally first (offline-first)
    await _hiveProvider.saveShift(shift);

    // 2. Trigger cloud sync (non-blocking)
    _syncService.syncShift(shift);

    return shift;
  }

  /// Update an existing shift
  Future<ShiftModel> updateShift({
    required String id,
    required DateTime date,
    required String eventName,
    required String jobRole,
    required String startTime,
    required String endTime,
    required double breakHours,
    required double payPerHour,
    String? notes,
  }) async {
    final existing = _hiveProvider.getShift(id);
    if (existing == null) throw Exception('Shift not found');

    final netHours =
        ShiftModel.calculateNetHours(startTime, endTime, breakHours);
    final totalPay = ShiftModel.calculateTotalPay(netHours, payPerHour);

    final updatedShift = existing.copyWith(
      date: date,
      eventName: eventName,
      jobRole: jobRole,
      startTime: startTime,
      endTime: endTime,
      breakHours: breakHours,
      netHours: netHours,
      payPerHour: payPerHour,
      totalPay: totalPay,
      notes: notes,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    // 1. Save locally first
    await _hiveProvider.saveShift(updatedShift);

    // 2. Trigger cloud sync
    _syncService.syncShift(updatedShift);

    return updatedShift;
  }

  /// Delete a shift (soft delete)
  Future<void> deleteShift(String id) async {
    // 1. Soft delete locally first
    await _hiveProvider.softDeleteShift(id);

    // 2. Sync deletion to cloud
    final shift = _hiveProvider.getShift(id);
    if (shift != null) {
      _syncService.syncShift(shift);
    }
  }

  /// Get all shifts
  List<ShiftModel> getAllShifts() => _hiveProvider.getAllShifts();

  /// Get shifts for today
  List<ShiftModel> getTodayShifts() => _hiveProvider.getTodayShifts();

  /// Get shifts for this week
  List<ShiftModel> getThisWeekShifts() => _hiveProvider.getThisWeekShifts();

  /// Get shifts for this month
  List<ShiftModel> getThisMonthShifts() => _hiveProvider.getThisMonthShifts();

  /// Get shifts by date range
  List<ShiftModel> getShiftsByDateRange(DateTime start, DateTime end) =>
      _hiveProvider.getShiftsByDateRange(start, end);

  /// Search shifts
  List<ShiftModel> searchShifts(String query) =>
      _hiveProvider.searchShifts(query);

  /// Get shift by ID
  ShiftModel? getShift(String id) => _hiveProvider.getShift(id);

  /// Calculate total earnings from a list of shifts
  double calculateTotalEarnings(List<ShiftModel> shifts) {
    return shifts.fold(0.0, (sum, shift) => sum + shift.totalPay);
  }

  /// Calculate total hours from a list of shifts
  double calculateTotalHours(List<ShiftModel> shifts) {
    return shifts.fold(0.0, (sum, shift) => sum + shift.netHours);
  }
}
