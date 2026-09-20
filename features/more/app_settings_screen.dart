import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

/// "زبان (Urdu/English) صرف Settings ('مزید' → 'ایپ کی سیٹنگز') میں ایک
/// بار سیٹ ہو، پوری ایپ پر خودکار لاگو ہو۔" — this screen is that single
/// switch, plus (Google AI Studio prompt, Feature 2) currency symbol,
/// dark mode, and the low-stock threshold, all persisted via
/// `shared_preferences` through [AppState]'s setters.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _lowStockCtrl;

  @override
  void initState() {
    super.initState();
    _currencyCtrl = TextEditingController(text: AppFormat.currencySymbol);
    _lowStockCtrl = TextEditingController(text: AppConstants.lowStockThreshold.toString());
  }

  @override
  void dispose() {
    _currencyCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  void _saveCurrency() {
    final t = AppLocalizations.of(context)!;
    final value = _currencyCtrl.text.trim();
    if (value.isEmpty) return;
    context.read<AppState>().setCurrencySymbol(value);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.currencySaved)));
  }

  void _saveLowStock() {
    final t = AppLocalizations.of(context)!;
    final value = int.tryParse(_lowStockCtrl.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.invalidNumber)));
      return;
    }
    context.read<AppState>().setLowStockThreshold(value);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.lowStockSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentCode = appState.locale.languageCode;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(t.language),
          RadioListTile<String>(
            value: 'ur',
            groupValue: currentCode,
            title: Text(t.urdu),
            onChanged: (v) => context.read<AppState>().setLanguage(v!),
          ),
          RadioListTile<String>(
            value: 'en',
            groupValue: currentCode,
            title: Text(t.english),
            onChanged: (v) => context.read<AppState>().setLanguage(v!),
          ),

          const SizedBox(height: 20),
          _sectionTitle(t.currencySymbol),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _currencyCtrl,
                  decoration: InputDecoration(hintText: t.currencyHint),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _saveCurrency, child: Text(t.save)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(t.currencyHelp,
                style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
          ),

          const SizedBox(height: 20),
          _sectionTitle(t.darkMode),
          const SizedBox(height: 4),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: appState.themeMode,
            title: Text(t.themeSystem),
            onChanged: (v) => context.read<AppState>().setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: appState.themeMode,
            title: Text(t.themeLight),
            onChanged: (v) => context.read<AppState>().setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: appState.themeMode,
            title: Text(t.themeDark),
            onChanged: (v) => context.read<AppState>().setThemeMode(v!),
          ),

          const SizedBox(height: 20),
          _sectionTitle(t.lowStockThreshold),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _lowStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: t.lowStockHint),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _saveLowStock, child: Text(t.save)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              t.lowStockHelp,
              style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700));
}
