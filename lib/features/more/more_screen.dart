import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_gate.dart';
import '../employees/employee_list_screen.dart';
import '../premium/upgrade_screen.dart';
import '../zakat/zakat_calculator_screen.dart';
import 'app_settings_screen.dart';
import 'letterhead_settings_screen.dart';

/// Tab 5 of [MainShell] — "مزید". Houses everything that doesn't need
/// its own bottom-nav slot: language switch (per the locked design,
/// this is the ONLY place language is changed), bill letterhead
/// settings, the Zakat Calculator, manual sync, and logout.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final business = context.read<AppState>().currentBusiness;
    final result = await SyncService.instance.syncAll(businessUuid: business?.uuid);
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _openZakatCalculator(BuildContext context) async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final ok = await PremiumGate.ensure(context, PremiumFeature.zakatCalculator,
        featureLabel: 'مکمل زکوٰۃ کیلکولیٹر');
    if (!ok || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()));
  }

  Future<void> _openEmployeeLedger(BuildContext context) async {
    final role = context.read<AppState>().currentBusinessRole;
    if (role != null && !role.canManageStaff) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ملازمین کا کھاتہ دیکھنے کی اجازت صرف مالک/منیجر کو ہے')));
      return;
    }
    final ok = await PremiumGate.ensure(context, PremiumFeature.staffAccounts, featureLabel: 'ملازمین کا کھاتہ');
    if (!ok || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmployeeListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final premium = context.watch<PremiumService>();
    return Scaffold(
      appBar: AppBar(title: const Text('مزید')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.gold100, Colors.white]),
                  border: Border.all(color: const Color(0xFFEAD9A0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, color: AppColors.gold500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        premium.isPremium ? 'پریمیم پلان فعال ہے' : 'پریمیم پلان کی تفصیلات دیکھیں',
                        style: AppFonts.body(fontSize: 13, color: AppColors.zakatText, weight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: AppColors.zakatTextSoft, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.settings_outlined, 'ایپ کی سیٹنگز', 'زبان (اردو/انگریزی)',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppSettingsScreen()))),
          _tile(Icons.receipt_long_outlined, 'بل کی سیٹنگز', 'لوگو، واٹرمارک، فونٹ (Phase 4 میں مکمل اطلاق)',
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LetterheadSettingsScreen()))),
          _tile(
            Icons.mosque_outlined,
            'زکوٰۃ کیلکولیٹر',
            'نصاب، شروع کی تاریخ، حساب',
            trailing: premium.isUnlocked(PremiumFeature.zakatCalculator) ? null : const PremiumLockBadge(),
            onTap: appState.currentBusiness == null ? null : () => _openZakatCalculator(context),
          ),
          _tile(
            Icons.groups_outlined,
            'ملازمین کا کھاتہ',
            'تنخواہ، ایڈوانس، حاضری',
            trailing: premium.isUnlocked(PremiumFeature.staffAccounts) ? null : const PremiumLockBadge(),
            onTap: appState.currentBusiness == null ? null : () => _openEmployeeLedger(context),
          ),
          const Divider(height: 24),
          _tile(
            Icons.cloud_sync_outlined,
            'ابھی مطابقت کریں',
            'مقامی ڈیٹا سرور سے ملائیں',
            trailing: _syncing ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
            onTap: _syncing ? null : _sync,
          ),
          _tile(Icons.info_outline, 'ایپ کے بارے میں', 'دکان مینجمنٹ ایپ — Phase 2', onTap: () => _showAbout(context)),
          const Divider(height: 24),
          _tile(
            Icons.logout,
            'لاگ آؤٹ',
            null,
            iconColor: AppColors.danger,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String? subtitle,
      {VoidCallback? onTap, Widget? trailing, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.teal700),
      title: Text(title, style: AppFonts.body(fontSize: 14, weight: FontWeight.w600, color: iconColor)),
      subtitle: subtitle != null ? Text(subtitle, style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_left, color: AppColors.inkSoft, size: 18),
      onTap: onTap,
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'دکان مینجمنٹ ایپ',
      applicationVersion: 'Phase 2',
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('لاگ آؤٹ کریں؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('منسوخ کریں')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('لاگ آؤٹ')),
        ],
      ),
    );
    if (confirm != true) return;
    await context.read<AppState>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
