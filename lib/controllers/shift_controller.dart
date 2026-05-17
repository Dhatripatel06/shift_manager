import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/errors/app_exception.dart';
import '../core/validation/input_validator.dart';
import '../domain/repositories/shift_repository_contract.dart';
import '../models/shift_model.dart';
import '../services/sync_service.dart';
import '../controllers/dashboard_controller.dart';

/// Filter type for shift list
enum ShiftFilter { all, daily, weekly, monthly }

/// Controller for Shift CRUD operations and list management.
class ShiftController extends GetxController {
  final IShiftRepository _repository = Get.find<IShiftRepository>();

  // ─── Observable State ──────────────────────────────────────

  /// All shifts
  final RxList<ShiftModel> shifts = <ShiftModel>[].obs;

  /// Filtered shifts
  final RxList<ShiftModel> filteredShifts = <ShiftModel>[].obs;

  /// Current filter
  final Rx<ShiftFilter> currentFilter = ShiftFilter.all.obs;

  /// Search query
  final RxString searchQuery = ''.obs;

  /// Loading state
  final RxBool isLoading = false.obs;

  /// Form controllers
  final eventNameController = TextEditingController();
  final jobRoleController = TextEditingController();
  final breakHoursController = TextEditingController();
  final payPerHourController = TextEditingController();
  final notesController = TextEditingController();

  /// Form state
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<TimeOfDay> selectedStartTime = const TimeOfDay(
    hour: 9,
    minute: 0,
  ).obs;
  final Rx<TimeOfDay> selectedEndTime = const TimeOfDay(
    hour: 17,
    minute: 0,
  ).obs;
  final RxDouble calculatedNetHours = 0.0.obs;
  final RxDouble calculatedTotalPay = 0.0.obs;

  /// Edit mode
  final RxBool isEditing = false.obs;
  final RxString editingShiftId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeShifts();

    // React to filter and search changes
    ever(currentFilter, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
  }

  /// Initialize shifts: restore from Firestore if Hive is empty
  Future<void> _initializeShifts() async {
    isLoading.value = true;
    try {
      // Load from local cache first
      final localShifts = _repository.getAllShifts();
      shifts.value = localShifts;

      // If Hive is empty, restore from Firestore
      if (localShifts.isEmpty) {
        debugPrint(
          '[ShiftController] Hive is empty, restoring from Firestore...',
        );
        try {
          final syncService = Get.find<SyncService>();
          final restoredCount = await syncService.fullRestore();
          debugPrint(
            '[ShiftController] Restored $restoredCount shifts from Firestore',
          );

          // Reload shifts after restoration
          shifts.value = _repository.getAllShifts();
        } catch (e) {
          debugPrint('[ShiftController] Restore failed: $e');
          // Silently fail - shifts might be syncing
        }
      }

      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all shifts
  void loadShifts() {
    isLoading.value = true;
    try {
      shifts.value = _repository.getAllShifts();
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  /// Apply current filters and search
  void _applyFilters() {
    List<ShiftModel> result;

    switch (currentFilter.value) {
      case ShiftFilter.daily:
        result = _repository.getTodayShifts();
        break;
      case ShiftFilter.weekly:
        result = _repository.getThisWeekShifts();
        break;
      case ShiftFilter.monthly:
        result = _repository.getThisMonthShifts();
        break;
      case ShiftFilter.all:
        result = _repository.getAllShifts();
        break;
    }

    // Apply search
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((shift) {
        return shift.eventName.toLowerCase().contains(query) ||
            shift.jobRole.toLowerCase().contains(query);
      }).toList();
    }

    filteredShifts.value = result;
  }

  /// Set filter
  void setFilter(ShiftFilter filter) {
    currentFilter.value = filter;
  }

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Calculate preview values for form
  void calculatePreview() {
    final startStr =
        '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${selectedStartTime.value.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${selectedEndTime.value.minute.toString().padLeft(2, '0')}';

    final breakHrs = double.tryParse(breakHoursController.text) ?? 0.0;
    final payRate = double.tryParse(payPerHourController.text) ?? 0.0;

    calculatedNetHours.value = ShiftModel.calculateNetHours(
      startStr,
      endStr,
      breakHrs,
    );
    calculatedTotalPay.value = ShiftModel.calculateTotalPay(
      calculatedNetHours.value,
      payRate,
    );
  }

  /// Add a new shift
  Future<bool> addShift() async {
    try {
      isLoading.value = true;

      final startStr =
          '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${selectedStartTime.value.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${selectedEndTime.value.minute.toString().padLeft(2, '0')}';

      final eventName = InputValidator.requiredText(
        eventNameController.text,
        'Event name',
      );
      final jobRole = InputValidator.requiredText(
        jobRoleController.text,
        'Job role',
      );
      final breakHours = InputValidator.nonNegativeDouble(
        breakHoursController.text.isEmpty ? '0' : breakHoursController.text,
        'Break hours',
      );
      final payPerHour = InputValidator.nonNegativeDouble(
        payPerHourController.text,
        'Pay per hour',
      );

      await _repository.createShift(
        date: selectedDate.value,
        eventName: eventName,
        jobRole: jobRole,
        startTime: startStr,
        endTime: endStr,
        breakHours: breakHours,
        payPerHour: payPerHour,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      loadShifts();
      _refreshDashboard();
      _clearForm();

      Get.snackbar(
        'Success',
        'Shift added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } on AppException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add shift. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing shift
  Future<bool> updateShift() async {
    try {
      isLoading.value = true;

      final startStr =
          '${selectedStartTime.value.hour.toString().padLeft(2, '0')}:${selectedStartTime.value.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${selectedEndTime.value.hour.toString().padLeft(2, '0')}:${selectedEndTime.value.minute.toString().padLeft(2, '0')}';

      final eventName = InputValidator.requiredText(
        eventNameController.text,
        'Event name',
      );
      final jobRole = InputValidator.requiredText(
        jobRoleController.text,
        'Job role',
      );
      final breakHours = InputValidator.nonNegativeDouble(
        breakHoursController.text.isEmpty ? '0' : breakHoursController.text,
        'Break hours',
      );
      final payPerHour = InputValidator.nonNegativeDouble(
        payPerHourController.text,
        'Pay per hour',
      );

      await _repository.updateShift(
        id: editingShiftId.value,
        date: selectedDate.value,
        eventName: eventName,
        jobRole: jobRole,
        startTime: startStr,
        endTime: endStr,
        breakHours: breakHours,
        payPerHour: payPerHour,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      loadShifts();
      _refreshDashboard();
      _clearForm();

      Get.snackbar(
        'Updated',
        'Shift updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      return true;
    } on AppException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update shift. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a shift with confirmation
  Future<void> deleteShift(String id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Shift'),
        content: const Text(
          'Are you sure you want to delete this shift? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteShift(id);
        loadShifts();
        _refreshDashboard();

        Get.snackbar(
          'Deleted',
          'Shift deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } on AppException catch (e) {
        Get.snackbar(
          'Error',
          e.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete shift. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  /// Prepare form for editing a shift
  void prepareEdit(ShiftModel shift) {
    isEditing.value = true;
    editingShiftId.value = shift.id;
    selectedDate.value = shift.date;
    eventNameController.text = shift.eventName;
    jobRoleController.text = shift.jobRole;
    breakHoursController.text = shift.breakHours.toString();
    payPerHourController.text = shift.payPerHour.toString();
    notesController.text = shift.notes ?? '';

    // Parse time
    final startParts = shift.startTime.split(':');
    selectedStartTime.value = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    final endParts = shift.endTime.split(':');
    selectedEndTime.value = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    calculatePreview();
  }

  /// Clear form
  void _clearForm() {
    isEditing.value = false;
    editingShiftId.value = '';
    selectedDate.value = DateTime.now();
    selectedStartTime.value = const TimeOfDay(hour: 9, minute: 0);
    selectedEndTime.value = const TimeOfDay(hour: 17, minute: 0);
    eventNameController.clear();
    jobRoleController.clear();
    breakHoursController.clear();
    payPerHourController.clear();
    notesController.clear();
    calculatedNetHours.value = 0.0;
    calculatedTotalPay.value = 0.0;
  }

  /// Prepare form for new shift
  void prepareNew() {
    _clearForm();
    payPerHourController.text = '12.00';
    breakHoursController.text = '0.0';
    calculatePreview();
  }

  /// Refresh dashboard data
  void _refreshDashboard() {
    try {
      final dashboardController = Get.find<DashboardController>();
      dashboardController.loadDashboardData();
    } catch (_) {
      // Dashboard might not be initialized yet
    }
  }

  /// Get all shifts for export
  List<ShiftModel> getAllShiftsForExport() => _repository.getAllShifts();

  @override
  void onClose() {
    eventNameController.dispose();
    jobRoleController.dispose();
    breakHoursController.dispose();
    payPerHourController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
