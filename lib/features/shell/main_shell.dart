import 'package:flutter/material.dart';
import '../billing/billing_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_list_screen.dart';
import '../ledger/ledger_screen.dart';
import '../more/more_screen.dart';

/// The persistent bottom navigation shown on every screen after login,
/// per the locked design: "ڈیش بورڈ | بلنگ | انوینٹری | کھاتہ | مزید".
/// Login/signup/business-select screens do NOT show this bar — they
/// never route through here.
///
/// Uses IndexedStack (not Navigator per tab) so switching tabs is
/// instant and each tab keeps its scroll position/state.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    BillingListScreen(),
    InventoryListScreen(),
    LedgerScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'ڈیش بورڈ'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'بلنگ'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'انوینٹری'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'کھاتہ'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'مزید'),
        ],
      ),
    );
  }
}
