import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_state.dart';
import '../../core/services/auth_service.dart';
import '../business/business_switch_screen.dart';

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

  static const _businessTypes = {
    'general_store': 'جنرل سٹور',
    'restaurant': 'ریسٹورنٹ',
    'pharmacy': 'میڈیکل سٹور',
    'workshop': 'ورکشاپ',
    'custom': 'دیگر',
  };

  Future<void> _submit() async {
    if (_ownerNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _businessNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'براہ کرم تمام خانے پُر کریں');
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
      setState(() => _error = 'اکاؤنٹ بنانے میں مسئلہ پیش آیا: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نیا اکاؤنٹ اور دکان')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text('مالک کی معلومات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _ownerNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'آپ کا نام', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'فون نمبر', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'پاس ورڈ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Text('دکان کی معلومات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _businessNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'دکان کا نام', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                decoration: const InputDecoration(
                    labelText: 'دکان کی قسم', border: OutlineInputBorder()),
                items: _businessTypes.entries
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
                    : const Text('اکاؤنٹ اور دکان بنائیں'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
