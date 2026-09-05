import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/services/app_state.dart';
import 'core/services/premium_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/business/business_switch_screen.dart';
import 'features/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // PHASE 2: lets DateFormat use Urdu month/day names (e.g. Zakat dates)
  // instead of throwing a LocaleDataException the first time it's used.
  await initializeDateFormatting('ur');
  await initializeDateFormatting('en');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider.value(value: PremiumService.instance..load()),
      ],
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatefulWidget {
  const PosApp({super.key});

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  late Future<bool> _sessionCheck;

  @override
  void initState() {
    super.initState();
    _sessionCheck = _restoreSession();
  }

  Future<bool> _restoreSession() async {
    final appState = context.read<AppState>();
    await appState.loadSession();
    return appState.currentBusiness != null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'دکان مینجمنٹ ایپ',
      debugShowCheckedModeBanner: false,
      locale: appState.locale,
      // Full Urdu/English toggle + correct RTL/LTR rendering.
      // Directionality follows `locale` automatically via Flutter's
      // built-in Localizations widget below — Urdu renders RTL, English LTR.
      supportedLocales: const [Locale('ur'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // PHASE 2: teal + gold theme matching the approved HTML prototype.
      theme: AppTheme.light(),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      // PHASE 2 screens use fixed AppColors (matching the approved HTML
      // prototype) rather than reading brightness, so force light mode
      // until Phase 5 does proper dark-mode polish across every screen.
      themeMode: ThemeMode.light,
      // PHASE 2: named routes so deep screens (Dashboard, More) can
      // navigate to Login/BusinessSwitch/MainShell without importing
      // each other directly and creating circular imports.
      routes: {
        '/login': (_) => const LoginScreen(),
        '/business-switch': (_) => const BusinessSwitchScreen(),
        '/main': (_) => const MainShell(),
      },
      home: FutureBuilder<bool>(
        future: _sessionCheck,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final hasSession = snapshot.data ?? false;
          if (!hasSession) return const LoginScreen();
          // A restored session with only one business skips straight to
          // the bottom-nav shell; multiple businesses still show the
          // switcher first (unchanged from Phase 1).
          return appState.availableBusinesses.length == 1
              ? const MainShell()
              : const BusinessSwitchScreen();
        },
      ),
    );
  }
}
