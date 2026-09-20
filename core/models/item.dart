import '../constants/app_constants.dart';

/// A single inventory item belonging to one [Business]. Fields match the
/// locked "Inventory Form" design exactly: نام، کیٹیگری، بار کوڈ،
/// خریداری قیمت، فروخت قیمت، مقدار.
class Item {
  final String uuid;
  final String businessUuid;
  final String name;
  final String? category;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final double quantity;
  final String unit;
  final int createdAt;
  final int lastUpdated;
  final bool isDeleted;
  final bool isSynced;

  Item({
    required this.uuid,
    required this.businessUuid,
    required this.name,
    this.category,
    this.barcode,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.quantity = 0,
    this.unit = AppConstants.defaultUnit,
    required this.createdAt,
    required this.lastUpdated,
    this.isDeleted = false,
    this.isSynced = false,
  });

  bool get isLowStock => quantity <= AppConstants.lowStockThreshold;

  /// Expected profit if the entire current stock sold at [salePrice].
  double get expectedProfit => (salePrice - purchasePrice) * quantity;

  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'business_uuid': businessUuid,
        'name': name,
        'category': category,
        'barcode': barcode,
        'purchase_price': purchasePrice,
        'sale_price': salePrice,
        'quantity': quantity,
        'unit': unit,
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'is_deleted': isDeleted ? 1 : 0,
        'is_synced': isSynced ? 1 : 0,
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        uuid: map['uuid'] as String,
        businessUuid: map['business_uuid'] as String,
        name: map['name'] as String,
        category: map['category'] as String?,
        barcode: map['barcode'] as String?,
        purchasePrice: (map['purchase_price'] as num?)?.toDouble() ?? 0,
        salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        // Rows saved before this column existed (or pulled from a
        // not-yet-migrated server) come back null — treat as عدد.
        unit: (map['unit'] as String?)?.trim().isNotEmpty == true ? map['unit'] as String : AppConstants.defaultUnit,
        createdAt: map['created_at'] as int,
        lastUpdated: map['last_updated'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        isSynced: (map['is_synced'] as int) == 1,
      );

  Item copyWith({
    String? name,
    String? category,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    double? quantity,
    String? unit,
    int? lastUpdated,
    bool? isDeleted,
    bool? isSynced,
  }) =>
      Item(
        uuid: uuid,
        businessUuid: businessUuid,
        name: name ?? this.name,
        category: category ?? this.category,
        barcode: barcode ?? this.barcode,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        salePrice: salePrice ?? this.salePrice,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        createdAt: createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        isDeleted: isDeleted ?? this.isDeleted,
        isSynced: isSynced ?? this.isSynced,
      );
}
