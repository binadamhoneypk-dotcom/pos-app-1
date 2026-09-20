import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/business.dart';
import '../utils/uuid_helper.dart';

/// Small companion to Phase 1's AuthService — Phase 1 only ever *creates*
/// a business, it never updates one. Phase 2 needs to persist the Zakat
/// nisab threshold and start date the shopkeeper sets in the Zakat
/// Calculator, so that logic lives here.
class BusinessService {
  BusinessService._internal();
  static final BusinessService instance = BusinessService._internal();

  final _db = DBHelper.instance;

  Future<Business> updateZakatSettings(
    Business business, {
    required double zakatNisabThreshold,
    required int? zakatStartDate,
  }) async {
    final updated = business.copyWith(
      zakatNisabThreshold: zakatNisabThreshold,
      zakatStartDate: zakatStartDate,
      lastUpdated: nowMillis(),
      isSynced: false,
    );
    await _db.update(AppConstants.tableBusinesses, updated.toMap(), updated.uuid);
    return updated;
  }
}
