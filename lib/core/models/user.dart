/// A person who can log into the app. A user can belong to multiple
/// businesses via [BusinessUser] rows (multi-tenant, multi-role).
///
/// Every syncable table in this app follows the same shape:
///   - uuid            : globally unique primary key (client-generated)
///   - lastUpdated      : epoch millis, used by the sync engine
///   - isDeleted        : soft delete flag (so deletes can sync too)
///   - isSynced         : 0 = has local changes not yet pushed to server
class User {
  final String uuid;
  final String name;
  final String? phone;
  final String? email;
  final String passwordHash; // local (offline) login uses this
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  User({
    required this.uuid,
    required this.name,
    this.phone,
    this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'name': name,
        'phone': phone,
        'email': email,
        'password_hash': passwordHash,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        uuid: map['uuid'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        passwordHash: map['password_hash'] as String,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  User copyWith({
    String? name,
    String? phone,
    String? email,
    String? passwordHash,
    int? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) =>
      User(
        uuid: uuid,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
}
