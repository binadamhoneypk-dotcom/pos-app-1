import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/item.dart';
import '../../core/services/app_state.dart';
import '../../core/services/item_service.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/barcode_scanner_screen.dart';
import '../../core/widgets/calculator_fab.dart';
import '../../core/widgets/premium_gate.dart';
import '../../core/utils/app_format.dart';
import '../../core/l10n/category_labels.dart';
import '../../l10n/app_localizations.dart';

/// "Inventory Form: نام، کیٹیگری (dropdown)، بار کوڈ (فیلڈ + سکین بٹن)،
/// خریداری قیمت، فروخت قیمت، مقدار۔" — one screen for both add and
/// edit; pass [existing] to edit, omit it to create a new item.
class ItemFormScreen extends StatefulWidget {
  final Item? existing;
  const ItemFormScreen({super.key, this.existing});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _customCategoryCtrl;
  late final TextEditingController _customUnitCtrl;

  String? _selectedCategory;
  late String? _selectedUnit;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _barcodeCtrl = TextEditingController(text: item?.barcode ?? '');
    _purchasePriceCtrl = TextEditingController(text: item != null ? item.purchasePrice.toStringAsFixed(0) : '');
    _salePriceCtrl = TextEditingController(text: item != null ? item.salePrice.toStringAsFixed(0) : '');
    _quantityCtrl = TextEditingController(text: item != null ? item.quantity.toStringAsFixed(0) : '');
    _customCategoryCtrl = TextEditingController();
    _customUnitCtrl = TextEditingController();

    if (item?.category != null && AppConstants.defaultItemCategories.contains(item!.category)) {
      _selectedCategory = item.category;
    } else if (item?.category != null) {
      _selectedCategory = 'دیگر';
      _customCategoryCtrl.text = item!.category!;
    }

    final unit = item?.unit ?? AppConstants.defaultUnit;
    if (AppConstants.unitOptions.contains(unit)) {
      _selectedUnit = unit;
    } else {
      _selectedUnit = 'دیگر';
      _customUnitCtrl.text = unit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _quantityCtrl.dispose();
    _customCategoryCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final t = AppLocalizations.of(context)!;
    final ok = await PremiumGate.ensure(context, PremiumFeature.barcodeAutoScan,
        featureLabel: t.autoBarcodeScanFeature);
    if (!ok || !mounted) return;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null) setState(() => _barcodeCtrl.text = code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;

    if (!_isEditing) {
      final t = AppLocalizations.of(context)!;
      final currentCount = (await ItemService.instance.getAll(business.uuid)).length;
      if (currentCount >= AppConstants.freeMaxItems &&
          !PremiumService.instance.isUnlocked(PremiumFeature.unlimitedItems)) {
        if (!mounted) return;
        final ok = await PremiumGate.ensure(context, PremiumFeature.unlimitedItems,
            featureLabel: t.unlimitedItemsFeatureLabel(AppConstants.freeMaxItems));
        if (!ok) return;
      }
    }

    setState(() => _saving = true);

    final category = _selectedCategory == 'دیگر' ? _customCategoryCtrl.text.trim() : _selectedCategory;
    final unit = _selectedUnit == 'دیگر'
        ? (_customUnitCtrl.text.trim().isEmpty ? AppConstants.defaultUnit : _customUnitCtrl.text.trim())
        : (_selectedUnit ?? AppConstants.defaultUnit);
    final purchasePrice = double.tryParse(_purchasePriceCtrl.text) ?? 0;
    final salePrice = double.tryParse(_salePriceCtrl.text) ?? 0;
    final quantity = double.tryParse(_quantityCtrl.text) ?? 0;

    if (_isEditing) {
      await ItemService.instance.updateItem(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        category: category,
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        quantity: quantity,
        unit: unit,
      ));
    } else {
      await ItemService.instance.createItem(
        businessUuid: business.uuid,
        name: _nameCtrl.text.trim(),
        category: category,
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        quantity: quantity,
        unit: unit,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteItemQuestionTitle),
        content: Text(t.deleteItemConfirmMessage(widget.existing!.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.delete, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ItemService.instance.deleteItem(widget.existing!.uuid);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? t.editItemTitle : t.addNewItemTitle),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                _label(t.itemNameLabel),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(hintText: t.itemNameHintExample),
                  validator: (v) => (v == null || v.trim().isEmpty) ? t.enterNameMessage : null,
                ),
                const SizedBox(height: 16),

                _label(t.categoryLabel),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(hintText: t.selectCategoryHint),
                  isExpanded: true,
                  menuMaxHeight: 320,
                  dropdownColor: AppColors.card,
                  items: AppConstants.defaultItemCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(categoryLabel(t, c))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                if (_selectedCategory == 'دیگر') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customCategoryCtrl,
                    decoration: InputDecoration(hintText: t.enterCategoryNameHint),
                  ),
                ],
                const SizedBox(height: 16),

                _label(t.barcodeLabel),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeCtrl,
                        decoration: InputDecoration(hintText: t.barcodeOptionalHint),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.teal100,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _scanBarcode,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.qr_code_scanner, color: AppColors.teal800),
                              if (!context.watch<PremiumService>().isUnlocked(PremiumFeature.barcodeAutoScan))
                                const Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Icon(Icons.lock, size: 12, color: AppColors.gold500),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _label(t.purchasePricePerUnitLabel),
                TextFormField(
                  controller: _purchasePriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(prefixText: AppFormat.pricePrefix),
                  validator: (v) => double.tryParse(v ?? '') == null ? t.enterValidPriceMessage : null,
                ),
                const SizedBox(height: 16),

                _label(t.salePricePerUnitLabel),
                TextFormField(
                  controller: _salePriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(prefixText: AppFormat.pricePrefix),
                  validator: (v) => double.tryParse(v ?? '') == null ? t.enterValidPriceMessage : null,
                ),
                const SizedBox(height: 16),

                _label(t.quantityFieldLabel),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => double.tryParse(v ?? '') == null ? t.enterValidQuantityMessage : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(hintText: t.unitLabelShort),
                        isExpanded: true,
                        // Bug fix #6: an unbounded dropdown menu tries to
                        // vertically center the selected item against the
                        // field, which can grow it downward past the field
                        // and over whatever comes next in the form (here,
                        // the Save button). Capping the height and forcing
                        // an opaque background stops it from ever reading
                        // as an overlap glitch.
                        menuMaxHeight: 260,
                        dropdownColor: AppColors.card,
                        items: AppConstants.unitOptions.map((u) => DropdownMenuItem(value: u, child: Text(unitLabel(t, u)))).toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v),
                      ),
                    ),
                  ],
                ),
                if (_selectedUnit == 'دیگر') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customUnitCtrl,
                    decoration: InputDecoration(hintText: t.enterUnitNameHint),
                  ),
                ],
                // Bug fix #6: extra clearance between the last field and
                // Save so an opened dropdown's menu has room to lay out
                // above the button instead of extending onto it.
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t.save),
                ),
              ],
            ),
          ),
          CalculatorFab(
            onInsertResult: (v) {
              // Drops the calculator's result into whichever price field
              // was last focused; sale price is the most common case.
              _salePriceCtrl.text = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
            },
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
      );
}
