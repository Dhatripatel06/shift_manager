import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/shift_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

/// Hive local database provider.
/// Handles all local CRUD operations for shifts with user isolation.
/// Ensures each user only sees their own shifts in local cache.
class HiveProvider extends GetxService {
  late Box<ShiftModel> _shiftsBox;
  late Box<dynamic> _settingsBox;

  /// Get auth service for current user ID
  AuthService get _auth => Get.find<AuthService>();

  /// Get current user ID
  String get _currentUserId => _auth.userId ?? '';

  /// Initialize Hive boxes
  Future<HiveProvider> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ShiftModelAdapter());
    }

    // Open boxes
    _shiftsBox = await Hive.openBox<ShiftModel>(AppConstants.shiftsBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);

    return this;
  }

  // ─── Shift Operations ──────────────────────────────────────

  /// Save or update a shift
  Future<void> saveShift(ShiftModel shift) async {
    await _shiftsBox.put(shift.id, shift);
  }

  /// Get a shift by ID
  ShiftModel? getShift(String id) {
    return _shiftsBox.get(id);
  }

  /// Get all active shifts for CURRENT USER ONLY (not deleted), sorted by date descending
  List<ShiftModel> getAllShifts() {
    final userId = _currentUserId;
    final shifts = _shiftsBox.values
        .where((shift) => !shift.isDeleted && shift.userId == userId)
        .toList();
    shifts.sort((a, b) => b.date.compareTo(a.date));
    return shifts;
  }

  /// Get shifts for a specific date range (current user only)
  List<ShiftModel> getShiftsByDateRange(DateTime start, DateTime end) {
    final userId = _currentUserId;
    return _shiftsBox.values
        .where((shift) => !shift.isDeleted && shift.userId == userId)
        .where((shift) {
          return shift.date.isAfter(start.subtract(const Duration(days: 1))) &&
              shift.date.isBefore(end.add(const Duration(days: 1)));
        })
        .toList();
  }

  /// Get shifts for today
  List<ShiftModel> getTodayShifts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getAllShifts()
        .where(
          (s) =>
              s.date.year == today.year &&
              s.date.month == today.month &&
              s.date.day == today.day,
        )
        .toList();
  }

  /// Get shifts for this week
  List<ShiftModel> getThisWeekShifts() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = start.add(const Duration(days: 7));
    return getShiftsByDateRange(start, end);
  }

  /// Get shifts for this month
  List<ShiftModel> getThisMonthShifts() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return getShiftsByDateRange(start, end);
  }

  /// Soft delete a shift (mark as deleted for sync)
  Future<void> softDeleteShift(String id) async {
    final shift = _shiftsBox.get(id);
    if (shift != null) {
      final updated = shift.copyWith(
        isDeleted: true,
        isSynced: false,
        updatedAt: DateTime.now(),
      );
      await _shiftsBox.put(id, updated);
    }
  }

  /// Permanently delete a shift (after successful Firestore delete)
  Future<void> permanentlyDeleteShift(String id) async {
    await _shiftsBox.delete(id);
  }

  /// Get all unsynced shifts for current user
  List<ShiftModel> getUnsyncedShifts() {
    final userId = _currentUserId;
    return _shiftsBox.values
        .where((shift) => shift.userId == userId && !shift.isSynced)
        .toList();
  }

  /// Mark a shift as synced
  Future<void> markAsSynced(String id) async {
    final shift = _shiftsBox.get(id);
    if (shift != null) {
      await _shiftsBox.put(id, shift.copyWith(isSynced: true));
    }
  }

  /// Search shifts by event name or job role (current user only)
  List<ShiftModel> searchShifts(String query) {
    final userId = _currentUserId;
    final lowerQuery = query.toLowerCase();
    return _shiftsBox.values
        .where((shift) => !shift.isDeleted && shift.userId == userId)
        .where((shift) {
          return shift.eventName.toLowerCase().contains(lowerQuery) ||
              shift.jobRole.toLowerCase().contains(lowerQuery);
        })
        .toList();
  }

  /// Get total shift count
  int get shiftCount => getAllShifts().length;

  /// Clear all shifts for current user (doesn't clear other users' data)
  Future<void> clearAllShifts() async {
    final userId = _currentUserId;
    final keysToDelete = _shiftsBox.values
        .where((shift) => shift.userId == userId)
        .map((shift) => shift.id)
        .toList();

    for (final key in keysToDelete) {
      await _shiftsBox.delete(key);
    }
  }

  // ─── Settings Operations ───────────────────────────────────

  /// Get a setting value
  T? getSetting<T>(String key) {
    return _settingsBox.get(key) as T?;
  }

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Get dark mode preference
  bool get isDarkMode =>
      _settingsBox.get(AppConstants.themeKey, defaultValue: true) as bool;

  /// Set dark mode preference
  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put(AppConstants.themeKey, value);
  }
}
