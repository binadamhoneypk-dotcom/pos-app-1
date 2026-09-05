import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/premium_service.dart';
import '../../core/theme/app_theme.dart';

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

  static final _features = [
    ('📷', 'کیمرے سے خودکار بار کوڈ/QR سکین', 'الگ ہارڈویئر اسکینر کی ضرورت نہیں'),
    ('🕌', 'مکمل زکوٰۃ کیلکولیٹر', 'نصاب، قمری سال کا حساب، اور تفصیلی معلومات'),
    ('🏪', 'متعدد دکانیں', 'ایک اکاؤنٹ سے ایک سے زیادہ دکانیں چلائیں'),
    ('📦', 'لامحدود انوینٹری آئٹمز', 'فری پلان میں ${AppConstants.freeMaxItems} آئٹمز کی حد ہے'),
    ('👥', 'عملہ/منیجر اکاؤنٹس', 'اپنی ٹیم کو الگ لاگ اِن دیں (فیز 3)'),
    ('📊', 'رپورٹس اور ایکسپورٹ', 'فروخت اور منافع کی مکمل رپورٹس (فیز 4)'),
    ('🧾', 'PDF بل + لوگو/واٹرمارک', 'اپنی برانڈنگ کے ساتھ پرنٹ شدہ بل (فیز 4)'),
    ('☁️', 'ملٹی ڈیوائس Sync', 'ایک ہی دکان کو ایک سے زیادہ فون/ڈیوائسز پر چلائیں'),
  ];

  @override
  Widget build(BuildContext context) {
    final premiumService = context.watch<PremiumService>();

    return Scaffold(
      appBar: AppBar(title: const Text('پریمیم اپ گریڈ')),
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
                    premiumService.isPremium ? 'آپ کا پریمیم پلان فعال ہے' : 'آپ فری پلان پر ہیں',
                    style: AppFonts.body(fontSize: 14, color: AppColors.zakatText, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('پریمیم پلان میں شامل ہے:',
              style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final f in _features) _featureRow(f.$1, f.$2, f.$3),

          const SizedBox(height: 24),
          ElevatedButton(
            // TODO(payment-integration): replace onPressed with the real
            // purchase flow (Play Billing / pos_api activation) once
            // decided. It should end by calling
            // PremiumService.instance.setPremium(true, ...).
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('پیمنٹ ابھی شامل نہیں کی گئی — نیچے ٹیسٹنگ ٹوگل استعمال کریں')),
              );
            },
            child: const Text('ابھی خریدیں'),
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
                Text('🔧 ٹیسٹنگ (پیمنٹ آنے تک عارضی)',
                    style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'اصل پیمنٹ سسٹم آنے تک، یہاں سے دستی طور پر پریمیم آن/آف کر کے دونوں حالتیں ٹیسٹ کریں۔',
                  style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: premiumService.isPremium,
                  title: const Text('پریمیم (ٹیسٹنگ موڈ)', style: TextStyle(fontSize: 13)),
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
