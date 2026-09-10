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

/// Font helpers. The bill/letterhead "kashida/nastaliq" font choice from
/// the locked design lives here too, so Phase 4's PDF invoice code and
/// this screen's live preview both read from one place.
class AppFonts {
  AppFonts._();

  /// Page titles / brand headings — matches `.page-title` /
  /// `.brand-title` in the HTML prototype (Noto Nastaliq Urdu).
  static TextStyle nastaliq({double fontSize = 22, Color? color, FontWeight? weight}) =>
      GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize,
        color: color ?? AppColors.teal900,
        fontWeight: weight ?? FontWeight.w700,
      );

  /// Body Urdu text — matches the prototype's default body font
  /// (Noto Sans Arabic).
  static TextStyle body({double fontSize = 14, Color? color, FontWeight? weight}) =>
      GoogleFonts.notoSansArabic(
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
        return GoogleFonts.notoNastaliqUrdu(fontSize: fontSize, color: color, fontWeight: FontWeight.w700);
    }
  }
}

class AppTheme {
  AppTheme._();

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
      textTheme: GoogleFonts.notoSansArabicTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.teal700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.body(fontSize: 17, color: Colors.white, weight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal700, width: 1.5),
        ),
        labelStyle: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppFonts.body(fontSize: 15, color: Colors.white, weight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal900,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.teal700,
        unselectedItemColor: AppColors.inkSoft,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.line,
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
      textTheme: GoogleFonts.notoSansArabicTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0E1917),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.body(fontSize: 17, color: Colors.white, weight: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1B2926),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A3835)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1B2926),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A3835), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A3835), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal600, width: 1.5),
        ),
        labelStyle: AppFonts.body(fontSize: 12.5, color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppFonts.body(fontSize: 15, color: Colors.white, weight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold500,
        foregroundColor: AppColors.ink,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0E1917),
        selectedItemColor: AppColors.gold500,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: const Color(0xFF2A3835),
    );
  }
}
