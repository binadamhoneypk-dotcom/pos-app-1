import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/business.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/zakat_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../l10n/app_localizations.dart';
import '../zakat_detail_sheet.dart';

/// "ڈیش بورڈ پر ہمیشہ ایک چھوٹا سا collapsed بیج/کارڈ ('زکوٰۃ کی حیثیت')
/// دکھے، مکمل تفصیل صرف tap کرنے پر ایک bottom-sheet modal میں کھلے۔"
///
/// The full detail (dates, nisab math) is a Premium feature — the
/// collapsed card is always visible as a teaser, but tapping it while
/// on the free plan shows the upgrade prompt instead of the real dates.
class ZakatCard extends StatelessWidget {
  final Business business;
  const ZakatCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isPremium = context.watch<PremiumService>().isUnlocked(PremiumFeature.zakatCalculator);
    final hasStartDate = business.zakatStartDate != null;
    final startDate = hasStartDate
        ? DateTime.fromMillisecondsSinceEpoch(business.zakatStartDate!)
        : null;
    final aboveNisab = hasStartDate; // start date is only ever set once nisab was reached

    final title = !isPremium
        ? t.zakatInfoTapForDetailsMessage
        : aboveNisab
            ? t.aboveNisabMessage
            : t.nisabInfoNotSetMessage;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final ok = await PremiumGate.ensure(context, PremiumFeature.zakatCalculator,
            featureLabel: t.fullZakatInfoFeatureLabel);
        if (!ok || !context.mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (_) => ZakatDetailSheet(business: business),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gold100, Colors.white],
          ),
          border: Border.all(color: const Color(0xFFEAD9A0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold500,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.zakatWord, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppFonts.body(fontSize: 13, color: AppColors.zakatText, weight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isPremium)
              const Icon(Icons.lock_outline, color: AppColors.gold500, size: 16)
            else ...[
              Text(
                // NOTE: uses the default ('en') DateFormat locale on
                // purpose — Urdu month names need initializeDateFormatting()
                // called first (see main.dart) or this throws at runtime.
                startDate != null
                    ? DateFormat('d MMM yyyy').format(ZakatService.expectedCompletionDate(startDate))
                    : '',
                style: AppFonts.body(fontSize: 11, color: AppColors.zakatTextSoft),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left, color: AppColors.zakatTextSoft, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
