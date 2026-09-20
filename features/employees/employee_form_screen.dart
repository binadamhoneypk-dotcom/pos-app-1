import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/employee_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// "نیا ملازم شامل کریں". The "اس ملازم کا لاگ اِن اکاؤنٹ بھی بنائیں"
/// switch hooks straight into [AuthService.addStaffToBusiness] (built in
/// Phase 1, unused until now) so ticking it creates both the payroll
/// record AND a working manager/staff login in one step, per the Phase 3
/// continuation prompt's explicit instruction.
class EmployeeFormScreen extends StatefulWidget {
  final String businessUuid;
  const EmployeeFormScreen({super.key, required this.businessUuid});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleTitleCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _createLogin = false;
  String _loginRole = AppConstants.roleStaff;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roleTitleCtrl.dispose();
    _salaryCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.nameRequiredMessage);
      return;
    }
    if (_createLogin && (_phoneCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().length < 4)) {
      setState(() => _error = t.loginRequiresPhonePasswordMessage);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      String? userUuid;
      if (_createLogin) {
        final (user, _) = await AuthService.instance.addStaffToBusiness(
          businessUuid: widget.businessUuid,
          staffName: name,
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          role: _loginRole,
        );
        userUuid = user.uuid;
      }

      await EmployeeService.instance.add(
        businessUuid: widget.businessUuid,
        userUuid: userUuid,
        name: name,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        roleTitle: _roleTitleCtrl.text.trim().isEmpty ? null : _roleTitleCtrl.text.trim(),
        monthlySalary: double.tryParse(_salaryCtrl.text.trim()) ?? 0,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = t.saveFailedMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.addNewEmployeeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: t.nameLabel)),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: _createLogin ? t.phoneRequiredForLoginLabel : t.phoneOptionalLabel),
          ),
          const SizedBox(height: 10),
          TextField(controller: _roleTitleCtrl, decoration: InputDecoration(labelText: t.roleTitleOptionalLabel)),
          const SizedBox(height: 10),
          TextField(
            controller: _salaryCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t.monthlySalaryFieldLabel),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.teal100, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _createLogin,
                  onChanged: (v) => setState(() => _createLogin = v),
                  title: Text(t.createLoginAccountLabel, style: AppFonts.body(fontSize: 13, weight: FontWeight.w600)),
                  subtitle: Text(t.createLoginAccountSubtitle,
                      style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
                ),
                if (_createLogin) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: t.passwordMinCharsLabel, filled: true, fillColor: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: AppConstants.roleManager,
                          groupValue: _loginRole,
                          onChanged: (v) => setState(() => _loginRole = v!),
                          title: Text(t.roleManager, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: AppConstants.roleStaff,
                          groupValue: _loginRole,
                          onChanged: (v) => setState(() => _loginRole = v!),
                          title: Text(t.roleStaff, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(t.save),
          ),
        ],
      ),
    );
  }
}
