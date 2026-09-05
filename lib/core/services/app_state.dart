import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/business.dart';
import '../models/business_user.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Root app state: who is logged in, which business is currently active,
/// and which language is selected. Every screen listens to this via
/// Provider instead of re-reading storage directly.
class AppState extends ChangeNotifier {
  User? currentUser;
  Business? currentBusiness;
  BusinessUser? currentBusinessRole;
  Locale locale = const Locale('ur'); // Urdu default, per project requirement

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

  Future<void> logout() async {
    await AuthService.instance.logout();
    currentUser = null;
    currentBusiness = null;
    currentBusinessRole = null;
    availableBusinesses = [];
    notifyListeners();
  }
}
