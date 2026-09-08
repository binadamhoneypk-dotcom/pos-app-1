import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

/// Single source of truth for the local SQLite database.
///
/// SYNC DESIGN (applies to every table Phase 2/3 will add too):
///   - Every row has a client-generated `uuid` as primary key (never an
///     autoincrement int) so records created offline never collide with
///     records created on another device.
///   - `last_updated` (epoch millis) is bumped on every local write.
///   - `is_synced` = 0 means "this row has local changes the server hasn't
///     seen yet" — the sync engine pushes rows where is_synced = 0.
///   - `is_deleted` = 1 is a SOFT delete. Hard deletes can't sync reliably
///     (the other device has no way to know a row "disappeared"), so we
///     mark it deleted, sync that flag, and periodically purge old
///     soft-deleted rows once every device has confirmed the sync.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
  }

  /// Runs when a device that already has the Phase 1 database (version 1)
  /// opens the Phase 2 app. Fresh installs never hit this — they get the
  /// full schema straight from [_createSchema] — so both paths must stay
  /// in sync whenever a new table is added.
  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPhase2Tables(db);
    }
    if (oldVersion < 3) {
      await _createPhase3Tables(db);
    }
    if (oldVersion < 4) {
      await _createFeature1Columns(db);
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    // ---- users ---------------------------------------------------------
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        uuid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        password_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ---- businesses ------------------------------------------------------
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBusinesses} (
        uuid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        logo_path TEXT,
        owner_uuid TEXT NOT NULL,
        zakat_nisab_threshold REAL NOT NULL DEFAULT 0,
        zakat_start_date INTEGER,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (owner_uuid) REFERENCES ${AppConstants.tableUsers}(uuid)
      )
    ''');

    // ---- business_users (roles / multi-tenant join table) --------------
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBusinessUsers} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        user_uuid TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid),
        FOREIGN KEY (user_uuid) REFERENCES ${AppConstants.tableUsers}(uuid),
        UNIQUE(business_uuid, user_uuid)
      )
    ''');

    // ---- sync_log --------------------------------------------------------
    // Tracks the last successful sync timestamp PER TABLE, so Phase 2/3
    // tables (items, sales, ledgers...) can plug into the same engine
    // without a full-database resync every time.
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncLog} (
        table_name TEXT PRIMARY KEY,
        last_synced_at INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Helpful indexes for the sync engine's "give me unsynced rows" query.
    await db.execute(
        'CREATE INDEX idx_users_synced ON ${AppConstants.tableUsers}(is_synced)');
    await db.execute(
        'CREATE INDEX idx_businesses_synced ON ${AppConstants.tableBusinesses}(is_synced)');
    await db.execute(
        'CREATE INDEX idx_bu_synced ON ${AppConstants.tableBusinessUsers}(is_synced)');
    await db.execute(
        'CREATE INDEX idx_bu_business ON ${AppConstants.tableBusinessUsers}(business_uuid)');

    await _createPhase2Tables(db);
    await _createPhase3Tables(db);
    await _createFeature1Columns(db);
  }

  /// Phase 2 tables — Inventory (`items`), the lightweight `customers`
  /// table Billing's "old due" banner needs (full Customer/Supplier
  /// ledger *screens* land in Phase 3, but they read/write this same
  /// table), and Billing itself (`sales` + `sale_items`).
  ///
  /// Every table follows the exact same sync shape as Phase 1
  /// (`uuid`, `business_uuid`, `last_updated`, `is_deleted`, `is_synced`)
  /// so [SyncService] needs zero special-casing — just add the table
  /// name to `syncableTables`.
  Future<void> _createPhase2Tables(Database db) async {
    // ---- items (inventory) ---------------------------------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableItems} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        barcode TEXT,
        purchase_price REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_items_synced ON ${AppConstants.tableItems}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_items_business ON ${AppConstants.tableItems}(business_uuid)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_items_barcode ON ${AppConstants.tableItems}(barcode)');

    // ---- customers (foundation for Billing's due banner now; the full
    // Khatabook-style ledger UI is Phase 3, reusing this same table) ----
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableCustomers} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        opening_balance REAL NOT NULL DEFAULT 0,
        current_balance REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_synced ON ${AppConstants.tableCustomers}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_business ON ${AppConstants.tableCustomers}(business_uuid)');

    // ---- sales (one row per bill) ---------------------------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableSales} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        customer_uuid TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        due_amount REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid),
        FOREIGN KEY (customer_uuid) REFERENCES ${AppConstants.tableCustomers}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_synced ON ${AppConstants.tableSales}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_business ON ${AppConstants.tableSales}(business_uuid)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_created ON ${AppConstants.tableSales}(created_at)');

    // ---- sale_items (line items of a bill) -------------------------------
    // `item_name_snapshot` / `unit_price` are copied at sale time on
    // purpose: if the shopkeeper later renames or re-prices the item,
    // old bills must keep showing what was actually sold that day.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableSaleItems} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        sale_uuid TEXT NOT NULL,
        item_uuid TEXT,
        item_name_snapshot TEXT NOT NULL,
        unit_price REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        line_total REAL NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sale_uuid) REFERENCES ${AppConstants.tableSales}(uuid),
        FOREIGN KEY (item_uuid) REFERENCES ${AppConstants.tableItems}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_synced ON ${AppConstants.tableSaleItems}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON ${AppConstants.tableSaleItems}(sale_uuid)');
  }

  /// Phase 3 — Customer/Supplier Ledger (statement + reminders) and the
  /// Employee/Payroll Ledger. Runs on BOTH a fresh install (right after
  /// `_createPhase2Tables`, so `customers` already exists without `type`)
  /// and an upgrade from v2, which is why the `type` column is added via
  /// a guarded ALTER TABLE rather than baked into `_createPhase2Tables`.
  Future<void> _createPhase3Tables(Database db) async {
    // ---- customers.type — lets Suppliers reuse the exact same table,
    // balance logic and sync wiring as Customers instead of duplicating
    // all of it in a parallel `suppliers` table. Existing rows default to
    // 'customer' so Phase 2 data is unaffected. --------------------------
    final columns = await db.rawQuery('PRAGMA table_info(${AppConstants.tableCustomers})');
    final hasType = columns.any((c) => c['name'] == 'type');
    if (!hasType) {
      await db.execute(
          "ALTER TABLE ${AppConstants.tableCustomers} ADD COLUMN type TEXT NOT NULL DEFAULT '${AppConstants.contactTypeCustomer}'");
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_type ON ${AppConstants.tableCustomers}(type)');
    }

    // ---- ledger_entries — one row per balance-changing event for a
    // customers/suppliers row, so the statement screen can show a real
    // history instead of just the running current_balance. -------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableLedgerEntries} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        contact_uuid TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        note TEXT,
        related_sale_uuid TEXT,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid),
        FOREIGN KEY (contact_uuid) REFERENCES ${AppConstants.tableCustomers}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_entries_synced ON ${AppConstants.tableLedgerEntries}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_entries_business ON ${AppConstants.tableLedgerEntries}(business_uuid)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_entries_contact ON ${AppConstants.tableLedgerEntries}(contact_uuid)');

    // ---- employees — same uuid/last_updated/is_deleted/is_synced +
    // balance-tracking pattern as customers, per the locked design.
    // `user_uuid` is nullable: an employee only gets a login account if
    // the owner/manager opts in via AuthService.addStaffToBusiness. -----
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableEmployees} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        user_uuid TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        role_title TEXT,
        monthly_salary REAL NOT NULL DEFAULT 0,
        current_balance REAL NOT NULL DEFAULT 0,
        joining_date INTEGER,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid),
        FOREIGN KEY (user_uuid) REFERENCES ${AppConstants.tableUsers}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_employees_synced ON ${AppConstants.tableEmployees}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_employees_business ON ${AppConstants.tableEmployees}(business_uuid)');

    // ---- employee_transactions — salary payments, advances, bonuses,
    // deductions. SIGN CONVENTION on `amount`, applied to
    // employees.current_balance: positive = shop now owes the employee
    // MORE (unpaid salary/bonus accrued); negative = the employee now
    // owes the shop (advance given) or a debt was settled (payment/
    // deduction). See EmployeeService for the exact sign per type. ------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableEmployeeTransactions} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        employee_uuid TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid),
        FOREIGN KEY (employee_uuid) REFERENCES ${AppConstants.tableEmployees}(uuid)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_emp_txn_synced ON ${AppConstants.tableEmployeeTransactions}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_emp_txn_employee ON ${AppConstants.tableEmployeeTransactions}(employee_uuid)');

    // ---- attendance — basic present/absent/leave, one row per
    // employee per day. `date_key` is 'YYYY-MM-DD' (not an epoch millis)
    // so "did we already mark today" is a simple string match regardless
    // of timezone. ---------------------------------------------------
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableAttendance} (
        uuid TEXT PRIMARY KEY,
        business_uuid TEXT NOT NULL,
        employee_uuid TEXT NOT NULL,
        date_key TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (business_uuid) REFERENCES ${AppConstants.tableBusinesses}(uuid),
        FOREIGN KEY (employee_uuid) REFERENCES ${AppConstants.tableEmployees}(uuid),
        UNIQUE(employee_uuid, date_key)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attendance_synced ON ${AppConstants.tableAttendance}(is_synced)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attendance_employee ON ${AppConstants.tableAttendance}(employee_uuid)');
  }

  /// Google AI Studio prompt, Feature 1 — unit of measurement. Adds
  /// `unit` to `items` (the shopkeeper's chosen unit) and `sale_items`
  /// (a snapshot at sale time, same reasoning as `item_name_snapshot`:
  /// a bill's history must never change if the item's unit is edited
  /// later). Guarded the same way as `customers.type` in
  /// `_createPhase3Tables` so this runs safely on both a fresh install
  /// and an upgrade.
  Future<void> _createFeature1Columns(Database db) async {
    final itemCols = await db.rawQuery('PRAGMA table_info(${AppConstants.tableItems})');
    if (!itemCols.any((c) => c['name'] == 'unit')) {
      await db.execute(
          "ALTER TABLE ${AppConstants.tableItems} ADD COLUMN unit TEXT NOT NULL DEFAULT '${AppConstants.defaultUnit}'");
    }

    final saleItemCols = await db.rawQuery('PRAGMA table_info(${AppConstants.tableSaleItems})');
    if (!saleItemCols.any((c) => c['name'] == 'unit')) {
      await db.execute(
          "ALTER TABLE ${AppConstants.tableSaleItems} ADD COLUMN unit TEXT NOT NULL DEFAULT '${AppConstants.defaultUnit}'");
    }
  }

  // ------------------------------------------------------------------
  // Generic helpers reused by every repository/service. Keeping CRUD
  // generic here means Phase 2 tables (items, sales...) reuse this
  // instead of re-implementing sync bookkeeping each time.
  // ------------------------------------------------------------------

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(
      String table, Map<String, dynamic> values, String uuid) async {
    final db = await database;
    return db.update(table, values, where: 'uuid = ?', whereArgs: [uuid]);
  }

  Future<List<Map<String, dynamic>>> queryUnsynced(String table) async {
    final db = await database;
    return db.query(table, where: 'is_synced = 0');
  }

  Future<void> markSynced(String table, List<String> uuids) async {
    if (uuids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(uuids.length, '?').join(',');
    await db.update(table, {'is_synced': 1},
        where: 'uuid IN ($placeholders)', whereArgs: uuids);
  }

  Future<int> getLastSyncedAt(String table) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableSyncLog,
        where: 'table_name = ?', whereArgs: [table]);
    if (rows.isEmpty) return 0;
    return rows.first['last_synced_at'] as int;
  }

  Future<void> setLastSyncedAt(String table, int timestamp) async {
    final db = await database;
    await db.insert(
      AppConstants.tableSyncLog,
      {'table_name': table, 'last_synced_at': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------------
  // PHASE 2 — generic read/delete helpers reused by ItemService,
  // CustomerService and BillingService so none of them need to touch
  // sqflite directly.
  // ------------------------------------------------------------------

  /// All non-deleted rows for one business, newest-first by default.
  Future<List<Map<String, dynamic>>> queryAllForBusiness(
    String table,
    String businessUuid, {
    String orderBy = 'last_updated DESC',
    String? extraWhere,
    List<Object?>? extraWhereArgs,
  }) async {
    final db = await database;
    final where = extraWhere == null
        ? 'business_uuid = ? AND is_deleted = 0'
        : 'business_uuid = ? AND is_deleted = 0 AND $extraWhere';
    return db.query(
      table,
      where: where,
      whereArgs: [businessUuid, ...?extraWhereArgs],
      orderBy: orderBy,
    );
  }

  Future<Map<String, dynamic>?> queryByUuid(String table, String uuid) async {
    final db = await database;
    final rows = await db.query(table, where: 'uuid = ?', whereArgs: [uuid], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  /// Soft delete — required so the sync engine can propagate the
  /// deletion to other devices instead of silently losing the row.
  Future<void> softDelete(String table, String uuid, int nowMillis) async {
    final db = await database;
    await db.update(
      table,
      {'is_deleted': 1, 'is_synced': 0, 'last_updated': nowMillis},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Runs [action] inside a single SQLite transaction — used by
  /// [BillingService] so "insert sale + insert sale_items + decrement
  /// stock + update customer balance" either all succeed or all roll
  /// back together.
  Future<T> runInTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
