import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Shown whenever [PremiumGate.ensure] blocks a locked feature, or from
/// "مزید" → "پریمیم اپ گریڈ". Lists what Premium unlocks.
///
/// IMPORTANT: the "ٹیسٹنگ" section at the bottom is a temporary manual
/// on/off switch so premium/free states can be tested right now,
/// without waiting on a payment provider. Delete that section (and
/// nothing else) once real payment is wired in — see the TODO on
/// [PremiumService.setPremium] for exactly where a real purchase should
/// call in from.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  static List<(String, String, String)> _features(AppLocalizations t) => [
        ('📷', t.autoBarcodeQrScanFeatureLabel, t.noSeparateScannerNeededMessage),
        ('🕌', t.fullZakatCalculatorFeatureLabel, t.nisabLunarYearDetailMessage),
        ('🏪', t.multipleShopsFeatureLabel, t.runMultipleShopsMessage),
        ('📦', t.unlimitedInventoryItemsFeatureLabel, t.freeItemLimitMessage(AppConstants.freeMaxItems)),
        ('👥', t.staffManagerAccountsFeatureLabel, t.separateTeamLoginsMessage),
        ('📊', t.reportsExportFeatureLabel, t.fullSalesProfitReportsMessage),
        ('🧾', t.pdfBillLogoWatermarkFeatureLabel, t.printedBillsBrandingMessage),
        ('☁️', t.multiDeviceSyncFeatureLabel, t.runSameShopMultipleDevicesMessage),
      ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final premiumService = context.watch<PremiumService>();

    return Scaffold(
      appBar: AppBar(title: Text(t.premiumUpgradeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gold100, Colors.white]),
              border: Border.all(color: const Color(0xFFEAD9A0)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  premiumService.isPremium ? Icons.verified : Icons.lock_open_outlined,
                  color: AppColors.gold500,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    premiumService.isPremium ? t.premiumPlanActiveMessage : t.onFreePlanMessage,
                    style: AppFonts.body(fontSize: 14, color: AppColors.zakatText, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(t.premiumPlanIncludesLabel,
              style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final f in _features(t)) _featureRow(f.$1, f.$2, f.$3),

          const SizedBox(height: 24),
          ElevatedButton(
            // TODO(payment-integration): replace onPressed with the real
            // purchase flow (Play Billing / pos_api activation) once
            // decided. It should end by calling
            // PremiumService.instance.setPremium(true, ...).
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.paymentNotYetAddedMessage)),
              );
            },
            child: Text(t.buyNowLabel),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔧 ${t.testingSectionTitle}',
                    style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  t.testingSectionDescriptionMessage,
                  style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: premiumService.isPremium,
                  title: Text(t.premiumTestingModeLabel, style: const TextStyle(fontSize: 13)),
                  onChanged: (v) => PremiumService.instance.setPremium(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.body(fontSize: 13, weight: FontWeight.w600)),
                Text(subtitle, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
