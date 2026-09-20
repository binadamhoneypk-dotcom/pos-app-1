import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/sale.dart';
import '../../core/services/app_state.dart';
import '../../core/services/billing_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calculator_fab.dart';
import 'new_bill_screen.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

/// Tab 2 of [MainShell]. Landing page for Billing: past bills newest
/// first, with a "+ نیا بل" FAB opening [NewBillScreen].
class BillingListScreen extends StatefulWidget {
  const BillingListScreen({super.key});

  @override
  State<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends State<BillingListScreen> {
  List<Sale> _sales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    setState(() => _loading = true);
    final sales = await BillingService.instance.getSalesForBusiness(business.uuid);
    if (!mounted) return;
    setState(() {
      _sales = sales;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.billingTitle)),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _sales.isEmpty
                  ? Center(
                      child: Text(t.noBillsYetMessage,
                          style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        itemCount: _sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _saleTile(_sales[i]),
                      ),
                    ),
          const CalculatorFab(),
          Positioned(
            bottom: 18,
            right: 18,
            child: FloatingActionButton(
              heroTag: 'billing_new_fab',
              backgroundColor: AppColors.teal700,
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const NewBillScreen()))
                  .then((_) => _load()),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saleTile(Sale sale) {
    final t = AppLocalizations.of(context)!;
    final date = DateTime.fromMillisecondsSinceEpoch(sale.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.teal100, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long, color: AppColors.teal800, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppFormat.currency(sale.totalAmount),
                    style: AppFonts.body(fontSize: 14, weight: FontWeight.w700)),
                Text(DateFormat('d MMM yyyy, h:mm a').format(date),
                    style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          if (sale.dueAmount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(t.dueAmountBadge(AppFormat.currency(sale.dueAmount)),
                  style: AppFonts.body(fontSize: 10.5, color: AppColors.danger, weight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
