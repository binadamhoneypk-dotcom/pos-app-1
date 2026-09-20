import '../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

/// One day's attendance mark for an [Employee]. `dateKey` is a plain
/// 'YYYY-MM-DD' string (not epoch millis) so "did we already mark
/// today" is a simple string match regardless of timezone, and a
/// (employee_uuid, date_key) UNIQUE constraint in the DB stops double
/// marking the same day twice.
class AttendanceRecord {
  final String uuid;
  final String businessUuid;
  final String employeeUuid;
  final String dateKey;
  final String status; // AppConstants.attendance*
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  AttendanceRecord({
    required this.uuid,
    required this.businessUuid,
    required this.employeeUuid,
    required this.dateKey,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  static String keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'employee_uuid': employeeUuid,
        'date_key': dateKey,
        'status': status,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) => AttendanceRecord(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        employeeUuid: map['employee_uuid'] as String,
        dateKey: map['date_key'] as String,
        status: map['status'] as String,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  String label(AppLocalizations t) {
    switch (status) {
      case AppConstants.attendancePresent:
        return t.attendancePresentLabel;
      case AppConstants.attendanceAbsent:
        return t.attendanceAbsentLabel;
      case AppConstants.attendanceLeave:
        return t.attendanceLeaveLabel;
      default:
        return status;
    }
  }
}
