import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/customer.dart';
import '../../core/utils/app_format.dart';
import '../../l10n/app_localizations.dart';

/// Builds the pre-written reminder message and opens the OS share sheet
/// (SMS/WhatsApp/anything installed) — per the locked Phase 3 design:
/// "کم از کم SMS/WhatsApp پہلے سے لکھے پیغام کے ساتھ شیئر شیٹ کھولے
/// (مکمل خودکار بھیجنا اس فیز میں ضروری نہیں)". Sending itself is left
/// to whichever app the user picks from the share sheet.
class ReminderHelper {
  ReminderHelper._();

  /// The reminder text in Urdu, worded for the amount's sign — a
  /// customer who owes money gets a "please pay" message; if the shop
  /// owes THEM, wording flips to acknowledge that instead so this never
  /// reads like a demand when it shouldn't.
  static String buildMessage(AppLocalizations t, Customer contact) {
    final amountText = AppFormat.currency(contact.currentBalance.abs());
    if (contact.currentBalance > 0) {
      // They owe us.
      return contact.isSupplier
          ? t.reminderSupplierTheyOweMessage(contact.name, amountText)
          : t.reminderCustomerTheyOweMessage(contact.name, amountText);
    } else if (contact.currentBalance < 0) {
      // We owe them.
      return contact.isSupplier
          ? t.reminderSupplierWeOweMessage(contact.name, amountText)
          : t.reminderCustomerWeOweMessage(contact.name, amountText);
    }
    return t.reminderSettledMessage(contact.name);
  }

  /// Opens the native share sheet with [buildMessage]'s text — works for
  /// SMS, WhatsApp, or anything else installed, without needing the
  /// phone number at all.
  static Future<void> shareReminder(AppLocalizations t, Customer contact) async {
    await SharePlus.instance.share(ShareParams(text: buildMessage(t, contact)));
  }

  /// Direct "WhatsApp پر بھیجیں" quick action for when a phone number is
  /// on file — skips the share-sheet chooser and opens WhatsApp with the
  /// message pre-filled. Returns false if there's no phone number or
  /// WhatsApp can't be opened, so the caller can fall back to
  /// [shareReminder].
  static Future<bool> openWhatsApp(AppLocalizations t, Customer contact) async {
    final phone = contact.phone?.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone == null || phone.isEmpty) return false;

    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(buildMessage(t, contact))}');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
