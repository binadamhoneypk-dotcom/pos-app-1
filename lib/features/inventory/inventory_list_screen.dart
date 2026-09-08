import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/item.dart';
import '../../core/services/app_state.dart';
import '../../core/services/item_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calculator_fab.dart';
import 'item_form_screen.dart';
import '../../core/utils/app_format.dart';

/// Tab 3 of [MainShell]. Lists every item in stock for the active
/// business with a search bar and a "+" FAB → [ItemFormScreen], per the
/// locked design's Inventory Form spec.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  List<Item> _items = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final business = context.read<AppState>().currentBusiness;
    if (business == null) return;
    setState(() => _loading = true);
    final items = await ItemService.instance.search(business.uuid, _query);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مال کی فہرست')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'چیز کا نام یا بار کوڈ تلاش کریں',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    _query = v;
                    _load();
                  },
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(
                            child: Text('کوئی چیز نہیں ملی — نیچے "+" سے نئی چیز شامل کریں',
                                style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) => _itemTile(_items[i]),
                            ),
                          ),
              ),
            ],
          ),
          const CalculatorFab(),
          Positioned(
            bottom: 18,
            right: 18,
            child: FloatingActionButton(
              heroTag: 'inventory_add_fab',
              backgroundColor: AppColors.teal700,
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ItemFormScreen()))
                  .then((_) => _load()),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(Item item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ItemFormScreen(existing: item)))
          .then((_) => _load()),
      child: Container(
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
                  Text(item.name, style: AppFonts.body(fontSize: 13.5, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.category != null && item.category!.isNotEmpty) item.category!,
                      'مقدار: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)} ${item.unit}',
                    ].join(' · '),
                    style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            if (item.isLowStock)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('کم اسٹاک', style: AppFonts.body(fontSize: 10, color: AppColors.danger, weight: FontWeight.w700)),
              ),
            Text(AppFormat.currency(item.salePrice),
                style: AppFonts.body(fontSize: 13.5, color: AppColors.teal800, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
