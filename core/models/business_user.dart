import '../constants/app_constants.dart';

/// Links a [User] to a [Business] with a role. This is what makes the app
/// multi-tenant AND multi-user at the same time: one user row can have many
/// BusinessUser rows (different roles in different shops), and one business
/// can have many staff.
class BusinessUser {
  final String uuid;
  final String businessUuid;
  final String userUuid;
  final String role; // owner | manager | staff (see AppConstants)
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  BusinessUser({
    required this.uuid,
    required this.businessUuid,
    required this.userUuid,
    required this.role,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  bool get isOwner => role == AppConstants.roleOwner;
  bool get isManager => role == AppConstants.roleManager;
  bool get isStaff => role == AppConstants.roleStaff;

  // Permission helpers Phase 2/3 screens can check directly.
  bool get canViewFinancialReports => isOwner || isManager;
  bool get canDeleteBusiness => isOwner;
  bool get canManageStaff => isOwner || isManager;

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'user_uuid': userUuid,
        'role': role,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory BusinessUser.fromMap(Map<String, dynamic> map) => BusinessUser(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        userUuid: map['user_uuid'] as String,
        role: map['role'] as String,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );
}
