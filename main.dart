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
import 'l10n/app_localizations.dart';

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
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        // Bug fix #2: this delegate (generated from lib/l10n/*.arb by
        // `flutter gen-l10n`, wired via l10n.yaml) is what actually makes
        // AppLocalizations.of(context).xyz strings switch when the user
        // picks a language in Settings. Before this, only the *locale
        // value* changed reactively — the screens had no localized
        // strings to switch to, so almost everything stayed in Urdu.
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // PHASE 2: teal + gold theme matching the approved HTML prototype.
      theme: AppTheme.light(),
      // FEATURE 2 (Google AI Studio prompt): a real dark theme, wired to
      // the Settings toggle via `appState.themeMode` — see
      // AppTheme.dark()'s doc comment for the honest scope note (stock
      // widgets go dark correctly; custom-painted screens keep their
      // fixed AppColors until Phase 5's per-screen pass).
      darkTheme: AppTheme.dark(),
      themeMode: appState.themeMode,
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
