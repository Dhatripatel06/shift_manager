import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/app_logger.dart';
import '../../models/shift_model.dart';
import '../providers/hive_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

/// Production-ready repository with Firestore as primary, Hive as cache
/// Implements offline-first architecture with intelligent sync
class FirestoreShiftRepository {
  final HiveProvider _hiveProvider = Get.find<HiveProvider>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _auth = Get.find<AuthService>();
  final _uuid = const Uuid();

  /// Create a new shift (saved to both Hive and Firestore)
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
    // Verify authentication
    if (!_auth.isLoggedIn) {
      throw Exception('User must be logged in to create shifts');
    }

    try {
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
      AppLogger.debug('[Repository] Shift created locally: ${shift.id}');

      // 2. Try to sync to Firestore (non-blocking)
      try {
        await _firestoreService.createShift(shift);
        await _hiveProvider.markAsSynced(shift.id);
        AppLogger.debug('[Repository] Shift synced to Firestore: ${shift.id}');
      } catch (e) {
        AppLogger.debug(
          '[Repository] Firestore sync failed, data saved locally: $e',
        );
        // Data is safe in Hive, will retry later
      }

      return shift;
    } catch (e) {
      AppLogger.debug('[Repository] Error creating shift: $e');
      rethrow;
    }
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
    try {
      final existing = _hiveProvider.getShift(id);
      if (existing == null) throw Exception('Shift not found');

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
      );

      // 1. Update locally
      await _hiveProvider.saveShift(updatedShift);
      AppLogger.debug('[Repository] Shift updated locally: $id');

      // 2. Sync to Firestore
      try {
        await _firestoreService.updateShift(updatedShift);
        await _hiveProvider.markAsSynced(id);
        AppLogger.debug('[Repository] Shift synced to Firestore: $id');
      } catch (e) {
        AppLogger.debug('[Repository] Firestore sync failed: $e');
      }

      return updatedShift;
    } catch (e) {
      AppLogger.debug('[Repository] Error updating shift: $e');
      rethrow;
    }
  }

  /// Delete a shift
  Future<void> deleteShift(String id) async {
    try {
      // 1. Soft delete locally
      final shift = _hiveProvider.getShift(id);
      if (shift != null) {
        await _hiveProvider.saveShift(shift.copyWith(isDeleted: true));
      }

      // 2. Soft delete in Firestore
      await _firestoreService.deleteShift(id);
      AppLogger.debug('[Repository] Shift deleted: $id');
    } catch (e) {
      AppLogger.debug('[Repository] Error deleting shift: $e');
      rethrow;
    }
  }

  /// Get shift from cache or Firestore
  Future<ShiftModel?> getShift(String id) async {
    try {
      // Try local cache first
      final localShift = _hiveProvider.getShift(id);
      if (localShift != null && !localShift.isDeleted) {
        return localShift;
      }

      // Fall back to Firestore
      final firestoreShift = await _firestoreService.getShift(id);
      if (firestoreShift != null) {
        await _hiveProvider.saveShift(firestoreShift);
      }
      return firestoreShift;
    } catch (e) {
      AppLogger.debug('[Repository] Error fetching shift: $e');
      return null;
    }
  }

  /// Get all shifts from local cache
  List<ShiftModel> getAllShifts() {
    return _hiveProvider.getAllShifts().where((s) => !s.isDeleted).toList();
  }

  /// Get this week's shifts
  List<ShiftModel> getThisWeekShifts() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return getAllShifts().where((shift) {
      return shift.date.isAfter(weekStart) && shift.date.isBefore(weekEnd);
    }).toList();
  }

  /// Get this month's shifts
  List<ShiftModel> getThisMonthShifts() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    return getAllShifts().where((shift) {
      return shift.date.isAfter(monthStart) && shift.date.isBefore(monthEnd);
    }).toList();
  }

  /// Calculate total hours
  double calculateTotalHours(List<ShiftModel> shifts) {
    return shifts.fold(0.0, (sum, shift) => sum + shift.netHours);
  }

  /// Calculate total earnings
  double calculateTotalEarnings(List<ShiftModel> shifts) {
    return shifts.fold(0.0, (sum, shift) => sum + shift.totalPay);
  }

  /// Stream of all shifts from Firestore (real-time)
  Stream<List<ShiftModel>> watchAllShifts() {
    return _firestoreService.watchAllShifts();
  }

  /// Stream of recent shifts (real-time)
  Stream<List<ShiftModel>> watchRecentShifts({int limit = 10}) {
    return _firestoreService.watchRecentShifts(limit: limit);
  }

  /// Search shifts by event name
  Future<List<ShiftModel>> searchShifts(String query) async {
    if (query.isEmpty) return getAllShifts();

    try {
      return await _firestoreService.searchByEventName(query);
    } catch (e) {
      AppLogger.debug('[Repository] Search error: $e');
      // Fallback to local search
      return getAllShifts().where((shift) {
        return shift.eventName.toLowerCase().contains(query.toLowerCase()) ||
            shift.jobRole.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  /// Get shifts by date range
  Future<List<ShiftModel>> getShiftsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _firestoreService.getShiftsByDateRange(start, end);
    } catch (e) {
      AppLogger.debug('[Repository] Date range query error: $e');
      return getAllShifts().where((shift) {
        return shift.date.isAfter(start) && shift.date.isBefore(end);
      }).toList();
    }
  }

  /// Get all shifts for export
  List<ShiftModel> getAllShiftsForExport() {
    return getAllShifts();
  }

  /// Get unsynced shifts
  List<ShiftModel> getUnsyncedShifts() {
    return _hiveProvider.getUnsyncedShifts();
  }

  /// Manual sync all unsynced shifts to Firestore
  Future<int> syncAllUnsynced() async {
    try {
      final unsynced = getUnsyncedShifts();
      if (unsynced.isEmpty) return 0;

      await _firestoreService.batchWriteShifts(unsynced);

      for (var shift in unsynced) {
        await _hiveProvider.markAsSynced(shift.id);
      }

      AppLogger.debug('[Repository] Synced ${unsynced.length} shifts');
      return unsynced.length;
    } catch (e) {
      AppLogger.debug('[Repository] Sync error: $e');
      return 0;
    }
  }

  /// Full restore from Firestore
  Future<int> fullRestoreFromFirestore() async {
    try {
      final allShifts = await _firestoreService.watchAllShifts().first;

      // Clear local cache and replace with Firestore data
      await _hiveProvider.clearAllShifts();
      await _firestoreService.batchWriteShifts(allShifts);

      for (var shift in allShifts) {
        await _hiveProvider.saveShift(shift);
      }

      AppLogger.debug(
        '[Repository] Restored ${allShifts.length} shifts from Firestore',
      );
      return allShifts.length;
    } catch (e) {
      AppLogger.debug('[Repository] Restore error: $e');
      rethrow;
    }
  }
}
