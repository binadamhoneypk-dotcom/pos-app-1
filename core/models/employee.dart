/// An employee/staff member of one [Business] — the payroll counterpart
/// to [Customer], following the exact same uuid + last_updated +
/// is_deleted + is_synced + balance-tracking pattern per the locked
/// design.
///
/// SIGN CONVENTION for [currentBalance]:
///   > 0  → the SHOP owes the employee money (unpaid salary/bonus accrued)
///   < 0  → the EMPLOYEE owes the shop money (advance given, not yet
///          worked off/deducted)
///   = 0  → settled
///
/// [userUuid] is set only if the owner/manager chose to also create a
/// login account for this employee via `AuthService.addStaffToBusiness`
/// — an employee can exist purely as a payroll record with no app login.
class Employee {
  final String uuid;
  final String businessUuid;
  final String? userUuid;
  final String name;
  final String? phone;
  final String? roleTitle;
  final double monthlySalary;
  final double currentBalance;
  final int? joiningDate;
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  Employee({
    required this.uuid,
    required this.businessUuid,
    this.userUuid,
    required this.name,
    this.phone,
    this.roleTitle,
    this.monthlySalary = 0,
    this.currentBalance = 0,
    this.joiningDate,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  bool get hasLoginAccount => userUuid != null;
  bool get shopOwesEmployee => currentBalance > 0;
  bool get employeeOwesShop => currentBalance < 0;

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'user_uuid': userUuid,
        'name': name,
        'phone': phone,
        'role_title': roleTitle,
        'monthly_salary': monthlySalary,
        'current_balance': currentBalance,
        'joining_date': joiningDate,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        userUuid: map['user_uuid'] as String?,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        roleTitle: map['role_title'] as String?,
        monthlySalary: (map['monthly_salary'] as num?)?.toDouble() ?? 0,
        currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0,
        joiningDate: map['joining_date'] as int?,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  Employee copyWith({
    String? name,
    String? phone,
    String? roleTitle,
    double? monthlySalary,
    double? currentBalance,
    int? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) =>
      Employee(
        uuid: uuid,
        businessUuid: businessUuid,
        userUuid: userUuid,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        roleTitle: roleTitle ?? this.roleTitle,
        monthlySalary: monthlySalary ?? this.monthlySalary,
        currentBalance: currentBalance ?? this.currentBalance,
        joiningDate: joiningDate,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
}
