/// Central place for values that Phase 2+ modules will also depend on.
/// Keeping these here means the schema/API base can be changed in ONE place.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------
  // BACKEND CONFIG — hosting-agnostic on purpose. Point this at XAMPP while
  // developing, then at InfinityFree/Hostinger once you deploy the PHP API.
  // Never hardcode this anywhere else in the app; always read from here.
  // ---------------------------------------------------------------------
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Default for local development against XAMPP.
    // Android emulator uses 10.0.2.2 to reach the host machine's localhost.
    defaultValue: 'http://10.0.2.2/pos_api',
  );

  static const Duration apiTimeout = Duration(seconds: 15);

  // ---------------------------------------------------------------------
  // DATABASE
  // ---------------------------------------------------------------------
  static const String dbName = 'pos_app.db';
  // v2 (Phase 2): adds items, customers, sales, sale_items. See
  // DBHelper._upgradeSchema — existing installs migrate without losing data.
  static const int dbVersion = 2;

  static const String tableUsers = 'users';
  static const String tableBusinesses = 'businesses';
  static const String tableBusinessUsers = 'business_users';
  static const String tableSyncLog = 'sync_log';

  // ---- Phase 2 tables --------------------------------------------------
  static const String tableItems = 'items';
  static const String tableCustomers = 'customers';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';

  // ---------------------------------------------------------------------
  // ROLES — used by Phase 2/3 to gate screens & actions
  // ---------------------------------------------------------------------
  static const String roleOwner = 'owner';
  static const String roleManager = 'manager';
  static const String roleStaff = 'staff';

  // ---------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------
  static const String prefLastSyncKey = 'last_sync_at';
  static const String prefSessionUserKey = 'session_user_uuid';
  static const String prefSessionTokenKey = 'session_token';
  static const String prefLanguageKey = 'app_language'; // 'ur' or 'en'

  // ---------------------------------------------------------------------
  // PHASE 2 — INVENTORY
  // ---------------------------------------------------------------------

  /// Default category list shown in the Inventory form's dropdown. The
  /// last entry ("دیگر") lets the shopkeeper type a custom category —
  /// see [ItemFormScreen]. Kept as a flat constant list rather than a
  /// separate synced table because the locked design only calls for a
  /// dropdown, not full category management.
  static const List<String> defaultItemCategories = [
    'گروسری',
    'مشروبات',
    'ادویات',
    'کاسمیٹکس',
    'الیکٹرانکس',
    'کھانے پینے کی اشیاء',
    'کپڑے',
    'پرزہ جات (اسپیئر پارٹس)',
    'دیگر',
  ];

  /// Quantity at or below this is flagged "کم اسٹاک" on the Dashboard and
  /// Inventory list.
  static const int lowStockThreshold = 5;

  // ---------------------------------------------------------------------
  // PHASE 2 — ZAKAT
  // ---------------------------------------------------------------------

  /// Approximate lunar (Hijri) year length in days, as agreed in the
  /// locked design ("قمری سال (تقریباً 354 دن)"). Used only for the
  /// supporting estimate shown to the user — not a substitute for a
  /// proper Hijri calendar calculation.
  static const int lunarYearApproxDays = 354;

  /// Classical nisab reference weights, used when the user has not typed
  /// a manual nisab amount directly.
  static const double nisabGoldGrams = 87.48; // ~7.5 tola
  static const double nisabSilverGrams = 612.36; // ~52.5 tola

  static const String prefZakatUseSilverStandardKey = 'zakat_use_silver_standard';
  static const String prefManualGoldRateKey = 'zakat_manual_gold_rate_per_gram';
  static const String prefManualSilverRateKey = 'zakat_manual_silver_rate_per_gram';

  /// Optional live metal-rate API. Empty by default — the Zakat
  /// Calculator falls back to manual rate entry until you configure a
  /// provider (e.g. metals-api.com, metalpriceapi.com, goldapi.io) and
  /// pass its base URL + key at build time, exactly like [apiBaseUrl]:
  ///   flutter run --dart-define=METAL_RATE_API_URL=... --dart-define=METAL_RATE_API_KEY=...
  /// See lib/core/services/metal_rate_service.dart for the expected
  /// response shape and where to adapt it to your chosen provider.
  static const String metalRateApiUrl = String.fromEnvironment('METAL_RATE_API_URL');
  static const String metalRateApiKey = String.fromEnvironment('METAL_RATE_API_KEY');

  // ---------------------------------------------------------------------
  // PHASE 2 — PREMIUM / FEATURE-LOCK (payment integration comes later —
  // see lib/core/services/premium_service.dart)
  // ---------------------------------------------------------------------

  static const String prefIsPremiumKey = 'is_premium';
  static const String prefPremiumExpiresAtKey = 'premium_expires_at';

  /// Free-tier caps. Kept as named constants (not magic numbers) so
  /// changing the free plan later is a one-line edit.
  static const int freeMaxItems = 100;
  static const int freeMaxBusinesses = 1;
}
