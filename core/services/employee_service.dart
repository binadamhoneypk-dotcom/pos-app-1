import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import '../models/employee_transaction.dart';
import '../utils/uuid_helper.dart';

/// Reads/writes `employees`, `employee_transactions` and `attendance`.
/// Mirrors [CustomerService]'s pattern deliberately (uuid + last_updated
/// + is_deleted + is_synced, balance tracking, a statement of signed
/// transactions) so the same mental model applies to both ledgers, per
/// the locked design.
class EmployeeService {
  EmployeeService._internal();
  static final EmployeeService instance = EmployeeService._internal();

  final _db = DBHelper.instance;

  Future<Employee> add({
    required String businessUuid,
    String? userUuid,
    required String name,
    String? phone,
    String? roleTitle,
    double monthlySalary = 0,
    int? joiningDate,
  }) async {
    final now = nowMillis();
    final employee = Employee(
      uuid: newUuid(),
      businessUuid: businessUuid,
      userUuid: userUuid,
      name: name,
      phone: phone,
      roleTitle: roleTitle,
      monthlySalary: monthlySalary,
      joiningDate: joiningDate ?? now,
      createdAt: now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableEmployees, employee.toMap());
    return employee;
  }

  Future<List<Employee>> getAll(String businessUuid) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableEmployees,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Employee.fromMap).toList();
  }

  Future<Employee?> getByUuid(String uuid) async {
    final row = await _db.queryByUuid(AppConstants.tableEmployees, uuid);
    return row == null ? null : Employee.fromMap(row);
  }

  Future<void> update(Employee employee) async {
    final updated = employee.copyWith(lastUpdated: nowMillis());
    await _db.update(AppConstants.tableEmployees, {
      ...updated.toMap(),
      'is_synced': 0,
    }, employee.uuid);
  }

  Future<void> softDelete(String uuid) => _db.softDelete(AppConstants.tableEmployees, uuid, nowMillis());

  Future<void> _adjustBalance(String uuid, double delta) async {
    final row = await _db.queryByUuid(AppConstants.tableEmployees, uuid);
    if (row == null) return;
    final employee = Employee.fromMap(row);
    final updated = employee.copyWith(
      currentBalance: employee.currentBalance + delta,
      lastUpdated: nowMillis(),
      isSynced: false,
    );
    await _db.update(AppConstants.tableEmployees, updated.toMap(), uuid);
  }

  /// Records a payroll event and updates [Employee.currentBalance] in
  /// one call, so screens never have to work the sign out themselves:
  ///   - salary payment / paying off an advance-covered amount → shop's
  ///     debt to the employee goes down: balance decreases.
  ///   - advance given to the employee → they now owe the shop:
  ///     balance decreases (goes negative).
  ///   - bonus accrued → shop owes more: balance increases.
  ///   - deduction (e.g. against an earlier advance, or a penalty) →
  ///     balance increases (reduces what they owe the shop, or reduces
  ///     what's still due to them, per [amount]'s sign as entered).
  /// [amount] is always entered as a positive number by the caller
  /// except for [AppConstants.empTxnDeduction], which the caller may
  /// pass negative for a straightforward "reduce what's owed to them".
  Future<void> addTransaction({
    required Employee employee,
    required String type,
    required double amount,
    String? note,
  }) async {
    if (amount == 0) return;
    double delta;
    switch (type) {
      case AppConstants.empTxnSalaryPayment:
        delta = -amount;
        break;
      case AppConstants.empTxnAdvance:
        delta = -amount;
        break;
      case AppConstants.empTxnBonus:
        delta = amount;
        break;
      case AppConstants.empTxnDeduction:
        delta = -amount.abs();
        break;
      default:
        delta = amount;
    }
    await _adjustBalance(employee.uuid, delta);

    final now = nowMillis();
    final txn = EmployeeTransaction(
      uuid: newUuid(),
      businessUuid: employee.businessUuid,
      employeeUuid: employee.uuid,
      type: type,
      amount: delta,
      note: note,
      createdAt: now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableEmployeeTransactions, txn.toMap());
  }

  Future<List<EmployeeTransaction>> getStatement(String employeeUuid) async {
    final db = await _db.database;
    final rows = await db.query(
      AppConstants.tableEmployeeTransactions,
      where: 'employee_uuid = ? AND is_deleted = 0',
      whereArgs: [employeeUuid],
      orderBy: 'created_at ASC',
    );
    return rows.map(EmployeeTransaction.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // ATTENDANCE (بنیادی)
  // ---------------------------------------------------------------------

  /// Marks [status] for [employeeUuid] on [date] (defaults to today).
  /// Upserts — marking the same day twice just overwrites the status,
  /// which is the expected "I marked it wrong, let me fix it" flow.
  Future<void> markAttendance({
    required String businessUuid,
    required String employeeUuid,
    required String status,
    DateTime? date,
  }) async {
    final now = nowMillis();
    final dateKey = AttendanceRecord.keyFor(date ?? DateTime.now());
    final db = await _db.database;
    final existing = await db.query(
      AppConstants.tableAttendance,
      where: 'employee_uuid = ? AND date_key = ?',
      whereArgs: [employeeUuid, dateKey],
      limit: 1,
    );
    final record = AttendanceRecord(
      uuid: existing.isNotEmpty ? existing.first['uuid'] as String : newUuid(),
      businessUuid: businessUuid,
      employeeUuid: employeeUuid,
      dateKey: dateKey,
      status: status,
      createdAt: existing.isNotEmpty ? existing.first['created_at'] as int : now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableAttendance, record.toMap());
  }

  /// All attendance rows for [employeeUuid] within [year]/[month]
  /// (1-indexed), for the month view on the employee detail screen.
  Future<List<AttendanceRecord>> getAttendanceForMonth(String employeeUuid, int year, int month) async {
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final db = await _db.database;
    final rows = await db.query(
      AppConstants.tableAttendance,
      where: 'employee_uuid = ? AND date_key LIKE ? AND is_deleted = 0',
      whereArgs: [employeeUuid, '$prefix%'],
      orderBy: 'date_key ASC',
    );
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  /// Sum of every employee's positive balance — "شاپ کو ملازمین کو کتنا
  /// دینا ہے" total, useful for a future payroll summary card.
  Future<double> totalPayableToEmployees(String businessUuid) async {
    final employees = await getAll(businessUuid);
    return employees.where((e) => e.currentBalance > 0).fold<double>(0, (sum, e) => sum + e.currentBalance);
  }
}
