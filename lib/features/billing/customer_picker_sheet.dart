import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/models/customer.dart';
import '../../core/services/customer_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_format.dart';

/// Bottom sheet for Billing's customer selection step. Returns the
/// chosen [Customer], or `null` for "واک اِن گاہک" (walk-in, no ledger
/// entry). Includes a quick "+ گاہک شامل کریں" so Billing never has to
/// block on the full Customer/Ledger screens Phase 3 will add.
class CustomerPickerSheet extends StatefulWidget {
  final String businessUuid;
  const CustomerPickerSheet({super.key, required this.businessUuid});

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  List<Customer> _customers = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    final list = await CustomerService.instance.search(widget.businessUuid, query);
    if (!mounted) return;
    setState(() {
      _customers = list;
      _loading = false;
    });
  }

  Future<void> _quickAdd() async {
    final nameCtrl = TextEditingController(text: _searchCtrl.text);
    final phoneCtrl = TextEditingController();

    Future<void> pickFromContacts() async {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('کانٹیکٹس کی اجازت نہیں ملی — نمبر خود لکھ دیں')));
        }
        return;
      }
      final picked = await FlutterContacts.openExternalPick();
      if (picked == null) return;
      // openExternalPick() sometimes returns a contact without its phone
      // numbers hydrated yet — re-fetch the full record by id to be sure.
      final full = await FlutterContacts.getContact(picked.id) ?? picked;
      final phone = full.phones.isNotEmpty ? full.phones.first.number : null;
      if (phone != null && phone.trim().isNotEmpty) phoneCtrl.text = phone.trim();
      // Never overwrite a name the shopkeeper already typed.
      if (nameCtrl.text.trim().isEmpty && full.displayName.trim().isNotEmpty) {
        nameCtrl.text = full.displayName.trim();
      }
    }

    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نیا گاہک شامل کریں'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'نام')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'فون نمبر (اختیاری)'),
                  ),
                ),
                const SizedBox(width: 6),
                // FEATURE 3 (Google AI Studio prompt): pick straight from
                // the device's contact book instead of typing. Manual
                // typing above keeps working exactly as before if the
                // person declines the permission or has no contacts app.
                IconButton(
                  onPressed: pickFromContacts,
                  icon: const Icon(Icons.contact_phone_outlined, color: AppColors.teal700),
                  tooltip: 'کانٹیکٹس سے منتخب کریں',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('منسوخ کریں')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('شامل کریں')),
        ],
      ),
    );
    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      final customer = await CustomerService.instance.quickAdd(
        businessUuid: widget.businessUuid,
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop<Customer?>(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('گاہک منتخب کریں', style: AppFonts.body(fontSize: 15, weight: FontWeight.w700))),
                TextButton.icon(onPressed: _quickAdd, icon: const Icon(Icons.person_add_alt, size: 18), label: const Text('نیا')),
              ],
            ),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(hintText: 'نام یا فون نمبر تلاش کریں', prefixIcon: Icon(Icons.search)),
              onChanged: _load,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: AppColors.teal100, child: Icon(Icons.person_outline, color: AppColors.teal800)),
              title: const Text('واک اِن گاہک (بغیر کھاتے کے)'),
              onTap: () => Navigator.of(context).pop<Customer?>(null),
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _customers.length,
                      itemBuilder: (context, i) {
                        final c = _customers[i];
                        final due = c.currentBalance;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(backgroundColor: AppColors.paper, child: Icon(Icons.person_outline)),
                          title: Text(c.name),
                          subtitle: c.phone != null ? Text(c.phone!) : null,
                          trailing: due == 0
                              ? null
                              : Text(
                                  AppFormat.currency(due.abs()),
                                  style: TextStyle(
                                    color: due > 0 ? AppColors.success : AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          onTap: () => Navigator.of(context).pop<Customer?>(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
