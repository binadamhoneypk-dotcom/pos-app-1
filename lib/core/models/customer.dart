/// A customer of one [Business]. This table is the foundation Billing's
/// "old due" banner reads/writes in Phase 2; the full Khatabook-style
/// ledger screens (search, reminders, statement) are built on top of
/// this exact same table in Phase 3 — nothing about this model changes
/// then, only new screens are added.
///
/// SIGN CONVENTION for [currentBalance]:
///   > 0  → the customer owes the shop money ("آپ کو ملنا ہے" — green)
///   < 0  → the shop owes the customer money ("آپ نے دینا ہے" — red)
///   = 0  → settled
class Customer {
  final String uuid;
  final String businessUuid;
  final String name;
  final String? phone;
  final double openingBalance;
  final double currentBalance;
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  Customer({
    required this.uuid,
    required this.businessUuid,
    required this.name,
    this.phone,
    this.openingBalance = 0,
    this.currentBalance = 0,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  bool get customerOwesUs => currentBalance > 0;
  bool get weOweCustomer => currentBalance < 0;

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'name': name,
        'phone': phone,
        'opening_balance': openingBalance,
        'current_balance': currentBalance,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
        currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  Customer copyWith({
    String? name,
    String? phone,
    double? currentBalance,
    int? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) =>
      Customer(
        uuid: uuid,
        businessUuid: businessUuid,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        openingBalance: openingBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
}
