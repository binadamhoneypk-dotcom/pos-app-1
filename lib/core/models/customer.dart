import '../constants/app_constants.dart';

/// A customer OR supplier of one [Business] — Phase 3 reuses this single
/// table/model for both via [type], instead of a parallel `suppliers`
/// table. Rationale (see the Phase 3 continuation prompt's request to
/// compare both approaches): a customer and a supplier are the exact same
/// shape of record — a name, a phone, a running balance, a history of
/// credit/payment events — and keeping one table means the sync engine,
/// balance math, search, and statement logic are written and tested once.
/// The trade-off is that every query must remember to filter by [type];
/// [CustomerService] does that centrally so call sites never have to.
///
/// SIGN CONVENTION for [currentBalance] (same for customers AND suppliers):
///   > 0  → the OTHER party owes the shop money ("آپ کو ملنا ہے" — green)
///   < 0  → the shop owes the OTHER party money ("آپ نے دینا ہے" — red)
///   = 0  → settled
/// For a supplier this typically stays negative (the shop owes them for
/// stock bought on credit) — the sign convention doesn't flip, only which
/// direction is "normal" for that contact type differs.
class Customer {
  final String uuid;
  final String businessUuid;
  final String name;
  final String? phone;
  final String type; // AppConstants.contactTypeCustomer / contactTypeSupplier
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
    this.type = AppConstants.contactTypeCustomer,
    this.openingBalance = 0,
    this.currentBalance = 0,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  bool get isSupplier => type == AppConstants.contactTypeSupplier;
  bool get isCustomer => !isSupplier;

  bool get customerOwesUs => currentBalance > 0;
  bool get weOweCustomer => currentBalance < 0;

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'name': name,
        'phone': phone,
        'type': type,
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
        // Older Phase 2 rows synced before this column existed may still
        // come back null from a stale server pull — treat those as
        // ordinary customers rather than crashing.
        type: (map['type'] as String?) ?? AppConstants.contactTypeCustomer,
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
        type: type,
        openingBalance: openingBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
}
