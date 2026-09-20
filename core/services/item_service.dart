import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/item.dart';
import '../utils/uuid_helper.dart';

/// All inventory read/write logic lives here so screens never touch
/// sqflite directly. Every write bumps `last_updated` and clears
/// `is_synced`, exactly like Phase 1's AuthService — that's what lets
/// [SyncService] push it on the next sync pass with zero special-casing.
class ItemService {
  ItemService._internal();
  static final ItemService instance = ItemService._internal();

  final _db = DBHelper.instance;

  Future<Item> createItem({
    required String businessUuid,
    required String name,
    String? category,
    String? barcode,
    required double purchasePrice,
    required double salePrice,
    required double quantity,
    String unit = AppConstants.defaultUnit,
  }) async {
    final now = nowMillis();
    final item = Item(
      uuid: newUuid(),
      businessUuid: businessUuid,
      name: name,
      category: category,
      barcode: barcode,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      quantity: quantity,
      unit: unit,
      createdAt: now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableItems, item.toMap());
    return item;
  }

  Future<Item> updateItem(Item item) async {
    final updated = item.copyWith(lastUpdated: nowMillis(), isSynced: false);
    await _db.update(AppConstants.tableItems, updated.toMap(), updated.uuid);
    return updated;
  }

  Future<void> deleteItem(String uuid) async {
    await _db.softDelete(AppConstants.tableItems, uuid, nowMillis());
  }

  /// Bumps or reduces stock after a sale/return. Used by [BillingService]
  /// inside the sale transaction, and available standalone for manual
  /// stock adjustments later.
  Future<void> adjustQuantity(String uuid, double delta) async {
    final row = await _db.queryByUuid(AppConstants.tableItems, uuid);
    if (row == null) return;
    final item = Item.fromMap(row);
    await updateItem(item.copyWith(quantity: item.quantity + delta));
  }

  Future<List<Item>> getAll(String businessUuid) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableItems,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<List<Item>> search(String businessUuid, String query) async {
    if (query.trim().isEmpty) return getAll(businessUuid);
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableItems,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
      extraWhere: '(name LIKE ? OR barcode LIKE ?)',
      extraWhereArgs: ['%$query%', '%$query%'],
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<Item?> findByBarcode(String businessUuid, String barcode) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableItems,
      businessUuid,
      extraWhere: 'barcode = ?',
      extraWhereArgs: [barcode],
    );
    return rows.isEmpty ? null : Item.fromMap(rows.first);
  }

  Future<List<Item>> getLowStock(String businessUuid) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableItems,
      businessUuid,
      orderBy: 'quantity ASC',
      extraWhere: 'quantity <= ?',
      extraWhereArgs: [AppConstants.lowStockThreshold],
    );
    return rows.map(Item.fromMap).toList();
  }

  /// Sum of `sale_price * quantity` across all current stock — used as
  /// the default "trade goods" figure in the Zakat Calculator (the
  /// shopkeeper can still edit it manually there).
  Future<double> totalStockSaleValue(String businessUuid) async {
    final items = await getAll(businessUuid);
    return items.fold<double>(0, (sum, i) => sum + (i.salePrice * i.quantity));
  }
}
