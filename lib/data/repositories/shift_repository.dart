import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/app_exception.dart';
import '../../models/shift_model.dart';
import '../providers/hive_provider.dart';
import '../../services/sync_service.dart';
import '../../services/auth_service.dart';
import '../../domain/repositories/shift_repository_contract.dart';

/// Repository pattern implementation for shift data operations.
/// Abstracts data source details from the business logic layer.
/// Always saves to Hive first (offline-first), then triggers Firebase RTDB sync.
class LocalShiftRepository implements IShiftRepository {
  final HiveProvider _hiveProvider = Get.find<HiveProvider>();
  final _uuid = const Uuid();

  /// Get sync service (lazy to avoid circular dependency)
  SyncService get _syncService => Get.find<SyncService>();

  /// Get auth service
  AuthService get _auth => Get.find<AuthService>();

  /// Create a new shift
  @override
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
    final userId = _requireUserId();

    // Calculate derived values
    final netHours = ShiftModel.calculateNetHours(
      startTime,
      endTime,
      breakHours,
    );
    final totalPay = ShiftModel.calculateTotalPay(netHours, payPerHour);
    final now = DateTime.now();

    final shift = ShiftModel(
      id: _uuid.v4(),
      userId: userId,
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
    debugPrint(
      '[ShiftRepository] Shift created locally for user ${shift.userId}: ${shift.id}',
    );

    // 2. Trigger cloud sync (non-blocking)
    _syncService.syncShift(shift);

    return shift;
  }

  /// Update an existing shift
  @override
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
    final userId = _requireUserId();
    final existing = _hiveProvider.getShift(id);
    if (existing == null) throw Exception('Shift not found');
    _assertOwnsShift(existing, userId);

    final netHours = ShiftModel.calculateNetHours(
      startTime,
      endTime,
      breakHours,
    );
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
      userId: existing.userId.isEmpty ? userId : existing.userId,
    );

    // 1. Save locally first
    await _hiveProvider.saveShift(updatedShift);
    debugPrint('[ShiftRepository] Shift updated locally: ${updatedShift.id}');

    // 2. Trigger cloud sync
    _syncService.syncShift(updatedShift);

    return updatedShift;
  }

  /// Delete a shift (soft delete)
  @override
  Future<void> deleteShift(String id) async {
    final userId = _requireUserId();
    final existing = _hiveProvider.getShift(id);
    if (existing == null) return;
    _assertOwnsShift(existing, userId);

    // 1. Soft delete locally first
    await _hiveProvider.softDeleteShift(id);
    debugPrint('[ShiftRepository] Shift soft-deleted: $id');

    // 2. Sync deletion to cloud
    final shift = _hiveProvider.getShift(id);
    if (shift != null) {
      _syncService.syncShift(shift);
    }
  }

  /// Get all shifts
  @override
  List<ShiftModel> getAllShifts() => _hiveProvider.getAllShifts();

  /// Get shifts for today
  @override
  List<ShiftModel> getTodayShifts() => _hiveProvider.getTodayShifts();

  /// Get shifts for this week
  @override
  List<ShiftModel> getThisWeekShifts() => _hiveProvider.getThisWeekShifts();

  /// Get shifts for this month
  @override
  List<ShiftModel> getThisMonthShifts() => _hiveProvider.getThisMonthShifts();

  /// Get shifts by date range
  @override
  List<ShiftModel> getShiftsByDateRange(DateTime start, DateTime end) =>
      _hiveProvider.getShiftsByDateRange(start, end);

  /// Search shifts
  @override
  List<ShiftModel> searchShifts(String query) =>
      _hiveProvider.searchShifts(query);

  /// Get shift by ID
  @override
  ShiftModel? getShift(String id) => _hiveProvider.getShift(id);

  String _requireUserId() {
    final userId = _auth.userId;
    if (!_auth.isLoggedIn || userId == null || userId.isEmpty) {
      throw const AuthRequiredException();
    }
    return userId;
  }

  void _assertOwnsShift(ShiftModel shift, String userId) {
    if (shift.userId.isNotEmpty && shift.userId != userId) {
      throw const PermissionDeniedException();
    }
  }

  /// Calculate total earnings from a list of shifts
  @override
  double calculateTotalEarnings(List<ShiftModel> shifts) {
    return shifts.fold(0.0, (sum, shift) => sum + shift.totalPay);
  }

  /// Calculate total hours from a list of shifts
  @override
  double calculateTotalHours(List<ShiftModel> shifts) {
    return shifts.fold(0.0, (sum, shift) => sum + shift.netHours);
  }
}
