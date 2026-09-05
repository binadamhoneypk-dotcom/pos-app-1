import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/theme/app_theme.dart';

/// "زبان (Urdu/English) صرف Settings ('مزید' → 'ایپ کی سیٹنگز') میں ایک
/// بار سیٹ ہو، پوری ایپ پر خودکار لاگو ہو — ہر سکرین پر الگ سوئچ نہ ہو۔"
/// This screen is that single switch; [AppState.setLanguage] (Phase 1)
/// already propagates it app-wide via [MaterialApp.locale].
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentCode = appState.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: const Text('ایپ کی سیٹنگز')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('زبان', style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}
