import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/business.dart';
import '../../core/services/zakat_service.dart';
import '../../core/theme/app_theme.dart';
import '../zakat/zakat_calculator_screen.dart';

/// Full Zakat detail, per the locked design:
/// "تفصیل میں شامل ہو: صاحبِ نصاب بننے کی تاریخ، قمری سال مکمل ہونے کی
/// متوقع تاریخ، اور یہ نوٹ کہ 'یہ ایک معاون اندازہ ہے، حتمی شرعی فتویٰ
/// نہیں — اپنے مسلک کے مفتی صاحب سے رجوع کریں'۔"
class ZakatDetailSheet extends StatelessWidget {
  final Business business;
  const ZakatDetailSheet({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final hasStartDate = business.zakatStartDate != null;
    final startDate =
        hasStartDate ? DateTime.fromMillisecondsSinceEpoch(business.zakatStartDate!) : null;
    final completionDate = startDate != null ? ZakatService.expectedCompletionDate(startDate) : null;
    final dateFmt = DateFormat('d MMMM yyyy', 'ur');

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(20)),
                child: const Text('زکوٰۃ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasStartDate ? 'زکوٰۃ کی حیثیت' : 'نصاب ابھی سیٹ نہیں',
                  style: AppFonts.body(fontSize: 15, weight: FontWeight.w700),
                ),
              ),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 10),
          if (hasStartDate) ...[
            _row('صاحبِ نصاب بننے کی تاریخ', dateFmt.format(startDate!)),
            const SizedBox(height: 6),
            _row('قمری سال مکمل ہونے کی متوقع تاریخ', dateFmt.format(completionDate!)),
            const SizedBox(height: 6),
            _row('نصاب کی حد (مقامی کرنسی)', 'Rs ${business.zakatNisabThreshold.toStringAsFixed(0)}'),
          ] else
            Text(
              'ابھی تک آپ نے زکوٰۃ کیلکولیٹر میں اپنی نصاب کی معلومات درج نہیں کیں۔ اپنا مجموعی مال درج کر کے معلوم کریں کہ آپ صاحبِ نصاب ہیں یا نہیں۔',
              style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'یہ ایک معاون اندازہ ہے، حتمی شرعی فتویٰ نہیں۔ حتمی مسئلے کے لیے براہ کرم اپنے مسلک کے مفتی صاحب سے رجوع کریں۔',
              style: AppFonts.body(fontSize: 11.5, color: AppColors.zakatTextSoft),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()),
                );
              },
              child: Text(hasStartDate ? 'زکوٰۃ کیلکولیٹر دوبارہ چلائیں' : 'زکوٰۃ کیلکولیٹر کھولیں'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft))),
        Text(value, style: AppFonts.body(fontSize: 12.5, weight: FontWeight.w700)),
      ],
    );
  }
}
