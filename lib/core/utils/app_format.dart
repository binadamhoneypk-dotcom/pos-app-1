/// Google AI Studio prompt, Feature 2 — "Currency symbol/prefix... default
/// Rs. Replace every hardcoded 'Rs ' literal across the app with a lookup
/// from this setting."
///
/// A plain static holder (not a Provider-only value) on purpose: several
/// call sites that need currency formatting — [ReminderHelper]'s static
/// message builder, `InputDecoration(prefixText: ...)` inside `const`-free
/// but otherwise simple widget trees — have no convenient `BuildContext`
/// to `context.watch<AppState>()` from. [AppState] is still the single
/// source of truth and the only thing allowed to change [currencySymbol]
/// (via `setCurrencySymbol`, which persists to `shared_preferences` AND
/// updates this static field in the same call) — this class just makes
/// the current value readable from anywhere without threading a
/// `BuildContext` through every helper and model.
class AppFormat {
  AppFormat._();

  static String currencySymbol = 'Rs';

  /// e.g. `AppFormat.currency(1500)` → `'Rs 1500'`.
  static String currency(num amount, {int decimals = 0}) => '$currencySymbol ${amount.toStringAsFixed(decimals)}';

  /// For `InputDecoration(prefixText: AppFormat.pricePrefix)` fields.
  static String get pricePrefix => '$currencySymbol ';
}
