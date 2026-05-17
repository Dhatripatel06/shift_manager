import '../../models/shift_model.dart';

abstract class IShiftRepository {
  Future<ShiftModel> createShift({
    required DateTime date,
    required String eventName,
    required String jobRole,
    required String startTime,
    required String endTime,
    required double breakHours,
    required double payPerHour,
    String? notes,
  });

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
  });

  Future<void> deleteShift(String id);

  List<ShiftModel> getAllShifts();

  List<ShiftModel> getTodayShifts();

  List<ShiftModel> getThisWeekShifts();

  List<ShiftModel> getThisMonthShifts();

  List<ShiftModel> getShiftsByDateRange(DateTime start, DateTime end);

  List<ShiftModel> searchShifts(String query);

  ShiftModel? getShift(String id);

  double calculateTotalEarnings(List<ShiftModel> shifts);

  double calculateTotalHours(List<ShiftModel> shifts);
}
