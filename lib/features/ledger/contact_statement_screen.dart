import 'package:flutter/material.dart';
import '../../core/models/customer.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/services/customer_service.dart';
import '../../core/theme/app_theme.dart';
import 'reminder_helper.dart';
import '../../core/utils/app_format.dart';

/// Tapping a contact in [LedgerScreen] opens this — the full statement
/// (every sale/payment/adjustment, date-wise) plus the reminder and
/// "ادائیگی ریکارڈ کریں" actions, per the locked Phase 3 design.
class ContactStatementScreen extends StatefulWidget {
  final Customer contact;
  const ContactStatementScreen({super.key, required this.contact});

  @override
  State<ContactStatementScreen> createState() => _ContactStatementScreenState();
}

class _ContactStatementScreenState extends State<ContactStatementScreen> {
  Customer? _contact;
  List<LedgerEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final refreshed = await CustomerService.instance.getByUuid(widget.contact.uuid);
    final entries = await CustomerService.instance.getStatement(widget.contact.uuid);
    if (!mounted) return;
    setState(() {
      _contact = refreshed ?? _contact;
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _sendReminder() async {
    final contact = _contact!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          if (contact.phone != null)
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('WhatsApp پر بھیجیں'),
              onTap: () => Navigator.of(context).pop('whatsapp'),
            ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('شیئر شیٹ سے بھیجیں (SMS/دیگر)'),
            onTap: () => Navigator.of(context).pop('share'),
          ),
        ]),
      ),
    );
    if (choice == 'whatsapp') {
      final opened = await ReminderHelper.openWhatsApp(contact);
      if (!opened) await ReminderHelper.shareReminder(contact);
    } else if (choice == 'share') {
      await ReminderHelper.shareReminder(contact);
    }
  }

  Future<void> _recordPayment() async {
    final contact = _contact!;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final label = contact.isSupplier ? 'ادائیگی (ہم سے سپلائر کو)' : 'ادائیگی وصول کریں (گاہک سے)';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'رقم'),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'نوٹ (اختیاری)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('منسوخ کریں')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('محفوظ کریں')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;
    await CustomerService.instance.addPayment(
      contact: contact,
      amount: amount,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact!;
    final balanceColor = contact.currentBalance > 0
        ? AppColors.success
        : contact.currentBalance < 0
            ? AppColors.danger
            : AppColors.inkSoft;
    final balanceLabel = contact.currentBalance == 0
        ? 'برابر'
        : (contact.currentBalance > 0 ? 'آپ کو ملنا ہے' : 'آپ نے دینا ہے');

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(onPressed: _sendReminder, icon: const Icon(Icons.notifications_active_outlined), tooltip: 'یاد دہانی'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (contact.phone != null)
                                Text(contact.phone!, style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
                              Text(balanceLabel, style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Text(
                          AppFormat.currency(contact.currentBalance.abs()),
                          style: TextStyle(color: balanceColor, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _recordPayment,
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(contact.isSupplier ? 'ادائیگی ریکارڈ کریں' : 'ادائیگی وصول کریں'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('کھاتہ / سٹیٹمنٹ', style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text('ابھی تک کوئی انٹری نہیں', style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
                      ),
                    )
                  else
                    for (final entry in _entries.reversed) _entryTile(entry),
                ],
              ),
            ),
    );
  }

  Widget _entryTile(LedgerEntry entry) {
    final color = entry.amount > 0 ? AppColors.success : (entry.amount < 0 ? AppColors.danger : AppColors.inkSoft);
    final date = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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
                Text(_entryTypeLabel(entry.type), style: AppFonts.body(fontSize: 13, weight: FontWeight.w600)),
                Text(dateStr, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
                if (entry.note != null) Text(entry.note!, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Text(
            '${entry.amount >= 0 ? '+' : '-'}${AppFormat.currency(entry.amount.abs())}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _entryTypeLabel(String type) {
    switch (type) {
      case LedgerEntry.typeSale:
        return 'بل (ادھار)';
      case LedgerEntry.typePaymentReceived:
        return 'ادائیگی وصول ہوئی';
      case LedgerEntry.typePaymentMade:
        return 'ادائیگی کی گئی';
      case LedgerEntry.typeAdjustment:
        return 'ایڈجسٹمنٹ';
      case LedgerEntry.typeOpeningBalance:
        return 'ابتدائی بقایا';
      default:
        return type;
    }
  }
}
