import '../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';

/// One payroll event for an [Employee] — salary paid, advance given, a
/// bonus accrued, or a deduction. This is what the Employee statement
/// screen lists date-wise; `employees.current_balance` alone only shows
/// the running total.
class EmployeeTransaction {
  final String uuid;
  final String businessUuid;
  final String employeeUuid;
  final String type; // AppConstants.empTxn*
  final double amount; // signed — same convention as Employee.currentBalance
  final String? note;
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  EmployeeTransaction({
    required this.uuid,
    required this.businessUuid,
    required this.employeeUuid,
    required this.type,
    required this.amount,
    this.note,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'employee_uuid': employeeUuid,
        'type': type,
        'amount': amount,
        'note': note,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory EmployeeTransaction.fromMap(Map<String, dynamic> map) => EmployeeTransaction(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        employeeUuid: map['employee_uuid'] as String,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  String label(AppLocalizations t) {
    switch (type) {
      case AppConstants.empTxnSalaryPayment:
        return t.salaryPaidLabel;
      case AppConstants.empTxnAdvance:
        return t.advanceGivenLabel;
      case AppConstants.empTxnBonus:
        return t.bonusWord;
      case AppConstants.empTxnDeduction:
        return t.deductionWord;
      default:
        return type;
    }
  }
}
