import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_state.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_gate.dart';
import '../../l10n/app_localizations.dart';
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
  // Canonical stored values stay in Urdu (unchanged data format); only the
  // displayed label is picked by locale via AppLocalizations.
  static const _businessTypeValues = ['جنرل سٹور', 'ریسٹورنٹ', 'میڈیکل سٹور', 'ورکشاپ', 'دیگر'];

  String _roleLabel(AppLocalizations t, String role) {
    switch (role) {
      case 'owner':
        return t.roleOwner;
      case 'manager':
        return t.roleManager;
      case 'staff':
        return t.roleStaff;
      default:
        return role;
    }
  }

  String _businessTypeLabel(AppLocalizations t, String value) {
    switch (value) {
      case 'جنرل سٹور':
        return t.businessTypeGeneralStore;
      case 'ریسٹورنٹ':
        return t.businessTypeRestaurant;
      case 'میڈیکل سٹور':
        return t.businessTypePharmacy;
      case 'ورکشاپ':
        return t.businessTypeWorkshop;
      case 'دیگر':
        return t.businessTypeOther;
      default:
        return value;
    }
  }

  Future<void> _addBusiness(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final appState = context.read<AppState>();
    final alreadyHasOne = appState.availableBusinesses.length >= AppConstants.freeMaxBusinesses;
    if (alreadyHasOne) {
      final ok = await PremiumGate.ensure(context, PremiumFeature.multiBusiness,
          featureLabel: t.multiBusinessFeatureLabel);
      if (!ok || !context.mounted) return;
    }

    final nameCtrl = TextEditingController();
    String type = 'جنرل سٹور';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(t.addNewShopTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: t.shopNameLabel)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(labelText: t.shopTypeLabel),
                items: _businessTypeValues
                    .map((v) => DropdownMenuItem(value: v, child: Text(_businessTypeLabel(t, v))))
                    .toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(t.cancel)),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(t.add)),
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
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final businesses = appState.availableBusinesses;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.selectYourShopTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: t.addNewShopTitle,
            onPressed: () => _addBusiness(context),
          ),
        ],
      ),
      body: businesses.isEmpty
          ? Center(child: Text(t.noShopFoundMessage))
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
                        '${_roleLabel(t, role.role)} · ${business.type}'),
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
