/// One line of a [Sale]. `itemNameSnapshot` and `unitPrice` are copied
/// at sale time so a bill's history never changes if the item is later
/// renamed, re-priced, or removed from inventory.
class SaleItem {
  final String uuid;
  final String businessUuid;
  final String saleUuid;
  final String? itemUuid; // null-safe even if the source item is later deleted
  final String itemNameSnapshot;
  final double unitPrice;
  final double quantity;
  final String unit;
  final double lineTotal;
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  SaleItem({
    required this.uuid,
    required this.businessUuid,
    required this.saleUuid,
    this.itemUuid,
    required this.itemNameSnapshot,
    required this.unitPrice,
    required this.quantity,
    this.unit = 'عدد',
    required this.lineTotal,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'sale_uuid': saleUuid,
        'item_uuid': itemUuid,
        'item_name_snapshot': itemNameSnapshot,
        'unit_price': unitPrice,
        'quantity': quantity,
        'unit': unit,
        'line_total': lineTotal,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        saleUuid: map['sale_uuid'] as String,
        itemUuid: map['item_uuid'] as String?,
        itemNameSnapshot: map['item_name_snapshot'] as String,
        unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unit: (map['unit'] as String?)?.trim().isNotEmpty == true ? map['unit'] as String : 'عدد',
        lineTotal: (map['line_total'] as num?)?.toDouble() ?? 0,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );
}
