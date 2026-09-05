import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import 'api_client.dart';

/// The background sync engine. Phase 2/3 tables (items, sales, ledgers,
/// employee payroll, zakat records...) all register themselves here with
/// one line — the push/pull/conflict logic is fully generic and does not
/// need to be rewritten per feature.
///
/// CONFLICT POLICY: last-write-wins by `last_updated`. Good enough for a
/// single shop with a handful of devices; if two staff edit the exact same
/// row within the same sync window, the later `last_updated` wins on both
/// sides once synced. This is stated explicitly so it's a conscious
/// decision, not an accident.
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final _db = DBHelper.instance;
  final _api = ApiClient.instance;

  /// Tables synced. Phase 1 registered users/businesses/business_users;
  /// Phase 2 adds the four lines below — nothing else in this class
  /// needed to change, exactly as the Phase 1 design intended.
  static const List<String> syncableTables = [
    AppConstants.tableUsers,
    AppConstants.tableBusinesses,
    AppConstants.tableBusinessUsers,
    AppConstants.tableItems,
    AppConstants.tableCustomers,
    AppConstants.tableSales,
    AppConstants.tableSaleItems,
  ];

  bool _isSyncing = false;

  Future<bool> get hasConnection async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Runs a full sync pass across every syncable table: push local changes
  /// first, then pull remote changes, in that order per table, so a
  /// device's own edits aren't immediately overwritten by a stale pull.
  Future<SyncResult> syncAll({String? businessUuid}) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }
    if (!await hasConnection) {
      return SyncResult(success: false, message: 'No internet connection — will retry automatically');
    }

    _isSyncing = true;
    final errors = <String>[];
    var pushedCount = 0;
    var pulledCount = 0;

    try {
      for (final table in syncableTables) {
        try {
          pushedCount += await _pushTable(table);
          pulledCount += await _pullTable(table, businessUuid: businessUuid);
        } catch (e) {
          errors.add('$table: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }

    if (errors.isNotEmpty) {
      return SyncResult(
        success: false,
        message: 'Some tables failed to sync: ${errors.join(', ')}',
        pushed: pushedCount,
        pulled: pulledCount,
      );
    }

    return SyncResult(
      success: true,
      message: 'Sync complete',
      pushed: pushedCount,
      pulled: pulledCount,
    );
  }

  Future<int> _pushTable(String table) async {
    final unsynced = await _db.queryUnsynced(table);
    if (unsynced.isEmpty) return 0;

    await _api.push(table: table, rows: unsynced);

    final uuids = unsynced.map((r) => r['uuid'] as String).toList();
    await _db.markSynced(table, uuids);
    return unsynced.length;
  }

  Future<int> _pullTable(String table, {String? businessUuid}) async {
    final since = await _db.getLastSyncedAt(table);
    final remoteRows = await _api.pull(
      table: table,
      since: since,
      businessUuid: businessUuid,
    );
    if (remoteRows.isEmpty) {
      await _db.setLastSyncedAt(table, DateTime.now().millisecondsSinceEpoch);
      return 0;
    }

    var maxUpdated = since;
    for (final row in remoteRows) {
      // Rows coming from the server are already "synced" from our
      // perspective — mark is_synced = 1 so we don't immediately try to
      // push them back up.
      final localRow = Map<String, dynamic>.from(row)..['is_synced'] = 1;
      await _db.insert(table, localRow);

      final rowUpdated = row['last_updated'] as int;
      if (rowUpdated > maxUpdated) maxUpdated = rowUpdated;
    }

    await _db.setLastSyncedAt(table, maxUpdated);
    return remoteRows.length;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int pushed;
  final int pulled;

  SyncResult({
    required this.success,
    required this.message,
    this.pushed = 0,
    this.pulled = 0,
  });
}
