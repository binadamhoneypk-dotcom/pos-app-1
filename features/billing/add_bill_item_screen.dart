import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/models/item.dart';
import '../../core/services/billing_service.dart';
import '../../core/services/item_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_gate.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

/// "+ نئی چیز شامل کریں" پر ایک الگ سکرین کھلے جس میں دو حصے ہوں:
/// (1) انوینٹری میں سے search/select کرنا، (2) بار کوڈ/QR کیمرے سے
/// سکین کرنا (segmented control سے سوئچ ہو)۔
///
/// Pops with a [BillLineItem] once the user has chosen an item + qty,
/// or `null` if they back out.
class AddBillItemScreen extends StatefulWidget {
  final String businessUuid;
  const AddBillItemScreen({super.key, required this.businessUuid});

  @override
  State<AddBillItemScreen> createState() => _AddBillItemScreenState();
}

class _AddBillItemScreenState extends State<AddBillItemScreen> {
  int _mode = 0; // 0 = search/select, 1 = scan
  List<Item> _items = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  final _scannerController = MobileScannerController();
  bool _scanHandled = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final items = await ItemService.instance.search(widget.businessUuid, q);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _pickItem(Item item) async {
    final qty = await _askQuantity(item);
    if (qty == null || qty <= 0) return;
    if (!mounted) return;
    Navigator.of(context).pop(
      BillLineItem(itemUuid: item.uuid, name: item.name, unitPrice: item.salePrice, quantity: qty, unit: item.unit),
    );
  }

  Future<double?> _askQuantity(Item item) async {
    final t = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: '1');
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.quantityUnitLabel(item.unit)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(ctrl.text) ?? 1),
            child: Text(t.add),
          ),
        ],
      ),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_scanHandled) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;
    _scanHandled = true;

    final item = await ItemService.instance.findByBarcode(widget.businessUuid, code);
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;

    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.barcodeNotFoundMessage(code))),
      );
      _scanHandled = false;
      return;
    }
    await _pickItem(item);
    _scanHandled = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.addNewItemTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(t.searchButton), icon: const Icon(Icons.search)),
                ButtonSegment(value: 1, label: Text(t.scanBarcodeButton), icon: const Icon(Icons.qr_code_scanner)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) async {
                final target = s.first;
                if (target == 1) {
                  final ok = await PremiumGate.ensure(context, PremiumFeature.barcodeAutoScan,
                      featureLabel: t.autoBarcodeScanFeature);
                  if (!ok) return;
                }
                setState(() => _mode = target);
              },
            ),
          ),
          Expanded(child: _mode == 0 ? _searchView() : _scanView()),
        ],
      ),
    );
  }

  Widget _searchView() {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(hintText: t.inventorySearchHint, prefixIcon: const Icon(Icons.search)),
            onChanged: _search,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(child: Text(t.noItemFoundMessage, style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final item = _items[i];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(t.stockLabel(item.quantity.toStringAsFixed(0), item.unit)),
                          trailing: Text(AppFormat.currency(item.salePrice),
                              style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
                          onTap: () => _pickItem(item),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _scanView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(controller: _scannerController, onDetect: _onBarcodeDetected),
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold500, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
