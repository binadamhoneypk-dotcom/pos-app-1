import '../constants/app_constants.dart';

/// Pure calculation helpers behind the Zakat Calculator + the Dashboard's
/// collapsed "زکوٰۃ کی حیثیت" card. Deliberately has no database or
/// widget dependencies so the math itself is easy to double-check.
///
/// This mirrors the exact wording already approved in the HTML
/// prototype: "قمری سال (تقریباً 354 دن) مکمل ہونے پر..." — this is a
/// supporting estimate, not a fatwa. Every screen that shows a result
/// from this class must keep the disclaimer visible next to it.
class ZakatService {
  ZakatService._();

  /// Nisab threshold in local currency, from either the gold or silver
  /// standard. Silver gives a lower (more cautious) threshold and is
  /// what most contemporary shopkeeper-Zakat guidance recommends for
  /// trade wealth — but the toggle is left to the user/their mufti.
  static double nisabThreshold({
    required bool useSilverStandard,
    required double goldRatePerGram,
    required double silverRatePerGram,
  }) {
    return useSilverStandard
        ? AppConstants.nisabSilverGrams * silverRatePerGram
        : AppConstants.nisabGoldGrams * goldRatePerGram;
  }

  static bool isAboveNisab({required double totalWealth, required double nisabThreshold}) {
    return totalWealth >= nisabThreshold && nisabThreshold > 0;
  }

  /// Zakat due = 2.5% of total zakatable wealth, once a full lunar year
  /// has passed above nisab.
  static double zakatDue(double totalWealth) => totalWealth * 0.025;

  static DateTime expectedCompletionDate(DateTime startDate) {
    return startDate.add(const Duration(days: AppConstants.lunarYearApproxDays));
  }

  static bool lunarYearComplete(DateTime startDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return !today.isBefore(expectedCompletionDate(startDate));
  }
}
