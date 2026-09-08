import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/customer.dart';
import '../models/ledger_entry.dart';
import '../utils/uuid_helper.dart';

/// Reads/writes the `customers` table — for BOTH customers and suppliers
/// (see [Customer.type]) and the `ledger_entries` table that records
/// every balance-changing event for a statement view. Phase 2 only
/// needed "quick add" and "look up the due amount" for Billing's old-due
/// banner; Phase 3 adds the full Khatabook-style ledger UI (search,
/// per-contact statement, reminders) on top of these same methods.
class CustomerService {
  CustomerService._internal();
  static final CustomerService instance = CustomerService._internal();

  final _db = DBHelper.instance;

  Future<Customer> quickAdd({
    required String businessUuid,
    required String name,
    String? phone,
    String type = AppConstants.contactTypeCustomer,
    double openingBalance = 0,
  }) async {
    final now = nowMillis();
    final customer = Customer(
      uuid: newUuid(),
      businessUuid: businessUuid,
      name: name,
      phone: phone,
      type: type,
      openingBalance: openingBalance,
      currentBalance: openingBalance,
      createdAt: now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableCustomers, customer.toMap());

    if (openingBalance != 0) {
      await _addLedgerEntry(
        businessUuid: businessUuid,
        contactUuid: customer.uuid,
        type: LedgerEntry.typeOpeningBalance,
        amount: openingBalance,
        now: now,
      );
    }
    return customer;
  }

  /// All non-deleted contacts of one [type] ('customer' or 'supplier').
  Future<List<Customer>> getAll(String businessUuid, {String type = AppConstants.contactTypeCustomer}) async {
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableCustomers,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
      extraWhere: 'type = ?',
      extraWhereArgs: [type],
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Customer>> search(String businessUuid, String query, {String type = AppConstants.contactTypeCustomer}) async {
    if (query.trim().isEmpty) return getAll(businessUuid, type: type);
    final rows = await _db.queryAllForBusiness(
      AppConstants.tableCustomers,
      businessUuid,
      orderBy: 'name COLLATE NOCASE ASC',
      extraWhere: 'type = ? AND (name LIKE ? OR phone LIKE ?)',
      extraWhereArgs: [type, '%$query%', '%$query%'],
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getByUuid(String uuid) async {
    final row = await _db.queryByUuid(AppConstants.tableCustomers, uuid);
    return row == null ? null : Customer.fromMap(row);
  }

  /// Adds [delta] to the customer's balance (positive = they now owe
  /// more; negative = a payment reduced what they owe). Called from
  /// [BillingService] inside the sale transaction, and internally by
  /// [addPayment]/[addAdjustment] below.
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

  /// Records a payment (received from a customer, or made to a supplier)
  /// and adjusts the running balance in the same call — this is what the
  /// Ledger's "ادائیگی ریکارڈ کریں" action uses. [amount] is entered as a
  /// positive number by the user; the sign applied to the balance is
  /// worked out here from the contact's [type] so callers never have to
  /// think about the sign convention.
  Future<void> addPayment({
    required Customer contact,
    required double amount,
    String? note,
  }) async {
    if (amount == 0) return;
    // A customer paying us reduces what they owe (balance moves toward
    // zero/negative); us paying a supplier does the same to what we owe
    // them (their balance, which is negative, moves toward zero).
    final delta = contact.isSupplier ? amount : -amount;
    await adjustBalance(contact.uuid, delta);
    await _addLedgerEntry(
      businessUuid: contact.businessUuid,
      contactUuid: contact.uuid,
      type: contact.isSupplier ? LedgerEntry.typePaymentMade : LedgerEntry.typePaymentReceived,
      amount: delta,
      note: note,
      now: nowMillis(),
    );
  }

  /// A free-form correction (e.g. fixing a typo'd opening balance).
  /// [delta] is signed exactly like [Customer.currentBalance].
  Future<void> addAdjustment({
    required Customer contact,
    required double delta,
    String? note,
  }) async {
    if (delta == 0) return;
    await adjustBalance(contact.uuid, delta);
    await _addLedgerEntry(
      businessUuid: contact.businessUuid,
      contactUuid: contact.uuid,
      type: LedgerEntry.typeAdjustment,
      amount: delta,
      note: note,
      now: nowMillis(),
    );
  }

  Future<void> _addLedgerEntry({
    required String businessUuid,
    required String contactUuid,
    required String type,
    required double amount,
    String? note,
    String? relatedSaleUuid,
    required int now,
  }) async {
    final entry = LedgerEntry(
      uuid: newUuid(),
      businessUuid: businessUuid,
      contactUuid: contactUuid,
      type: type,
      amount: amount,
      note: note,
      relatedSaleUuid: relatedSaleUuid,
      createdAt: now,
      lastUpdated: now,
    );
    await _db.insert(AppConstants.tableLedgerEntries, entry.toMap());
  }

  /// Full date-wise statement for one contact — every sale, payment and
  /// adjustment, oldest first, for the statement screen.
  Future<List<LedgerEntry>> getStatement(String contactUuid) async {
    final db = await _db.database;
    final rows = await db.query(
      AppConstants.tableLedgerEntries,
      where: 'contact_uuid = ? AND is_deleted = 0',
      whereArgs: [contactUuid],
      orderBy: 'created_at ASC',
    );
    return rows.map(LedgerEntry.fromMap).toList();
  }

  /// Sum of every contact's positive balance for [type] — "آپ کو ملنا
  /// ہے" total for the Ledger summary bar (and, for customers, the Zakat
  /// Calculator's receivables field).
  Future<double> totalReceivable(String businessUuid, {String type = AppConstants.contactTypeCustomer}) async {
    final contacts = await getAll(businessUuid, type: type);
    return contacts.where((c) => c.currentBalance > 0).fold<double>(0, (sum, c) => sum + c.currentBalance);
  }

  /// Sum of every contact's negative balance (absolute value) for
  /// [type] — "آپ نے دینا ہے" total.
  Future<double> totalPayable(String businessUuid, {String type = AppConstants.contactTypeCustomer}) async {
    final contacts = await getAll(businessUuid, type: type);
    return contacts.where((c) => c.currentBalance < 0).fold<double>(0, (sum, c) => sum + c.currentBalance.abs());
  }
}
