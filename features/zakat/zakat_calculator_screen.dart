import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_state.dart';
import '../../core/services/business_service.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/item_service.dart';
import '../../core/services/metal_rate_service.dart';
import '../../core/services/zakat_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

/// "نصاب تھریشولڈ، شروع کی تاریخ، قمری سال حساب، سونا/چاندی ریٹ آٹو
/// فیچ + دستی انٹری کا آپشن" — exactly what's built here. Reads the
/// active business from [AppState] rather than a constructor parameter
/// so it can be opened from anywhere (Dashboard's Zakat sheet, or later
/// a direct "مزید" menu entry) with one line.
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _cashCtrl = TextEditingController(text: '0');
  final _tradeGoodsCtrl = TextEditingController(text: '0');
  final _receivablesCtrl = TextEditingController(text: '0');
  final _goldGramsCtrl = TextEditingController(text: '0');
  final _goldRateCtrl = TextEditingController(text: '0');
  final _silverGramsCtrl = TextEditingController(text: '0');
  final _silverRateCtrl = TextEditingController(text: '0');

  bool _useSilverStandard = true; // more cautious/common default for traders
  bool _loading = true;
  bool _fetchingRates = false;
  DateTime? _startDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    for (final c in [
      _cashCtrl,
      _tradeGoodsCtrl,
      _receivablesCtrl,
      _goldGramsCtrl,
      _goldRateCtrl,
      _silverGramsCtrl,
      _silverRateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) {
      setState(() => _loading = false);
      return;
    }

    final tradeGoods = await ItemService.instance.totalStockSaleValue(business.uuid);
    final receivables = await CustomerService.instance.totalReceivable(business.uuid);
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _tradeGoodsCtrl.text = tradeGoods.toStringAsFixed(0);
      _receivablesCtrl.text = receivables.toStringAsFixed(0);
      _useSilverStandard = prefs.getBool(AppConstants.prefZakatUseSilverStandardKey) ?? true;
      _goldRateCtrl.text = (prefs.getDouble(AppConstants.prefManualGoldRateKey) ?? 0).toStringAsFixed(0);
      _silverRateCtrl.text =
          (prefs.getDouble(AppConstants.prefManualSilverRateKey) ?? 0).toStringAsFixed(0);
      _startDate = business.zakatStartDate != null
          ? DateTime.fromMillisecondsSinceEpoch(business.zakatStartDate!)
          : null;
      _loading = false;
    });
  }

  double get _totalWealth =>
      (double.tryParse(_cashCtrl.text) ?? 0) +
      (double.tryParse(_tradeGoodsCtrl.text) ?? 0) +
      (double.tryParse(_receivablesCtrl.text) ?? 0) +
      (double.tryParse(_goldGramsCtrl.text) ?? 0) * (double.tryParse(_goldRateCtrl.text) ?? 0) +
      (double.tryParse(_silverGramsCtrl.text) ?? 0) * (double.tryParse(_silverRateCtrl.text) ?? 0);

  double get _nisabThreshold => ZakatService.nisabThreshold(
        useSilverStandard: _useSilverStandard,
        goldRatePerGram: double.tryParse(_goldRateCtrl.text) ?? 0,
        silverRatePerGram: double.tryParse(_silverRateCtrl.text) ?? 0,
      );

  bool get _aboveNisab =>
      ZakatService.isAboveNisab(totalWealth: _totalWealth, nisabThreshold: _nisabThreshold);

  Future<void> _fetchRates() async {
    setState(() => _fetchingRates = true);
    final rates = await MetalRateService.instance.fetchRates();
    if (!mounted) return;
    setState(() {
      _fetchingRates = false;
      if (rates != null) {
        _goldRateCtrl.text = rates.goldPerGram.toStringAsFixed(0);
        _silverRateCtrl.text = rates.silverPerGram.toStringAsFixed(0);
      }
    });
    if (rates == null && mounted) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.rateFetchFailedMessage)),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    final business = context.read<AppState>().currentBusiness;
    final role = context.read<AppState>().currentBusinessRole;
    if (business == null) return;

    if (_aboveNisab && _startDate == null) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.selectAboveNisabDateMessage)),
      );
      return;
    }

    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefZakatUseSilverStandardKey, _useSilverStandard);
    await prefs.setDouble(AppConstants.prefManualGoldRateKey, double.tryParse(_goldRateCtrl.text) ?? 0);
    await prefs.setDouble(
        AppConstants.prefManualSilverRateKey, double.tryParse(_silverRateCtrl.text) ?? 0);

    final updated = await BusinessService.instance.updateZakatSettings(
      business,
      zakatNisabThreshold: _nisabThreshold,
      zakatStartDate: _aboveNisab ? _startDate!.millisecondsSinceEpoch : null,
    );

    if (!mounted) return;
    if (role != null) {
      await context.read<AppState>().switchBusiness(updated, role);
    }
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.zakatCalculatorTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _sectionLabel(t.cashAndDueAmountSectionLabel),
          _numberField(_cashCtrl, t.cashInHandBankLabel),
          _numberField(_receivablesCtrl, t.receivableFromCustomersLabel),
          _numberField(_tradeGoodsCtrl, t.tradeGoodsValueLabel),
          const SizedBox(height: 8),
          _sectionLabel(t.goldSilverSectionLabel),
          Row(children: [
            Expanded(child: _numberField(_goldGramsCtrl, t.goldGramsLabel)),
            const SizedBox(width: 10),
            Expanded(child: _numberField(_goldRateCtrl, t.goldRatePerGramLabel)),
          ]),
          Row(children: [
            Expanded(child: _numberField(_silverGramsCtrl, t.silverGramsLabel)),
            const SizedBox(width: 10),
            Expanded(child: _numberField(_silverRateCtrl, t.silverRatePerGramLabel)),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: MetalRateService.instance.isConfigured && !_fetchingRates ? _fetchRates : null,
              icon: _fetchingRates
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                MetalRateService.instance.isConfigured
                    ? t.fetchOnlineRateNowLabel
                    : t.onlineRateProviderNotSetMessage,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _sectionLabel(t.nisabStandardSectionLabel),
          RadioListTile<bool>(
            value: true,
            groupValue: _useSilverStandard,
            onChanged: (v) => setState(() => _useSilverStandard = v!),
            title: Text(t.bySilverStandardLabel, style: const TextStyle(fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: _useSilverStandard,
            onChanged: (v) => setState(() => _useSilverStandard = v!),
            title: Text(t.byGoldStandardLabel, style: const TextStyle(fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          _resultCard(t),
          const SizedBox(height: 16),
          if (_aboveNisab) ...[
            _sectionLabel(t.aboveNisabDateLabel),
            InkWell(
              onTap: _pickStartDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.inkSoft),
                    const SizedBox(width: 10),
                    Text(
                      _startDate != null
                          ? DateFormat('d MMMM yyyy', 'ur').format(_startDate!)
                          : t.selectDateFirstTimeTodayLabel,
                      style: AppFonts.body(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
            child: Text(
              t.zakatShortDisclaimerMessage,
              style: AppFonts.body(fontSize: 11.5, color: AppColors.zakatTextSoft),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(t.save),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.gold100, Colors.white]),
        border: Border.all(color: const Color(0xFFEAD9A0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(t.totalWealthLabel, AppFormat.currency(_totalWealth)),
          const SizedBox(height: 6),
          _row(t.nisabThresholdLabel, AppFormat.currency(_nisabThreshold)),
          const Divider(height: 20),
          _row(
            _aboveNisab ? t.aboveNisabMessage : t.notAboveNisabMessage,
            _aboveNisab ? t.zakatDueApproxMessage(AppFormat.currency(ZakatService.zakatDue(_totalWealth))) : '',
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppFonts.body(fontSize: 13, color: AppColors.zakatText, weight: FontWeight.w700))),
        Text(value, style: AppFonts.body(fontSize: 13, color: AppColors.zakatText, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Text(text, style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
      );

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
