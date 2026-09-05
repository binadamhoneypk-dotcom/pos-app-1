import 'package:flutter/material.dart';
import '../../features/premium/upgrade_screen.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';

/// The one function every gated action should call first:
///
/// ```dart
/// if (!await PremiumGate.ensure(context, PremiumFeature.barcodeAutoScan,
///     featureLabel: 'کیمرہ بار کوڈ اسکینر')) return;
/// // ... proceed with the premium action ...
/// ```
///
/// Shows an upsell dialog naming the feature when locked, with a button
/// to [UpgradeScreen]. Returns `true` immediately (no dialog) if the
/// feature is already unlocked.
class PremiumGate {
  PremiumGate._();

  static Future<bool> ensure(
    BuildContext context,
    PremiumFeature feature, {
    required String featureLabel,
  }) async {
    if (PremiumService.instance.isUnlocked(feature)) return true;

    final upgraded = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.gold500, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('پریمیم فیچر')),
          ],
        ),
        content: Text('"$featureLabel" پریمیم پلان میں شامل ہے۔ اپ گریڈ کر کے یہ فیچر فوری استعمال کریں۔'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('ٹھیک ہے')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            },
            child: const Text('اپ گریڈ کریں'),
          ),
        ],
      ),
    );
    // Re-check after returning from UpgradeScreen — the dev toggle (or,
    // later, a real purchase) may have unlocked it in the meantime.
    return upgraded == true || PremiumService.instance.isUnlocked(feature);
  }
}

/// Small "پریمیم" lock chip to place next to a menu item/label so
/// locked features are visibly marked before the user even taps them.
class PremiumLockBadge extends StatelessWidget {
  const PremiumLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.gold100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock_outline, size: 10, color: AppColors.gold500),
          SizedBox(width: 3),
          Text('پریمیم', style: TextStyle(fontSize: 9.5, color: AppColors.gold500, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
