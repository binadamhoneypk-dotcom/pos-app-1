import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/ledger_entry.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../utils/uuid_helper.dart';

/// One row the user has added to the bill they're currently building.
/// This is UI-side state only — it becomes a real [SaleItem] row once
/// the bill is saved via [BillingService.createSale].
class BillLineItem {
  final String? itemUuid; // null for a free-text/manual line
  final String name;
  final double unitPrice;
  double quantity;
  final String unit;

  BillLineItem({
    this.itemUuid,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
    this.unit = 'عدد',
  });

  double get lineTotal => unitPrice * quantity;
}

/// Saves a completed bill. Everything happens inside one SQLite
/// transaction so a half-written bill (e.g. stock decremented but the
/// sale row missing) can never happen if something fails partway.
class BillingService {
  BillingService._internal();
  static final BillingService instance = BillingService._internal();

  final _db = DBHelper.instance;

  Future<Sale> createSale({
    required String businessUuid,
    String? customerUuid,
    required List<BillLineItem> lines,
    required double paidAmount,
  }) async {
    final now = nowMillis();
    final subtotal = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final total = subtotal; // Phase 2 has no discount/tax fields yet.
    final due = total - paidAmount;

    final sale = Sale(
      uuid: newUuid(),
      businessUuid: businessUuid,
      customerUuid: customerUuid,
      subtotal: subtotal,
      totalAmount: total,
      paidAmount: paidAmount,
      dueAmount: due,
      createdAt: now,
      lastUpdated: now,
    );

    await _db.runInTransaction((txn) async {
      await txn.insert(AppConstants.tableSales, sale.toMap());

      for (final line in lines) {
        final saleItem = SaleItem(
          uuid: newUuid(),
          businessUuid: businessUuid,
          saleUuid: sale.uuid,
          itemUuid: line.itemUuid,
          itemNameSnapshot: line.name,
          unitPrice: line.unitPrice,
          quantity: line.quantity,
          unit: line.unit,
          lineTotal: line.lineTotal,
          createdAt: now,
          lastUpdated: now,
        );
        await txn.insert(AppConstants.tableSaleItems, saleItem.toMap());

        if (line.itemUuid != null) {
          final rows = await txn.query(
            AppConstants.tableItems,
            where: 'uuid = ?',
            whereArgs: [line.itemUuid],
          );
          if (rows.isNotEmpty) {
            final currentQty = (rows.first['quantity'] as num).toDouble();
            await txn.update(
              AppConstants.tableItems,
              {
                'quantity': currentQty - line.quantity,
                'last_updated': now,
                'is_synced': 0,
              },
              where: 'uuid = ?',
              whereArgs: [line.itemUuid],
            );
          }
        }
      }

      if (customerUuid != null && due != 0) {
        final rows = await txn.query(
          AppConstants.tableCustomers,
          where: 'uuid = ?',
          whereArgs: [customerUuid],
        );
        if (rows.isNotEmpty) {
          final currentBalance = (rows.first['current_balance'] as num).toDouble();
          await txn.update(
            AppConstants.tableCustomers,
            {
              'current_balance': currentBalance + due,
              'last_updated': now,
              'is_synced': 0,
            },
            where: 'uuid = ?',
            whereArgs: [customerUuid],
          );

          // PHASE 3: also record this on the ledger so the customer's
          // statement screen shows the sale itself, not just a balance
          // jump. Written via `txn` (not CustomerService, which would
          // reach for the outer, still-locked Database and hang) so it
          // rolls back together with the rest of the bill on failure.
          final ledgerEntry = LedgerEntry(
            uuid: newUuid(),
            businessUuid: businessUuid,
            contactUuid: customerUuid,
            type: LedgerEntry.typeSale,
            amount: due,
            relatedSaleUuid: sale.uuid,
            createdAt: now,
            lastUpdated: now,
          );
          await txn.insert(AppConstants.tableLedgerEntries, ledgerEntry.toMap());
        }
      }

      return null;
    });

    return sale;
  }

  Future<List<Sale>> getSalesForBusiness(String businessUuid) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableSales,
      businessUuid,
      orderBy: 'created_at DESC',
    );
    return rows.map(Sale.fromMap).toList();
  }

  Future<List<SaleItem>> getLineItems(String saleUuid) async {
    final db = await _db.database;
    final rows = await db.query(
      AppConstants.tableSaleItems,
      where: 'sale_uuid = ? AND is_deleted = 0',
      whereArgs: [saleUuid],
    );
    return rows.map(SaleItem.fromMap).toList();
  }

  /// Sum of today's bills — Dashboard "آج کی فروخت" stat card.
  Future<double> todaysSalesTotal(String businessUuid) async {
    final sales = await getSalesForBusiness(businessUuid);
    final startOfDay = DateTime.now();
    final startMillis =
        DateTime(startOfDay.year, startOfDay.month, startOfDay.day).millisecondsSinceEpoch;
    return sales
        .where((s) => s.createdAt >= startMillis)
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
  }
}
