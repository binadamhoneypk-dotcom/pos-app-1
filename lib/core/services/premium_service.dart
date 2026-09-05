import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Every feature that can be gated behind Premium. Adding a new one here
/// is the ONLY step needed to start gating it elsewhere in the app —
/// call `PremiumService.instance.isUnlocked(PremiumFeature.xxx)`.
///
/// Some of these (staffAccounts, supplierLedger, reports, pdfInvoicing,
/// multiDeviceSync) don't have a screen yet — they belong to Phase 3/4 —
/// but are listed now so whoever builds those screens just wraps them
/// with [PremiumGate.ensure] instead of inventing a new mechanism.
enum PremiumFeature {
  barcodeAutoScan, // camera auto-scans a barcode, no separate scanner needed
  zakatCalculator, // full Zakat Calculator + detailed nisab info
  multiBusiness, // more than one shop per account
  unlimitedItems, // more than AppConstants.freeMaxItems inventory rows
  staffAccounts, // Phase 3: manager/staff accounts beyond the owner
  supplierLedger, // Phase 3: supplier side of the ledger
  reports, // Phase 4: sales/profit reports & export
  pdfInvoicing, // Phase 4: PDF bill generation with letterhead/watermark
  multiDeviceSync, // running the same business on more than one device
}

/// Single source of truth for "is this shopkeeper on the free plan or
/// Premium". Deliberately payment-agnostic: today [setPremium] is only
/// ever called by the temporary dev toggle on [UpgradeScreen], but
/// nothing else in the app needs to change once a real payment method
/// is wired in — Google Play Billing, a pos_api license-key endpoint,
/// or both just need to call [setPremium] after a successful purchase.
///
/// Notifies listeners so any screen watching it (e.g. a lock badge)
/// updates the instant premium status changes.
class PremiumService extends ChangeNotifier {
  PremiumService._internal();
  static final PremiumService instance = PremiumService._internal();

  bool _isPremium = false;
  int? _expiresAtMillis; // null = lifetime / not a subscription

  bool get isPremium {
    if (!_isPremium) return false;
    if (_expiresAtMillis == null) return true;
    return DateTime.now().millisecondsSinceEpoch < _expiresAtMillis!;
  }

  int? get expiresAtMillis => _expiresAtMillis;

  /// Call once at app startup (see main.dart) to warm the in-memory
  /// value from disk before the first frame that might need it.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(AppConstants.prefIsPremiumKey) ?? false;
    _expiresAtMillis = prefs.getInt(AppConstants.prefPremiumExpiresAtKey);
    notifyListeners();
  }

  /// TODO(payment-integration): this is the one method a real purchase
  /// flow needs to call.
  ///   - Google Play Billing: call this from the `purchaseUpdated`
  ///     stream handler after verifying the purchase (ideally verified
  ///     server-side, not just on-device).
  ///   - Your own pos_api license key: call this after `pos_api/`
  ///     confirms the key/subscription is valid, passing its expiry.
  /// [expiresAtMillis] null means lifetime/no expiry (e.g. a one-time
  /// unlock); pass a real timestamp for a subscription.
  Future<void> setPremium(bool value, {int? expiresAtMillis}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsPremiumKey, value);
    if (expiresAtMillis != null) {
      await prefs.setInt(AppConstants.prefPremiumExpiresAtKey, expiresAtMillis);
    } else {
      await prefs.remove(AppConstants.prefPremiumExpiresAtKey);
    }
    _isPremium = value;
    _expiresAtMillis = expiresAtMillis;
    notifyListeners();
  }

  /// Features that stay free even on the free plan — kept as an explicit
  /// allow-list so a newly added [PremiumFeature] defaults to LOCKED
  /// rather than accidentally free.
  static const Set<PremiumFeature> _alwaysFree = {};

  bool isUnlocked(PremiumFeature feature) {
    if (_alwaysFree.contains(feature)) return true;
    return isPremium;
  }
}
