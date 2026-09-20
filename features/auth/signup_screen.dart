import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/auth_service.dart';
import '../business/business_switch_screen.dart';
import '../../l10n/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  String _businessType = 'general_store';
  bool _loading = false;
  String? _error;

  // Stored key stays in English (matches AuthService/DB expectations);
  // only the displayed label is picked by locale.
  Map<String, String> _businessTypeLabels(AppLocalizations t) => {
        'general_store': t.businessTypeGeneralStore,
        'restaurant': t.businessTypeRestaurant,
        'pharmacy': t.businessTypePharmacy,
        'workshop': t.businessTypeWorkshop,
        'custom': t.businessTypeOther,
      };

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (_ownerNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _businessNameCtrl.text.trim().isEmpty) {
      setState(() => _error = t.fillAllFieldsMessage);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final (user, business, _) =
          await AuthService.instance.signUpOwnerWithBusiness(
        ownerName: _ownerNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        businessName: _businessNameCtrl.text.trim(),
        businessType: _businessType,
      );

      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.currentUser = user;
      appState.currentBusiness = business;
      await appState.loadSession();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BusinessSwitchScreen()),
      );
    } catch (e) {
      setState(() => _error = t.accountCreationFailedMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final businessTypeLabels = _businessTypeLabels(t);
    return Scaffold(
      appBar: AppBar(title: Text(t.newAccountAndShopTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Text(t.ownerInfoSectionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _ownerNameCtrl,
                decoration: InputDecoration(
                    labelText: t.yourNameLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: t.phoneNumberLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: t.passwordLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Text(t.shopInfoSectionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _businessNameCtrl,
                decoration: InputDecoration(
                    labelText: t.shopNameLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                decoration: InputDecoration(
                    labelText: t.shopTypeLabel, border: const OutlineInputBorder()),
                items: businessTypeLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _businessType = v!),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.createAccountAndShopButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
