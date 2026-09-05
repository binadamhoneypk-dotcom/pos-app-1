import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/customer.dart';
import '../../core/services/app_state.dart';
import '../../core/services/billing_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calculator_fab.dart';
import 'add_bill_item_screen.dart';
import 'customer_picker_sheet.dart';

/// "کسٹمر منتخب کرتے ہی اس کا پرانا بقایا (old due) فوری طور پر نام کے
/// نیچے ایک رنگین banner میں نظر آئے (سرخ = آپ نے دینا ہے / سبز = آپ کو
/// ملنا ہے) — نیا بل بننے سے پہلے ہی۔"
class NewBillScreen extends StatefulWidget {
  const NewBillScreen({super.key});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  Customer? _customer;
  final List<BillLineItem> _lines = [];
  final _paidCtrl = TextEditingController();
  bool _saving = false;

  double get _total => _lines.fold<double>(0, (sum, l) => sum + l.lineTotal);

  Future<void> _pickCustomer() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final result = await showModalBottomSheet<Customer?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => CustomerPickerSheet(businessUuid: business.uuid),
    );
    setState(() => _customer = result);
  }

  Future<void> _addItem() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final line = await Navigator.of(context).push<BillLineItem>(
      MaterialPageRoute(builder: (_) => AddBillItemScreen(businessUuid: business.uuid)),
    );
    if (line != null) setState(() => _lines.add(line));
  }

  Future<void> _saveBill() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بل میں کم از کم ایک چیز شامل کریں')));
      return;
    }
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;

    final paid = double.tryParse(_paidCtrl.text) ?? _total;
    setState(() => _saving = true);
    await BillingService.instance.createSale(
      businessUuid: business.uuid,
      customerUuid: _customer?.uuid,
      lines: _lines,
      paidAmount: paid,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نیا بل')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Text('گاہک کا نام (اختیاری)', style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickCustomer,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: AppColors.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_customer?.name ?? 'واک اِن گاہک — تبدیل کرنے کے لیے دبائیں'),
                      ),
                      const Icon(Icons.chevron_left, size: 18, color: AppColors.inkSoft),
                    ],
                  ),
                ),
              ),
              if (_customer != null && _customer!.currentBalance != 0) ...[
                const SizedBox(height: 8),
                _dueBanner(_customer!),
              ],
              const SizedBox(height: 20),

              for (int i = 0; i < _lines.length; i++) _billRow(_lines[i], i),

              const SizedBox(height: 6),
              Material(
                color: AppColors.teal100,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _addItem,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text('+ نئی چیز شامل کریں',
                          style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.teal900, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('کل رقم', style: AppFonts.body(fontSize: 13, color: Colors.white70)),
                    Text('Rs ${_total.toStringAsFixed(0)}',
                        style: AppFonts.body(fontSize: 20, color: Colors.white, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _paidCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'وصول شدہ رقم (خالی چھوڑیں تو مکمل رقم وصول ظاہر ہوگی)',
                  prefixText: 'Rs ',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _saveBill,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('بل محفوظ کریں'),
              ),
            ],
          ),
          CalculatorFab(onInsertResult: (v) => setState(() => _paidCtrl.text = v.toStringAsFixed(0))),
        ],
      ),
    );
  }

  Widget _dueBanner(Customer customer) {
    final owesUs = customer.currentBalance > 0;
    final color = owesUs ? AppColors.success : AppColors.danger;
    final label = owesUs
        ? 'پرانا بقایا — آپ کو ملنا ہے: Rs ${customer.currentBalance.toStringAsFixed(0)}'
        : 'پرانا بقایا — آپ نے دینا ہے: Rs ${customer.currentBalance.abs().toStringAsFixed(0)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }

  Widget _billRow(BillLineItem line, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(line.name, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w600))),
          Text('× ${line.quantity.toStringAsFixed(line.quantity == line.quantity.roundToDouble() ? 0 : 2)}',
              style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft)),
          const SizedBox(width: 10),
          Text('Rs ${line.lineTotal.toStringAsFixed(0)}',
              style: AppFonts.body(fontSize: 13.5, color: AppColors.teal800, weight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.inkSoft),
            onPressed: () => setState(() => _lines.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
