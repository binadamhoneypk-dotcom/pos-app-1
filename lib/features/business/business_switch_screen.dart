import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_state.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_gate.dart';
import '../shell/main_shell.dart';

/// Shown right after login. Lets a user who manages several businesses
/// (e.g. a general store AND a restaurant) pick which one to work in.
/// If they only have one business, this could later auto-skip — kept
/// explicit for now so Phase 1 stays easy to test with multiple shops.
///
/// PHASE 2: adding a SECOND (or later) business is a Premium feature —
/// see [PremiumFeature.multiBusiness]. The first business (created at
/// signup) is always free.
class BusinessSwitchScreen extends StatefulWidget {
  const BusinessSwitchScreen({super.key});

  @override
  State<BusinessSwitchScreen> createState() => _BusinessSwitchScreenState();
}

class _BusinessSwitchScreenState extends State<BusinessSwitchScreen> {
  static const _roleLabels = {
    'owner': 'مالک',
    'manager': 'منیجر',
    'staff': 'عملہ',
  };

  Future<void> _addBusiness(BuildContext context) async {
    final appState = context.read<AppState>();
    final alreadyHasOne = appState.availableBusinesses.length >= AppConstants.freeMaxBusinesses;
    if (alreadyHasOne) {
      final ok = await PremiumGate.ensure(context, PremiumFeature.multiBusiness,
          featureLabel: 'متعدد دکانیں (ایک اکاؤنٹ سے ایک سے زیادہ دکانیں)');
      if (!ok || !context.mounted) return;
    }

    final nameCtrl = TextEditingController();
    String type = 'جنرل سٹور';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('نئی دکان شامل کریں'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'دکان کا نام')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'دکان کی قسم'),
                items: const [
                  DropdownMenuItem(value: 'جنرل سٹور', child: Text('جنرل سٹور')),
                  DropdownMenuItem(value: 'ریسٹورنٹ', child: Text('ریسٹورنٹ')),
                  DropdownMenuItem(value: 'میڈیکل سٹور', child: Text('میڈیکل سٹور')),
                  DropdownMenuItem(value: 'ورکشاپ', child: Text('ورکشاپ')),
                  DropdownMenuItem(value: 'دیگر', child: Text('دیگر')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('منسوخ کریں')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('شامل کریں')),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;
    final userUuid = appState.currentUser?.uuid;
    if (userUuid == null) return;

    await AuthService.instance.addBusinessForExistingOwner(
      ownerUuid: userUuid,
      businessName: nameCtrl.text.trim(),
      businessType: type,
    );
    if (!context.mounted) return;
    await appState.reloadAvailableBusinesses();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final businesses = appState.availableBusinesses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اپنی دکان منتخب کریں'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'نئی دکان شامل کریں',
            onPressed: () => _addBusiness(context),
          ),
        ],
      ),
      body: businesses.isEmpty
          ? const Center(child: Text('کوئی دکان نہیں ملی'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: businesses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final (business, role) = businesses[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront),
                    title: Text(business.name),
                    subtitle: Text(
                        '${_roleLabels[role.role] ?? role.role} · ${business.type}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await context
                          .read<AppState>()
                          .switchBusiness(business, role);
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainShell()),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
