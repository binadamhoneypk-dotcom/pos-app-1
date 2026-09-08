import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/customer.dart';
import '../../core/services/customer_service.dart';
import '../../core/theme/app_theme.dart';

/// "+ گاہک/سپلائر شامل کریں" bottom sheet — [type] decides which label
/// and table filter the new contact is saved under (see [Customer.type]).
/// Returns the created [Customer] so the caller can refresh its list.
class ContactFormSheet extends StatefulWidget {
  final String businessUuid;
  final String type; // AppConstants.contactTypeCustomer / contactTypeSupplier

  const ContactFormSheet({super.key, required this.businessUuid, required this.type});

  @override
  State<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<ContactFormSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController();
  bool _saving = false;

  bool get _isSupplier => widget.type == AppConstants.contactTypeSupplier;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final rawOpening = double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0;
    // For a supplier the natural "opening balance" the shopkeeper types
    // is "ہم ان کے کتنے مقروض ہیں" (a positive number in their head), but
    // the stored sign convention needs it negative (shop owes them) —
    // flip it here so the form field can stay intuitive.
    final openingBalance = _isSupplier ? -rawOpening.abs() : rawOpening;

    final customer = await CustomerService.instance.quickAdd(
      businessUuid: widget.businessUuid,
      name: name,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      type: widget.type,
      openingBalance: openingBalance,
    );
    if (mounted) Navigator.of(context).pop<Customer?>(customer);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSupplier ? 'نیا سپلائر شامل کریں' : 'نیا گاہک شامل کریں';
    final openingLabel = _isSupplier ? 'ابتدائی بقایا (ہم پر واجب) — اختیاری' : 'ابتدائی بقایا (ان پر واجب) — اختیاری';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.body(fontSize: 16, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'نام'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'فون نمبر (اختیاری)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _openingBalanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: openingLabel),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving || _nameCtrl.text.trim().isEmpty ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('محفوظ کریں'),
            ),
          ),
        ],
      ),
    );
  }
}
