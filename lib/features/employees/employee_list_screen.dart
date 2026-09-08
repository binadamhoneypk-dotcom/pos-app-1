import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/employee.dart';
import '../../core/services/app_state.dart';
import '../../core/services/employee_service.dart';
import '../../core/theme/app_theme.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';
import '../../core/utils/app_format.dart';

/// "ملازمین کا کھاتہ" — reached from the More screen (gated behind
/// [PremiumFeature.staffAccounts] at the call site), not a bottom-nav
/// tab, per the Phase 3 design note that this is a separate screen, not
/// a third Ledger tab.
class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Employee> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    setState(() => _loading = true);
    final list = await EmployeeService.instance.getAll(business.uuid);
    if (!mounted) return;
    setState(() {
      _employees = list;
      _loading = false;
    });
  }

  Future<void> _addEmployee() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(businessUuid: business.uuid)),
    );
    if (added == true) await _load();
  }

  Future<void> _openDetail(Employee employee) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employee: employee)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final owed = _employees.where((e) => e.currentBalance > 0).fold<double>(0, (s, e) => s + e.currentBalance);
    final advances = _employees.where((e) => e.currentBalance < 0).fold<double>(0, (s, e) => s + e.currentBalance.abs());

    return Scaffold(
      appBar: AppBar(title: const Text('ملازمین کا کھاتہ')),
      floatingActionButton: FloatingActionButton(onPressed: _addEmployee, child: const Icon(Icons.person_add_alt_1)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: _summaryTile('ملازمین کو دینا ہے (تنخواہ)', owed, AppColors.danger)),
                      const SizedBox(width: 12),
                      Expanded(child: _summaryTile('ملازمین سے لینا ہے (ایڈوانس)', advances, AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_employees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text('ابھی تک کوئی ملازم شامل نہیں — نیچے دیے بٹن سے شامل کریں',
                            style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft), textAlign: TextAlign.center),
                      ),
                    )
                  else
                    for (final e in _employees) _employeeTile(e),
                ],
              ),
            ),
    );
  }

  Widget _summaryTile(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text(AppFormat.currency(value), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _employeeTile(Employee e) {
    final color = e.currentBalance > 0
        ? AppColors.danger // shop owes them
        : e.currentBalance < 0
            ? AppColors.success // they owe shop (advance)
            : AppColors.inkSoft;
    return InkWell(
      onTap: () => _openDetail(e),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.teal100,
              child: Icon(e.hasLoginAccount ? Icons.badge_outlined : Icons.person_outline, color: AppColors.teal800),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w600)),
                  Text(
                    [if (e.roleTitle != null) e.roleTitle!, 'تنخواہ ${AppFormat.currency(e.monthlySalary)}'].join(' • '),
                    style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Text(
              e.currentBalance == 0 ? 'برابر' : AppFormat.currency(e.currentBalance.abs()),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
