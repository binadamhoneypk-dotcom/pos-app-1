import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/business.dart';
import '../models/business_user.dart';
import '../models/user.dart';
import '../utils/app_format.dart';
import 'auth_service.dart';

/// Root app state: who is logged in, which business is currently active,
/// and which language is selected. Every screen listens to this via
/// Provider instead of re-reading storage directly.
class AppState extends ChangeNotifier {
  User? currentUser;
  Business? currentBusiness;
  BusinessUser? currentBusinessRole;
  Locale locale = const Locale('ur'); // Urdu default, per project requirement

  // ---- FEATURE 2: App Settings ----------------------------------------
  ThemeMode themeMode = ThemeMode.light;

  List<(Business, BusinessUser)> availableBusinesses = [];

  Future<void> loadSession() async {
    final userUuid = await AuthService.instance.getSessionUserUuid();
    if (userUuid == null) return;

    // In Phase 1 we only keep the uuid in secure storage; re-hydrate the
    // full User + business list from the local DB. PHASE 2: also
    // restores currentUser itself — Phase 1 left it null after a cold
    // start, which broke anything (like adding a second business) that
    // needs the logged-in user's uuid outside the fresh-login flow.
    currentUser ??= await AuthService.instance.getUserByUuid(userUuid);
    final list = await AuthService.instance.businessesForUser(userUuid);
    availableBusinesses = list;
    if (list.isNotEmpty) {
      currentBusiness = list.first.$1;
      currentBusinessRole = list.first.$2;
    }
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(AppConstants.prefLanguageKey) ?? 'ur';
    locale = Locale(lang);

    // FEATURE 2 settings — read once at startup; AppFormat.currencySymbol
    // and AppConstants.lowStockThreshold are plain mutable statics (see
    // their doc comments) so every screen/service picks up the saved
    // value without needing a BuildContext.
    AppFormat.currencySymbol = prefs.getString(AppConstants.prefCurrencyKey) ?? 'Rs';
    AppConstants.lowStockThreshold =
        prefs.getInt(AppConstants.prefLowStockThresholdKey) ?? AppConstants.lowStockThreshold;
    final themeModeStr = prefs.getString(AppConstants.prefThemeModeKey) ?? 'light';
    themeMode = _themeModeFromString(themeModeStr);

    notifyListeners();
  }

  /// Re-reads the business list after adding a new one (Phase 2's
  /// "+ نئی دکان شامل کریں"), without disturbing the currently active
  /// business/role.
  Future<void> reloadAvailableBusinesses() async {
    if (currentUser == null) return;
    availableBusinesses = await AuthService.instance.businessesForUser(currentUser!.uuid);
    notifyListeners();
  }

  Future<void> switchBusiness(Business business, BusinessUser role) async {
    currentBusiness = business;
    currentBusinessRole = role;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    locale = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLanguageKey, code);
    notifyListeners();
  }

  /// FEATURE 2 — "کرنسی سمبل/پریفکس". Updates [AppFormat.currencySymbol]
  /// (what every screen actually reads) and persists it in the same call.
  Future<void> setCurrencySymbol(String symbol) async {
    final trimmed = symbol.trim();
    if (trimmed.isEmpty) return;
    AppFormat.currencySymbol = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefCurrencyKey, trimmed);
    notifyListeners();
  }

  /// FEATURE 2 — three-way light/dark/system choice, wired into
  /// `MaterialApp.themeMode` in main.dart.
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeModeKey, _themeModeToString(mode));
    notifyListeners();
  }

  /// FEATURE 2 — "کم اسٹاک کی حد". Updates [AppConstants.lowStockThreshold]
  /// (what [ItemService.getLowStock] and [Item.isLowStock] both read) and
  /// persists it in the same call.
  Future<void> setLowStockThreshold(int threshold) async {
    if (threshold < 0) return;
    AppConstants.lowStockThreshold = threshold;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefLowStockThresholdKey, threshold);
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    currentUser = null;
    currentBusiness = null;
    currentBusinessRole = null;
    availableBusinesses = [];
    notifyListeners();
  }
}
