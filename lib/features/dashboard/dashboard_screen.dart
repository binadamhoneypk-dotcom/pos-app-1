import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/item_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calculator_fab.dart';
import '../billing/new_bill_screen.dart';
import '../inventory/item_form_screen.dart';
import '../ledger/ledger_screen.dart';
import 'widgets/zakat_card.dart';

/// Tab 1 of [MainShell]. Replaces Phase 1's placeholder HomeScreen with
/// the approved layout: sync card, welcome row, two stat cards, the
/// collapsed Zakat card, and a quick-access menu grid — all matching
/// the HTML prototype's `#screen-home` section exactly.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _syncing = false;
  String? _syncMessage;
  double _todaysSales = 0;
  int _lowStockCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final sales = await BillingService.instance.todaysSalesTotal(business.uuid);
    final lowStock = await ItemService.instance.getLowStock(business.uuid);
    if (!mounted) return;
    setState(() {
      _todaysSales = sales;
      _lowStockCount = lowStock.length;
      _loadingStats = false;
    });
  }

  Future<void> _runSync() async {
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });
    final business = context.read<AppState>().currentBusiness;
    final result = await SyncService.instance.syncAll(businessUuid: business?.uuid);
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _syncMessage = result.success
          ? 'مطابقت مکمل ہوئی — بھیجا گیا: ${result.pushed}, وصول کیا: ${result.pulled}'
          : result.message;
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final business = appState.currentBusiness;
    final role = appState.currentBusinessRole;

    return Scaffold(
      appBar: AppBar(
        title: Text(business?.name ?? 'ڈیش بورڈ'),
        actions: [
          if (appState.availableBusinesses.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'دکان تبدیل کریں',
              onPressed: () => _switchBusiness(context),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'لاگ آؤٹ',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadStats,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                _syncCard(),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: AppFonts.body(fontSize: 13.5, color: AppColors.inkSoft),
                    children: [
                      const TextSpan(text: 'خوش آمدید، آپ کا کردار: '),
                      TextSpan(
                        text: _roleLabel(role?.role),
                        style: AppFonts.body(fontSize: 13.5, color: AppColors.ink, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: '💰',
                        value: _loadingStats ? '...' : 'Rs ${_todaysSales.toStringAsFixed(0)}',
                        label: 'آج کی فروخت',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        icon: '📦',
                        value: _loadingStats ? '...' : '$_lowStockCount',
                        label: 'کم اسٹاک اشیاء',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (business != null) ZakatCard(business: business),
                const SizedBox(height: 18),
                _menuGrid(context),
              ],
            ),
          ),
          const CalculatorFab(),
        ],
      ),
    );
  }

  Widget _syncCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.teal100, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Text('☁️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _syncMessage ?? 'ڈیٹا مقامی طور پر محفوظ ہے۔ انٹرنیٹ آنے پر خودکار مطابقت ہوگی۔',
              style: AppFonts.body(fontSize: 12.5, color: AppColors.teal900),
            ),
          ),
          _syncing
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: _runSync,
                  child: Text('ابھی مطابقت کریں',
                      style: AppFonts.body(fontSize: 12.5, color: AppColors.teal700, weight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }

  Widget _statCard({required String icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value, style: AppFonts.body(fontSize: 19, color: AppColors.teal900, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _menuGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _menuItem('🧾', 'بل بنائیں', 'گاہک کا بل تیار کریں',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const NewBillScreen()))
                .then((_) => _loadStats())),
        _menuItem('📋', 'مال کی فہرست', 'دکان کا سامان (انوینٹری)',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ItemFormScreen()))
                .then((_) => _loadStats())),
        _menuItem('📒', 'گاہک کا کھاتہ', 'ادھار اور واجب الادا رقم',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LedgerScreen()))),
        _menuItem('🧮', 'کیلکولیٹر', 'ہر سکرین پر بھی دستیاب',
            onTap: () {}),
        _menuItem('📊', 'رپورٹس', 'فیز 4', disabled: true, tag: 'فیز 4'),
        _menuItem('👥', 'عملہ', 'فیز 3', disabled: true, tag: 'فیز 3'),
      ],
    );
  }

  Widget _menuItem(String icon, String label, String hint,
      {VoidCallback? onTap, bool disabled = false, String? tag}) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(label, style: AppFonts.body(fontSize: 13, weight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                tag ?? hint,
                style: AppFonts.body(fontSize: 10.5, color: AppColors.inkSoft),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'owner':
        return 'مالک';
      case 'manager':
        return 'منیجر';
      case 'staff':
        return 'عملہ';
      default:
        return '-';
    }
  }

  void _switchBusiness(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/business-switch');
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AppState>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
