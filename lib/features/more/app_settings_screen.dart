import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_format.dart';

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
    final value = _currencyCtrl.text.trim();
    if (value.isEmpty) return;
    context.read<AppState>().setCurrencySymbol(value);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کرنسی محفوظ ہو گئی')));
  }

  void _saveLowStock() {
    final value = int.tryParse(_lowStockCtrl.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('درست نمبر درج کریں')));
      return;
    }
    context.read<AppState>().setLowStockThreshold(value);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کم اسٹاک کی حد محفوظ ہو گئی')));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentCode = appState.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('ایپ کی سیٹنگز')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('زبان'),
          RadioListTile<String>(
            value: 'ur',
            groupValue: currentCode,
            title: const Text('اردو'),
            onChanged: (v) => context.read<AppState>().setLanguage(v!),
          ),
          RadioListTile<String>(
            value: 'en',
            groupValue: currentCode,
            title: const Text('English'),
            onChanged: (v) => context.read<AppState>().setLanguage(v!),
          ),

          const SizedBox(height: 20),
          _sectionTitle('کرنسی سمبل'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _currencyCtrl,
                  decoration: const InputDecoration(hintText: 'مثلاً: Rs, ₨, PKR'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _saveCurrency, child: const Text('محفوظ کریں')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('یہ سمبل پوری ایپ میں ہر جگہ قیمت کے ساتھ استعمال ہوگا۔',
                style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
          ),

          const SizedBox(height: 20),
          _sectionTitle('ڈارک موڈ'),
          const SizedBox(height: 4),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: appState.themeMode,
            title: const Text('سسٹم کے مطابق'),
            onChanged: (v) => context.read<AppState>().setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: appState.themeMode,
            title: const Text('لائٹ (روشن)'),
            onChanged: (v) => context.read<AppState>().setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: appState.themeMode,
            title: const Text('ڈارک (تاریک)'),
            onChanged: (v) => context.read<AppState>().setThemeMode(v!),
          ),

          const SizedBox(height: 20),
          _sectionTitle('کم اسٹاک کی حد'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _lowStockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'مثلاً: 5'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _saveLowStock, child: const Text('محفوظ کریں')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'اس مقدار یا اس سے کم ہونے پر چیز "کم اسٹاک" میں شمار ہوگی۔',
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
