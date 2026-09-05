import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer.dart';
import '../../core/services/app_state.dart';
import '../../core/services/customer_service.dart';
import '../../core/theme/app_theme.dart';

/// Tab 4 of [MainShell]. The full Khatabook/Vyapar-style two-tab
/// (Customers/Suppliers) ledger with reminders is Phase 3 per the
/// roadmap. This Phase 2 version already shows real data from the same
/// `customers` table Billing writes to — so nothing here changes when
/// Phase 3 adds the Suppliers tab and reminder actions on top of it.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Customer> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final list = await CustomerService.instance.getAll(business.uuid);
    if (!mounted) return;
    setState(() {
      _customers = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final receivable = _customers.where((c) => c.currentBalance > 0).fold<double>(0, (s, c) => s + c.currentBalance);
    final payable = _customers.where((c) => c.currentBalance < 0).fold<double>(0, (s, c) => s + c.currentBalance.abs());

    return Scaffold(
      appBar: AppBar(title: const Text('گاہک کا کھاتہ')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.teal100, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      'مکمل کھاتہ (سپلائرز، یاد دہانی، اور ملازمین کا کھاتہ) فیز 3 میں شامل ہوگا۔ نیچے دی گئی فہرست بلنگ کے ذریعے محفوظ ہونے والا اصل ڈیٹا ہے۔',
                      style: AppFonts.body(fontSize: 11.5, color: AppColors.teal900),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_customers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('ابھی تک کوئی گاہک شامل نہیں — بل بناتے وقت گاہک شامل کریں',
                            style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
                      ),
                    )
                  else
                    for (final c in _customers) _customerTile(c),
                ],
              ),
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
          Text('Rs ${value.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _customerTile(Customer c) {
    final color = c.currentBalance > 0
        ? AppColors.success
        : c.currentBalance < 0
            ? AppColors.danger
            : AppColors.inkSoft;
    return Container(
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
            c.currentBalance == 0 ? 'برابر' : 'Rs ${c.currentBalance.abs().toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
