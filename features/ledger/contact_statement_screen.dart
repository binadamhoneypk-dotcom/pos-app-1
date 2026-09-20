import 'package:flutter/material.dart';
import '../../core/models/customer.dart';
import '../../core/models/ledger_entry.dart';
import '../../core/services/customer_service.dart';
import '../../core/theme/app_theme.dart';
import 'reminder_helper.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

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
    final t = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          if (contact.phone != null)
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(t.sendViaWhatsappLabel),
              onTap: () => Navigator.of(context).pop('whatsapp'),
            ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(t.sendViaShareSheetLabel),
            onTap: () => Navigator.of(context).pop('share'),
          ),
        ]),
      ),
    );
    if (choice == 'whatsapp') {
      final opened = await ReminderHelper.openWhatsApp(t, contact);
      if (!opened) await ReminderHelper.shareReminder(t, contact);
    } else if (choice == 'share') {
      await ReminderHelper.shareReminder(t, contact);
    }
  }

  Future<void> _recordPayment() async {
    final contact = _contact!;
    final t = AppLocalizations.of(context)!;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final label = contact.isSupplier ? t.paymentToSupplierLabel : t.paymentFromCustomerLabel;
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
              decoration: InputDecoration(labelText: t.amountLabel),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(controller: noteCtrl, decoration: InputDecoration(labelText: t.noteOptionalLabel)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.save)),
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
    final t = AppLocalizations.of(context)!;
    final contact = _contact!;
    final balanceColor = contact.currentBalance > 0
        ? AppColors.success
        : contact.currentBalance < 0
            ? AppColors.danger
            : AppColors.inkSoft;
    final balanceLabel = contact.currentBalance == 0
        ? t.settled
        : (contact.currentBalance > 0 ? t.youWillGetLabel : t.youWillGiveLabel);

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(onPressed: _sendReminder, icon: const Icon(Icons.notifications_active_outlined), tooltip: t.reminderTooltip),
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
                      label: Text(contact.isSupplier ? t.recordPaymentButton : t.receivePaymentButton),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(t.ledgerStatementLabel, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(t.noEntriesYetMessage, style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
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
    final t = AppLocalizations.of(context)!;
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
                Text(_entryTypeLabel(t, entry.type), style: AppFonts.body(fontSize: 13, weight: FontWeight.w600)),
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

  String _entryTypeLabel(AppLocalizations t, String type) {
    switch (type) {
      case LedgerEntry.typeSale:
        return t.entryTypeSaleLabel;
      case LedgerEntry.typePaymentReceived:
        return t.entryTypePaymentReceivedLabel;
      case LedgerEntry.typePaymentMade:
        return t.entryTypePaymentMadeLabel;
      case LedgerEntry.typeAdjustment:
        return t.entryTypeAdjustmentLabel;
      case LedgerEntry.typeOpeningBalance:
        return t.entryTypeOpeningBalanceLabel;
      default:
        return type;
    }
  }
}
