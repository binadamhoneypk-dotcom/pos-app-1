import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Exact colour tokens copied from the approved HTML prototype's
/// `:root` CSS variables. Phase 2+ screens must use these constants
/// instead of ad-hoc `Colors.xxx` values so the app always matches the
/// approved design, and so a future desktop build can reuse this file
/// unchanged.
class AppColors {
  AppColors._();

  static const teal900 = Color(0xFF0B4A44);
  static const teal800 = Color(0xFF0E5850);
  static const teal700 = Color(0xFF0F6158);
  static const teal600 = Color(0xFF12776C);
  static const teal100 = Color(0xFFE3F1EE);

  static const gold500 = Color(0xFFC79A2B);
  static const gold100 = Color(0xFFFBF1D9);

  static const ink = Color(0xFF1B2321);
  static const inkSoft = Color(0xFF5B6663);
  static const paper = Color(0xFFF3F6F5);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFDDE6E3);
  static const danger = Color(0xFFC0453A);
  static const success = Color(0xFF1E7A4C);

  // Zakat card text colour used on the gold gradient background.
  static const zakatText = Color(0xFF7A5B0F);
  static const zakatTextSoft = Color(0xFF8A7440);
}

/// 8px baseline spacing scale (bug fix #4 — "consistent spacing, use an
/// 8px grid"). Screens that still hard-code `SizedBox`/`EdgeInsets`
/// numbers can migrate to these over time; new code should prefer them.
class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

/// Font helpers. The bill/letterhead "kashida/nastaliq" font choice from
/// the locked design lives here too, so Phase 4's PDF invoice code and
/// this screen's live preview both read from one place.
class AppFonts {
  AppFonts._();

  /// Page titles / brand headings — matches `.page-title` /
  /// `.brand-title` in the HTML prototype (Noto Nastaliq Urdu).
  ///
  /// Bug fix #3 (follow-up): uses the font bundled in assets/fonts/ via
  /// pubspec.yaml instead of google_fonts' runtime download, so it
  /// renders correctly even on a first launch with no internet — the
  /// app is meant to be offline-first.
  static TextStyle nastaliq({double fontSize = 22, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'NotoNastaliqUrdu',
        fontSize: fontSize,
        color: color ?? AppColors.teal900,
        fontWeight: weight ?? FontWeight.w700,
      );

  /// Body Urdu text — matches the prototype's default body font
  /// (Noto Sans Arabic), bundled locally for the same offline reason.
  static TextStyle body({double fontSize = 14, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'NotoSansArabic',
        fontSize: fontSize,
        color: color ?? AppColors.ink,
        fontWeight: weight ?? FontWeight.w400,
      );

  /// Three bill letterhead name-font choices, per the locked "بل کی
  /// سیٹنگز" design (نستعلیق / کشیدہ‌طرز / نسخ). All three currently
  /// resolve to Google Fonts families that render Urdu well; swap the
  /// "kashida" entry for a true kashida-style font file later if you
  /// license one — this list is intentionally the single place that
  /// changes.
  static const Map<String, String> letterheadFontLabels = {
    'nastaliq': 'نستعلیق',
    'kashida': 'کشیدہ طرز',
    'naskh': 'نسخ',
  };

  static TextStyle letterheadFont(String key, {double fontSize = 20, Color? color}) {
    switch (key) {
      case 'naskh':
        return GoogleFonts.notoNaskhArabic(fontSize: fontSize, color: color, fontWeight: FontWeight.w700);
      case 'kashida':
        // Decorative/kashida-flavoured option distinct from both Nastaliq
        // and Naskh, so the three letterhead choices look visually
        // different in the live preview. Swap for a licensed true
        // kashida-Naskh font file later if you have one — this constant
        // is the only place that needs to change.
        return GoogleFonts.arefRuqaa(fontSize: fontSize, color: color, fontWeight: FontWeight.w700);
      case 'nastaliq':
      default:
        return TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: fontSize, color: color, fontWeight: FontWeight.w700);
    }
  }
}

class AppTheme {
  AppTheme._();

  /// Bug fix #3: makes Noto Nastaliq Urdu the *default* font for
  /// headings/titles app-wide (page titles, dialog titles, large AppBar
  /// titles) without forcing every small label/body string into
  /// Nastaliq — Nastaliq's calligraphic strokes become hard to read
  /// below ~16px, which is why the approved HTML prototype always paired
  /// it with a plain sans body font. Any screen still gets true Nastaliq
  /// automatically the moment it uses a heading-level TextTheme style
  /// (or `Theme.of(context).textTheme.headlineSmall`, etc.) instead of a
  /// one-off `TextStyle`.
  static TextTheme _withNastaliqHeadings(TextTheme base) {
    TextStyle? nastaliq(TextStyle? s) => s == null
        ? null
        : TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: s.fontSize, color: s.color, fontWeight: s.fontWeight ?? FontWeight.w700);
    return base.copyWith(
      displayLarge: nastaliq(base.displayLarge),
      displayMedium: nastaliq(base.displayMedium),
      displaySmall: nastaliq(base.displaySmall),
      headlineLarge: nastaliq(base.headlineLarge),
      headlineMedium: nastaliq(base.headlineMedium),
      headlineSmall: nastaliq(base.headlineSmall),
      titleLarge: nastaliq(base.titleLarge),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal700,
        brightness: Brightness.light,
        primary: AppColors.teal700,
        secondary: AppColors.gold500,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: _withNastaliqHeadings(ThemeData.light().textTheme.apply(fontFamily: 'NotoSansArabic')),
      // Bug fix #4: a touch more breathing room than Material's compact
      // default so tap targets read as a modern mobile app, not a dense
      // desktop port.
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.teal700,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: AppFonts.body(fontSize: 17, color: Colors.white, weight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return AppColors.line;
            if (states.contains(MaterialState.pressed)) return AppColors.teal800;
            return AppColors.teal700;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return AppColors.inkSoft;
            return Colors.white;
          }),
          elevation: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return 0;
            if (states.contains(MaterialState.pressed)) return 0;
            return 1;
          }),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: MaterialStatePropertyAll(AppFonts.body(fontSize: 15, color: Colors.white, weight: FontWeight.w600)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal700,
          side: const BorderSide(color: AppColors.teal700, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal900,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.teal700,
        unselectedItemColor: AppColors.inkSoft,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 24),
      dividerColor: AppColors.line,
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? AppColors.teal700 : AppColors.inkSoft),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? AppColors.teal700 : null),
        trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? AppColors.teal100 : null),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.teal100,
        labelStyle: AppFonts.body(fontSize: 12, color: AppColors.teal800, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppFonts.body(fontSize: 16, color: AppColors.ink, weight: FontWeight.w700),
        contentTextStyle: AppFonts.body(fontSize: 13.5, color: AppColors.inkSoft),
      ),
      // Bug fix #5 (calculator) relies on a rounded, elevated sheet —
      // this default matches it for every other bottom sheet in the app.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.teal900,
        contentTextStyle: AppFonts.body(fontSize: 13, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
        textStyle: AppFonts.body(fontSize: 11.5, color: Colors.white),
      ),
    );
  }

  /// GOOGLE AI STUDIO PROMPT — FEATURE 2: dark mode. Same font families as
  /// [light] (Noto Sans Arabic body / Noto Nastaliq Urdu headings), a dark
  /// `ColorScheme` seeded from the same teal, and dark surfaces for every
  /// stock Material widget (dialogs, `TextField`s not given an explicit
  /// `fillColor`, `SnackBar`s, switches, the default `AppBar`/bottom-nav
  /// backgrounds here, etc).
  ///
  /// HONEST LIMIT, so nobody is surprised testing this: most Phase 2/3
  /// screens paint their own `Container`s using the fixed [AppColors]
  /// constants (`AppColors.card`, `AppColors.paper`, `AppColors.ink`...)
  /// directly rather than `Theme.of(context)`, exactly like this file's
  /// own `main.dart` comment already flags ("PHASE 2 screens use fixed
  /// AppColors... force light mode until Phase 5 does proper dark-mode
  /// polish across every screen"). This theme makes the Settings toggle
  /// real and correctly darkens every default Flutter widget, but a
  /// custom-built screen's card backgrounds will keep looking light until
  /// that later per-screen pass converts them to theme-aware colours.
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal600,
        brightness: Brightness.dark,
        primary: AppColors.teal600,
        secondary: AppColors.gold500,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: const Color(0xFF14201E),
      textTheme: _withNastaliqHeadings(
          ThemeData(brightness: Brightness.dark).textTheme.apply(fontFamily: 'NotoSansArabic')),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0E1917),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: AppFonts.body(fontSize: 17, color: Colors.white, weight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      iconTheme: const IconThemeData(color: Colors.white70, size: 22),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B2926),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A3835)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B2926),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3835), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3835), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: AppFonts.body(fontSize: 12.5, color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return const Color(0xFF2A3835);
            if (states.contains(MaterialState.pressed)) return AppColors.teal700;
            return AppColors.teal600;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) return Colors.white38;
            return Colors.white;
          }),
          elevation: const MaterialStatePropertyAll(0),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: MaterialStatePropertyAll(AppFonts.body(fontSize: 15, color: Colors.white, weight: FontWeight.w600)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold500,
          side: const BorderSide(color: AppColors.gold500, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold500,
        foregroundColor: AppColors.ink,
        elevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0E1917),
        selectedItemColor: AppColors.gold500,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A3835), thickness: 1, space: 24),
      dividerColor: const Color(0xFF2A3835),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? AppColors.gold500 : Colors.white54),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? AppColors.gold500 : null),
        trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? AppColors.teal800 : null),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1B2926),
        labelStyle: AppFonts.body(fontSize: 12, color: AppColors.gold100, weight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1B2926),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppFonts.body(fontSize: 16, color: Colors.white, weight: FontWeight.w700),
        contentTextStyle: AppFonts.body(fontSize: 13.5, color: Colors.white70),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1B2926),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gold500,
        contentTextStyle: AppFonts.body(fontSize: 13, color: AppColors.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        textStyle: AppFonts.body(fontSize: 11.5, color: AppColors.ink),
      ),
      dividerColor: const Color(0xFF2A3835),
    );
  }
}
