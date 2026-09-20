import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/attendance_record.dart';
import '../../core/models/employee.dart';
import '../../core/models/employee_transaction.dart';
import '../../core/services/employee_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

/// Per-employee statement + payroll actions (تنخواہ ادا کریں / ایڈوانس /
/// بونس / کٹوتی) + basic attendance marking for the current month, per
/// the Phase 3 continuation prompt's "حاضری (بنیادی)" scope.
class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  Employee? _employee;
  List<EmployeeTransaction> _transactions = [];
  List<AttendanceRecord> _monthAttendance = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final refreshed = await EmployeeService.instance.getByUuid(widget.employee.uuid);
    final txns = await EmployeeService.instance.getStatement(widget.employee.uuid);
    final attendance = await EmployeeService.instance.getAttendanceForMonth(widget.employee.uuid, now.year, now.month);
    if (!mounted) return;
    setState(() {
      _employee = refreshed ?? _employee;
      _transactions = txns;
      _monthAttendance = attendance;
      _loading = false;
    });
  }

  Future<void> _addTransaction(String type, String title) async {
    final t = AppLocalizations.of(context)!;
    final employee = _employee!;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
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
    await EmployeeService.instance.addTransaction(
      employee: employee,
      type: type,
      amount: amount,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    await _load();
  }

  Future<void> _markAttendance(String status) async {
    final employee = _employee!;
    await EmployeeService.instance.markAttendance(
      businessUuid: employee.businessUuid,
      employeeUuid: employee.uuid,
      status: status,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final employee = _employee!;
    final color = employee.currentBalance > 0
        ? AppColors.danger
        : employee.currentBalance < 0
            ? AppColors.success
            : AppColors.inkSoft;
    final balanceLabel = employee.currentBalance == 0
        ? t.settled
        : (employee.currentBalance > 0 ? t.owedToEmployeeLabel : t.owedByEmployeeLabel);
    final todayKey = AttendanceRecord.keyFor(DateTime.now());
    AttendanceRecord? markedToday;
    for (final a in _monthAttendance) {
      if (a.dateKey == todayKey) {
        markedToday = a;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(employee.name)),
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
                              if (employee.roleTitle != null)
                                Text(employee.roleTitle!, style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
                              Text(t.monthlySalaryLabel(AppFormat.currency(employee.monthlySalary)),
                                  style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
                              Text(balanceLabel, style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Text(
                          AppFormat.currency(employee.currentBalance.abs()),
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addTransaction(AppConstants.empTxnSalaryPayment, t.paySalaryButton),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(t.paySalaryButton),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addTransaction(AppConstants.empTxnAdvance, t.giveAdvanceButton),
                        icon: const Icon(Icons.request_quote_outlined, size: 18),
                        label: Text(t.giveAdvanceButton),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addTransaction(AppConstants.empTxnBonus, t.addBonusButton),
                        icon: const Icon(Icons.card_giftcard_outlined, size: 18),
                        label: Text(t.bonusWord),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addTransaction(AppConstants.empTxnDeduction, t.applyDeductionButton),
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: Text(t.deductionWord),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(t.todayAttendanceLabel, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _attendanceButton(t.attendancePresentLabel, AppConstants.attendancePresent, AppColors.success, markedToday)),
                      const SizedBox(width: 8),
                      Expanded(child: _attendanceButton(t.attendanceAbsentLabel, AppConstants.attendanceAbsent, AppColors.danger, markedToday)),
                      const SizedBox(width: 8),
                      Expanded(child: _attendanceButton(t.attendanceLeaveLabel, AppConstants.attendanceLeave, AppColors.gold500, markedToday)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in _monthAttendance.reversed.take(14))
                        Chip(
                          label: Text('${a.dateKey.substring(8)}: ${a.label(t)}', style: const TextStyle(fontSize: 11)),
                          backgroundColor: a.status == AppConstants.attendancePresent
                              ? AppColors.teal100
                              : a.status == AppConstants.attendanceAbsent
                                  ? const Color(0xFFF8DCD9)
                                  : AppColors.gold100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(t.ledgerStatementLabel, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(t.noEntriesYetMessage, style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
                      ),
                    )
                  else
                    for (final txn in _transactions.reversed) _txnTile(txn),
                ],
              ),
            ),
    );
  }

  Widget _attendanceButton(String label, String status, Color color, AttendanceRecord? markedToday) {
    final isSelected = markedToday?.status == status;
    return OutlinedButton(
      onPressed: () => _markAttendance(status),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.12) : null,
        side: BorderSide(color: isSelected ? color : AppColors.line),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? color : AppColors.ink, fontSize: 12.5)),
    );
  }

  Widget _txnTile(EmployeeTransaction txn) {
    final t = AppLocalizations.of(context)!;
    final color = txn.amount > 0 ? AppColors.danger : AppColors.success;
    final date = DateTime.fromMillisecondsSinceEpoch(txn.createdAt);
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
                Text(txn.label(t), style: AppFonts.body(fontSize: 13, weight: FontWeight.w600)),
                Text(dateStr, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
                if (txn.note != null) Text(txn.note!, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Text(
            '${txn.amount >= 0 ? '+' : '-'}${AppFormat.currency(txn.amount.abs())}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
