import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// "بل کی سیٹنگز": شاپ کیپر کا نام (3 فونٹ آپشنز میں سے)، لوگو کارنر
/// پوزیشن، درمیانی واٹرمارک (نام/لوگو/مخفف + موبائل نمبر)، اور Live
/// preview۔
///
/// Phase 2 saves these choices and shows the live preview described in
/// the locked design; Phase 4 ("PDF Invoicing — letterhead/watermark
/// settings کا اطلاق") is what actually stamps them onto a generated
/// PDF bill. Logo image upload needs an image-picker dependency this
/// phase doesn't add yet, so that one control is shown but disabled
/// with a note — everything else here is fully functional today.
class LetterheadSettingsScreen extends StatefulWidget {
  const LetterheadSettingsScreen({super.key});

  @override
  State<LetterheadSettingsScreen> createState() => _LetterheadSettingsScreenState();
}

class _LetterheadSettingsScreenState extends State<LetterheadSettingsScreen> {
  static const _kNameKey = 'letterhead_name';
  static const _kFontKey = 'letterhead_font';
  static const _kCornerKey = 'letterhead_logo_corner';
  static const _kWatermarkTypeKey = 'letterhead_watermark_type'; // none|name|initials
  static const _kWatermarkTextKey = 'letterhead_watermark_text';
  static const _kMobileKey = 'letterhead_mobile';

  final _nameCtrl = TextEditingController();
  final _watermarkTextCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String _font = 'nastaliq';
  String _corner = 'right';
  String _watermarkType = 'none';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = prefs.getString(_kNameKey) ?? '';
      _font = prefs.getString(_kFontKey) ?? 'nastaliq';
      _corner = prefs.getString(_kCornerKey) ?? 'right';
      _watermarkType = prefs.getString(_kWatermarkTypeKey) ?? 'none';
      _watermarkTextCtrl.text = prefs.getString(_kWatermarkTextKey) ?? '';
      _mobileCtrl.text = prefs.getString(_kMobileKey) ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNameKey, _nameCtrl.text.trim());
    await prefs.setString(_kFontKey, _font);
    await prefs.setString(_kCornerKey, _corner);
    await prefs.setString(_kWatermarkTypeKey, _watermarkType);
    await prefs.setString(_kWatermarkTextKey, _watermarkTextCtrl.text.trim());
    await prefs.setString(_kMobileKey, _mobileCtrl.text.trim());
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.letterheadSavedMessage)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.billSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.teal100, borderRadius: BorderRadius.circular(8)),
            child: Text(
              t.billSettingsSavedNoticeMessage,
              style: AppFonts.body(fontSize: 11.5, color: AppColors.teal900),
            ),
          ),
          const SizedBox(height: 18),

          Text(t.logoLabel, style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: null, // needs an image-picker dependency — Phase 4
            icon: const Icon(Icons.image_outlined),
            label: Text(t.uploadLogoPhase4Label),
          ),
          const SizedBox(height: 10),
          Text(t.logoPositionLabel, style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  value: 'right',
                  groupValue: _corner,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.rightCornerLabel, style: const TextStyle(fontSize: 13)),
                  onChanged: (v) => setState(() => _corner = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: 'left',
                  groupValue: _corner,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.leftCornerLabel, style: const TextStyle(fontSize: 13)),
                  onChanged: (v) => setState(() => _corner = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(t.shopOwnerNameLabel, style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: t.shopOwnerNameHintExample)),
          const SizedBox(height: 10),
          Text(t.fontLabel, style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft)),
          Wrap(
            spacing: 8,
            children: AppFonts.letterheadFontLabels.entries.map((e) {
              return ChoiceChip(
                label: Text(e.value),
                selected: _font == e.key,
                onSelected: (_) => setState(() => _font = e.key),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Text(t.centerWatermarkLabel, style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          RadioListTile<String>(
            value: 'none',
            groupValue: _watermarkType,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(t.noneLabel, style: const TextStyle(fontSize: 13)),
            onChanged: (v) => setState(() => _watermarkType = v!),
          ),
          RadioListTile<String>(
            value: 'name',
            groupValue: _watermarkType,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(t.fullNameOrLogoLabel, style: const TextStyle(fontSize: 13)),
            onChanged: (v) => setState(() => _watermarkType = v!),
          ),
          RadioListTile<String>(
            value: 'initials',
            groupValue: _watermarkType,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(t.initialsLabel, style: const TextStyle(fontSize: 13)),
            onChanged: (v) => setState(() => _watermarkType = v!),
          ),
          if (_watermarkType != 'none') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _watermarkTextCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _watermarkType == 'initials' ? t.initialsHintExample : t.fullNameLabel,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _mobileCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: t.mobileNumberWatermarkHint),
          ),

          const SizedBox(height: 20),
          Text(t.livePreviewLabel, style: AppFonts.body(fontSize: 13, color: AppColors.teal800, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          _preview(t),

          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: Text(t.save)),
        ],
      ),
    );
  }

  Widget _preview(AppLocalizations t) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          if (_watermarkType != 'none')
            Center(
              child: Opacity(
                opacity: 0.12,
                child: Text(
                  _watermarkType == 'initials'
                      ? (_watermarkTextCtrl.text.isEmpty ? 'TK' : _watermarkTextCtrl.text)
                      : (_watermarkTextCtrl.text.isEmpty ? _nameCtrl.text : _watermarkTextCtrl.text),
                  style: AppFonts.letterheadFont(_font, fontSize: 40, color: AppColors.teal900),
                ),
              ),
            ),
          Align(
            alignment: _corner == 'right' ? Alignment.topRight : Alignment.topLeft,
            child: Text(
              _nameCtrl.text.isEmpty ? t.shopNameLabel : _nameCtrl.text,
              style: AppFonts.letterheadFont(_font, fontSize: 20, color: AppColors.teal900),
            ),
          ),
          if (_mobileCtrl.text.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(_mobileCtrl.text, style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
            ),
        ],
      ),
    );
  }
}
