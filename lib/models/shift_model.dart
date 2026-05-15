import 'package:hive/hive.dart';

part 'shift_model.g.dart';

/// Shift model representing a single work shift entry.
/// Stores all information about a shift including time, pay, and metadata.
@HiveType(typeId: 0)
class ShiftModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String eventName;

  @HiveField(3)
  final String jobRole;

  @HiveField(4)
  final String startTime; // HH:mm format

  @HiveField(5)
  final String endTime; // HH:mm format

  @HiveField(6)
  final double breakHours;

  @HiveField(7)
  final double netHours;

  @HiveField(8)
  final double payPerHour;

  @HiveField(9)
  final double totalPay;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final bool isSynced;

  @HiveField(14)
  final bool isDeleted;

  ShiftModel({
    required this.id,
    required this.date,
    required this.eventName,
    required this.jobRole,
    required this.startTime,
    required this.endTime,
    required this.breakHours,
    required this.netHours,
    required this.payPerHour,
    required this.totalPay,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  /// Calculate total hours from start and end time
  static double calculateTotalHours(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      // Handle overnight shifts
      if (endMinutes < startMinutes) {
        endMinutes += 24 * 60;
      }

      return (endMinutes - startMinutes) / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate net hours (total hours - break hours)
  static double calculateNetHours(
      String startTime, String endTime, double breakHours) {
    final totalHours = calculateTotalHours(startTime, endTime);
    final net = totalHours - breakHours;
    return net > 0 ? net : 0.0;
  }

  /// Calculate total pay
  static double calculateTotalPay(double netHours, double payPerHour) {
    return netHours * payPerHour;
  }

  /// Convert to Firestore-compatible Map
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'eventName': eventName,
      'jobRole': jobRole,
      'startTime': startTime,
      'endTime': endTime,
      'breakHours': breakHours,
      'netHours': netHours,
      'payPerHour': payPerHour,
      'totalPay': totalPay,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  /// Create ShiftModel from Firestore document
  factory ShiftModel.fromFirestoreMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      eventName: map['eventName'] as String,
      jobRole: map['jobRole'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      breakHours: (map['breakHours'] as num).toDouble(),
      netHours: (map['netHours'] as num).toDouble(),
      payPerHour: (map['payPerHour'] as num).toDouble(),
      totalPay: (map['totalPay'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: true,
      isDeleted: (map['isDeleted'] as bool?) ?? false,
    );
  }

  /// Create a copy with updated fields
  ShiftModel copyWith({
    String? id,
    DateTime? date,
    String? eventName,
    String? jobRole,
    String? startTime,
    String? endTime,
    double? breakHours,
    double? netHours,
    double? payPerHour,
    double? totalPay,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      date: date ?? this.date,
      eventName: eventName ?? this.eventName,
      jobRole: jobRole ?? this.jobRole,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakHours: breakHours ?? this.breakHours,
      netHours: netHours ?? this.netHours,
      payPerHour: payPerHour ?? this.payPerHour,
      totalPay: totalPay ?? this.totalPay,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'ShiftModel(id: $id, date: $date, event: $eventName, role: $jobRole, '
        'net: ${netHours}h, pay: £$totalPay)';
  }
}
