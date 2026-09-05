import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/business.dart';
import '../models/business_user.dart';
import '../models/user.dart';
import '../utils/password_helper.dart';
import '../utils/uuid_helper.dart';

/// Handles signup/login fully offline (no server round-trip required),
/// plus creating the FIRST business for a new owner. Staff accounts for
/// an existing business are created from the business-management screen
/// in Phase 3 (needs owner/manager permission checks from BusinessUser).
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _db = DBHelper.instance;

  /// Creates a new owner account AND their first business in one step —
  /// this is the normal "shopkeeper installs the app for the first time"
  /// flow. Works with zero internet connection.
  Future<(User, Business, BusinessUser)> signUpOwnerWithBusiness({
    required String ownerName,
    required String phone,
    String? email,
    required String password,
    required String businessName,
    required String businessType,
  }) async {
    final now = nowMillis();

    final user = User(
      uuid: newUuid(),
      name: ownerName,
      phone: phone,
      email: email,
      passwordHash: PasswordHelper.hash(password),
      createdAt: now,
      lastUpdated: now,
    );

    final business = Business(
      uuid: newUuid(),
      name: businessName,
      type: businessType,
      ownerUuid: user.uuid,
      createdAt: now,
      lastUpdated: now,
    );

    final link = BusinessUser(
      uuid: newUuid(),
      businessUuid: business.uuid,
      userUuid: user.uuid,
      role: AppConstants.roleOwner,
      createdAt: now,
      lastUpdated: now,
    );

    await _db.insert(AppConstants.tableUsers, user.toMap());
    await _db.insert(AppConstants.tableBusinesses, business.toMap());
    await _db.insert(AppConstants.tableBusinessUsers, link.toMap());

    await _startSession(user.uuid);
    return (user, business, link);
  }

  /// Adds a staff/manager account to an EXISTING business. Caller must
  /// already have verified the requesting user has canManageStaff == true.
  Future<(User, BusinessUser)> addStaffToBusiness({
    required String businessUuid,
    required String staffName,
    required String phone,
    required String password,
    required String role, // AppConstants.roleManager or roleStaff
  }) async {
    final now = nowMillis();

    final user = User(
      uuid: newUuid(),
      name: staffName,
      phone: phone,
      passwordHash: PasswordHelper.hash(password),
      createdAt: now,
      lastUpdated: now,
    );

    final link = BusinessUser(
      uuid: newUuid(),
      businessUuid: businessUuid,
      userUuid: user.uuid,
      role: role,
      createdAt: now,
      lastUpdated: now,
    );

    await _db.insert(AppConstants.tableUsers, user.toMap());
    await _db.insert(AppConstants.tableBusinessUsers, link.toMap());

    return (user, link);
  }

  /// Adds an ADDITIONAL business to a user who already has at least one
  /// (e.g. an owner opening a second shop). Reuses the exact same
  /// Business + BusinessUser(role: owner) shape as the first-business
  /// signup — no new sync logic needed since both tables were already
  /// registered with SyncService. Gated behind PremiumFeature
  /// .multiBusiness at the call site (business_switch_screen.dart), not
  /// here — this method itself has no opinion about premium.
  Future<(Business, BusinessUser)> addBusinessForExistingOwner({
    required String ownerUuid,
    required String businessName,
    required String businessType,
  }) async {
    final now = nowMillis();

    final business = Business(
      uuid: newUuid(),
      name: businessName,
      type: businessType,
      ownerUuid: ownerUuid,
      createdAt: now,
      lastUpdated: now,
    );

    final link = BusinessUser(
      uuid: newUuid(),
      businessUuid: business.uuid,
      userUuid: ownerUuid,
      role: AppConstants.roleOwner,
      createdAt: now,
      lastUpdated: now,
    );

    await _db.insert(AppConstants.tableBusinesses, business.toMap());
    await _db.insert(AppConstants.tableBusinessUsers, link.toMap());

    return (business, link);
  }

  /// Offline login: looks the user up locally by phone, checks the hash.
  /// No network call — this is the whole point of offline-first auth.
  Future<User?> login({required String phone, required String password}) async {
    final db = await _db.database;
    final rows = await db.query(
      AppConstants.tableUsers,
      where: 'phone = ? AND is_deleted = 0',
      whereArgs: [phone],
    );
    if (rows.isEmpty) return null;

    final user = User.fromMap(rows.first);
    if (!PasswordHelper.verify(password, user.passwordHash)) return null;

    await _startSession(user.uuid);
    return user;
  }

  Future<void> _startSession(String userUuid) async {
    await _secureStorage.write(
        key: AppConstants.prefSessionUserKey, value: userUuid);
  }

  Future<String?> getSessionUserUuid() =>
      _secureStorage.read(key: AppConstants.prefSessionUserKey);

  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.prefSessionUserKey);
  }

  /// Looks up a user by uuid — used by [AppState.loadSession] to restore
  /// the full [User] object on a cold app start (Phase 1's loadSession
  /// only restored the business list, leaving currentUser null after a
  /// restart; Phase 2's "add another business" flow needs currentUser).
  Future<User?> getUserByUuid(String uuid) async {
    final db = await _db.database;
    final rows = await db.query(
      AppConstants.tableUsers,
      where: 'uuid = ? AND is_deleted = 0',
      whereArgs: [uuid],
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  /// All businesses the given user belongs to, with their role in each —
  /// this powers the multi-business switcher on the home screen.
  Future<List<(Business, BusinessUser)>> businessesForUser(
      String userUuid) async {
    final db = await _db.database;
    final links = await db.query(
      AppConstants.tableBusinessUsers,
      where: 'user_uuid = ? AND is_deleted = 0',
      whereArgs: [userUuid],
    );

    final result = <(Business, BusinessUser)>[];
    for (final linkRow in links) {
      final bu = BusinessUser.fromMap(linkRow);
      final bizRows = await db.query(
        AppConstants.tableBusinesses,
        where: 'uuid = ? AND is_deleted = 0',
        whereArgs: [bu.businessUuid],
      );
      if (bizRows.isNotEmpty) {
        result.add((Business.fromMap(bizRows.first), bu));
      }
    }
    return result;
  }
}
