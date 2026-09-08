import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/customer.dart';
import '../../core/services/app_state.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_gate.dart';
import 'contact_form_sheet.dart';
import 'contact_statement_screen.dart';
import '../../core/utils/app_format.dart';

/// Tab 4 of [MainShell] — the full Khatabook/Vyapar-style ledger:
/// Customers/Suppliers tabs, a summary bar, search, and a per-contact
/// "یاد دہانی" via [ContactStatementScreen]. Suppliers are
/// [PremiumFeature.supplierLedger] — the tab itself is always visible
/// (so a free-plan shopkeeper can see it exists) but switching to it
/// prompts the upgrade dialog until unlocked, per [PremiumGate].
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();

  List<Customer> _customers = [];
  List<Customer> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && !PremiumService.instance.isUnlocked(PremiumFeature.supplierLedger)) {
      // Bounce back to Customers immediately and show the upsell — the
      // Suppliers tab content never actually renders while locked.
      _tabController.index = 0;
      PremiumGate.ensure(context, PremiumFeature.supplierLedger, featureLabel: 'سپلائر کھاتہ');
    }
  }

  Future<void> _load([String query = '']) async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    setState(() => _loading = true);
    final customers = await CustomerService.instance.search(business.uuid, query, type: AppConstants.contactTypeCustomer);
    final suppliers = await CustomerService.instance.search(business.uuid, query, type: AppConstants.contactTypeSupplier);
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _suppliers = suppliers;
      _loading = false;
    });
  }

  Future<void> _addContact() async {
    final isSupplierTab = _tabController.index == 1;
    final type = isSupplierTab ? AppConstants.contactTypeSupplier : AppConstants.contactTypeCustomer;

    if (isSupplierTab) {
      final ok = await PremiumGate.ensure(context, PremiumFeature.supplierLedger, featureLabel: 'سپلائر کھاتہ');
      if (!ok || !mounted) return;
    }

    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final added = await showModalBottomSheet<Customer?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ContactFormSheet(businessUuid: business.uuid, type: type),
    );
    if (added != null) await _load(_searchCtrl.text);
  }

  Future<void> _openStatement(Customer contact) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContactStatementScreen(contact: contact)));
    await _load(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final supplierLocked = !premium.isUnlocked(PremiumFeature.supplierLedger);

    return Scaffold(
      appBar: AppBar(
        title: const Text('کھاتہ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'گاہک'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('سپلائرز'),
                  if (supplierLocked) const Padding(padding: EdgeInsets.only(right: 6), child: PremiumLockBadge()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'نام یا فون نمبر تلاش کریں', prefixIcon: Icon(Icons.search)),
              onChanged: _load,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _contactListTab(_customers, isSupplierTab: false),
                supplierLocked ? _lockedSupplierTab() : _contactListTab(_suppliers, isSupplierTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedSupplierTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 36, color: AppColors.gold500),
            const SizedBox(height: 12),
            Text('سپلائر کھاتہ پریمیم فیچر ہے', style: AppFonts.body(fontSize: 14, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('سپلائرز کا کھاتہ دیکھنے کے لیے پریمیم پلان درکار ہے۔',
                style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => PremiumGate.ensure(context, PremiumFeature.supplierLedger, featureLabel: 'سپلائر کھاتہ'),
              child: const Text('اپ گریڈ کریں'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactListTab(List<Customer> contacts, {required bool isSupplierTab}) {
    final receivable = contacts.where((c) => c.currentBalance > 0).fold<double>(0, (s, c) => s + c.currentBalance);
    final payable = contacts.where((c) => c.currentBalance < 0).fold<double>(0, (s, c) => s + c.currentBalance.abs());

    return RefreshIndicator(
      onRefresh: () => _load(_searchCtrl.text),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _summaryTile('آپ کو ملنا ہے', receivable, AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _summaryTile('آپ نے دینا ہے', payable, AppColors.danger)),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
          else if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  isSupplierTab
                      ? 'ابھی تک کوئی سپلائر شامل نہیں — نیچے دیے بٹن سے شامل کریں'
                      : 'ابھی تک کوئی گاہک شامل نہیں — بل بناتے وقت یا نیچے دیے بٹن سے شامل کریں',
                  style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final c in contacts) _contactTile(c),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text(AppFormat.currency(value), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _contactTile(Customer c) {
    final color = c.currentBalance > 0
        ? AppColors.success
        : c.currentBalance < 0
            ? AppColors.danger
            : AppColors.inkSoft;
    return InkWell(
      onTap: () => _openStatement(c),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w600)),
                  if (c.phone != null) Text(c.phone!, style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            Text(
              c.currentBalance == 0 ? 'برابر' : AppFormat.currency(c.currentBalance.abs()),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
