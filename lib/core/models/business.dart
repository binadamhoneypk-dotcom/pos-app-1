/// A single shop/restaurant/workshop owned or managed by one or more users.
/// Phase 2+ tables (items, sales, ledgers) will all carry a businessUuid
/// foreign key so data stays cleanly separated per business.
class Business {
  final String uuid;
  final String name;
  final String type; // e.g. 'general_store', 'restaurant', 'workshop', 'pharmacy', 'custom'
  final String? logoPath;
  final String ownerUuid; // uuid of the User who created this business
  final double zakatNisabThreshold; // in local currency, user-configurable
  final int? zakatStartDate; // epoch millis, user-configurable
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  Business({
    required this.uuid,
    required this.name,
    required this.type,
    this.logoPath,
    required this.ownerUuid,
    this.zakatNisabThreshold = 0,
    this.zakatStartDate,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'name': name,
        'type': type,
        'logo_path': logoPath,
        'owner_uuid': ownerUuid,
        'zakat_nisab_threshold': zakatNisabThreshold,
        'zakat_start_date': zakatStartDate,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory Business.fromMap(Map<String, dynamic> map) => Business(
        uuid: map['uuid'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        logoPath: map['logo_path'] as String?,
        ownerUuid: map['owner_uuid'] as String,
        zakatNisabThreshold:
            (map['zakat_nisab_threshold'] as num?)?.toDouble() ?? 0,
        zakatStartDate: map['zakat_start_date'] as int?,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  Business copyWith({
    String? name,
    String? type,
    String? logoPath,
    double? zakatNisabThreshold,
    int? zakatStartDate,
    int? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) =>
      Business(
        uuid: uuid,
        name: name ?? this.name,
        type: type ?? this.type,
        logoPath: logoPath ?? this.logoPath,
        ownerUuid: ownerUuid,
        zakatNisabThreshold: zakatNisabThreshold ?? this.zakatNisabThreshold,
        zakatStartDate: zakatStartDate ?? this.zakatStartDate,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
}
