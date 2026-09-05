import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';
import '../utils/uuid_helper.dart';

/// Reads/writes the `customers` table. Phase 2 only needs "quick add"
/// and "look up the due amount" for Billing's old-due banner — the full
/// Khatabook-style ledger screen (search, per-customer statement,
/// reminders) is Phase 3 and will call these same methods.
class CustomerService {
  CustomerService._internal();
  static final CustomerService instance = CustomerService._internal();

  final _db = DBHelper.instance;

  Future<Customer> quickAdd({
    required String businessUuid,
    required String name,
    String? phone,
    double openingBalance = 0,
  }) async {
    final now = nowMillis();
    final customer = Customer(
      uuid: newUuid(),
      businessUuid: businessUuid,
      name: name,
      phone: phone,
      openingBalance: openingBalance,
      currentBalance: openingBalance,
      createdAt: now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableCustomers, customer.toMap());
    return customer;
  }

  Future<List<Customer>> getAll(String businessUuid) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableCustomers,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Customer>> search(String businessUuid, String query) async {
    if (query.trim().isEmpty) return getAll(businessUuid);
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableCustomers,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
      extraWhere: '(name LIKE ? OR phone LIKE ?)',
      extraWhereArgs: ['%$query%', '%$query%'],
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getByUuid(String uuid) async {
    final row = await _db.queryByUuid(AppConstants.tableCustomers, uuid);
    return row == null ? null : Customer.fromMap(row);
  }

  /// Adds [delta] to the customer's balance (positive = they now owe
  /// more; negative = a payment reduced what they owe). Called from
  /// [BillingService] inside the sale transaction.
  Future<void> adjustBalance(String uuid, double delta) async {
    final row = await _db.queryByUuid(AppConstants.tableCustomers, uuid);
    if (row == null) return;
    final customer = Customer.fromMap(row);
    final updated = customer.copyWith(
      currentBalance: customer.currentBalance + delta,
      lastUpdated: nowMillis(),
      isSynced: false,
    );
    await _db.update(AppConstants.tableCustomers, updated.toMap(), uuid);
  }

  /// Sum of every customer's positive balance — "آپ کو ملنا ہے" total
  /// for the Ledger summary bar and the Zakat Calculator's receivables
  /// field.
  Future<double> totalReceivable(String businessUuid) async {
    final customers = await getAll(businessUuid);
    return customers
        .where((c) => c.currentBalance > 0)
        .fold<double>(0, (sum, c) => sum + c.currentBalance);
  }
}
