import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// The floating calculator button from the locked design: "الگ مینو
/// آپشن نہیں بلکہ ہر متعلقہ سکرین پر ایک تیرتا ہوا گول بٹن — کہیں سے بھی
/// ایک ٹیپ میں کھلے، نتیجہ فیلڈ میں insert ہو سکے۔"
///
/// Usage: wrap a screen's Scaffold body in a Stack and add this as the
/// last child, positioned bottom-start. Pass [onInsertResult] to receive
/// the calculator's final value (e.g. to drop it into a price field) —
/// omit it on screens where the calculator is just a scratch pad.
class CalculatorFab extends StatelessWidget {
  final void Function(double result)? onInsertResult;

  const CalculatorFab({super.key, this.onInsertResult});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 18,
      left: 18,
      child: FloatingActionButton(
        heroTag: 'calculator_fab_${identityHashCode(this)}',
        backgroundColor: AppColors.teal900,
        onPressed: () => _openCalculator(context),
        child: const Icon(Icons.calculate_outlined),
      ),
    );
  }

  void _openCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // Bug fix #5: without this, showModalBottomSheet caps the sheet at
      // roughly half the screen height, so on shorter phones the last
      // key row (0 / . / =) gets pushed past the bottom edge and clipped
      // — that's the "BOTTOM OVERFLOWED" warning. isScrollControlled lets
      // the sheet grow to fit its content (up to the full screen), and
      // the SingleChildScrollView inside _CalculatorSheet handles the
      // rare case where even that isn't enough (very short/landscape
      // screens, or a large system font size).
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CalculatorSheet(onInsertResult: onInsertResult),
    );
  }
}

class _CalculatorSheet extends StatefulWidget {
  final void Function(double result)? onInsertResult;
  const _CalculatorSheet({this.onInsertResult});

  @override
  State<_CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<_CalculatorSheet> {
  String _expression = '';
  String get _display => _expression.isEmpty ? '0' : _expression;

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
      } else if (key == 'back') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (key == '=') {
        _expression = _evaluate(_expression);
      } else {
        _expression += key;
      }
    });
  }

  /// Deliberately simple left-to-right evaluator (no operator precedence)
  /// for the small +, -, ×, ÷ expressions this pad produces — avoids
  /// pulling in a full expression-parsing package for a shopkeeper's
  /// quick sum.
  String _evaluate(String expr) {
    try {
      final tokens = <String>[];
      var current = '';
      for (final ch in expr.split('')) {
        if ('+-*/'.contains(ch)) {
          if (current.isNotEmpty) tokens.add(current);
          tokens.add(ch);
          current = '';
        } else {
          current += ch;
        }
      }
      if (current.isNotEmpty) tokens.add(current);
      if (tokens.isEmpty) return '';

      double result = double.tryParse(tokens.first) ?? 0;
      for (var i = 1; i < tokens.length - 1; i += 2) {
        final op = tokens[i];
        final next = double.tryParse(tokens[i + 1]) ?? 0;
        switch (op) {
          case '+':
            result += next;
            break;
          case '-':
            result -= next;
            break;
          case '*':
            result *= next;
            break;
          case '/':
            result = next == 0 ? double.nan : result / next;
            break;
        }
      }
      if (result.isNaN) return 'Error';
      return result == result.roundToDouble()
          ? result.toInt().toString()
          : result.toStringAsFixed(2);
    } catch (_) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Cap the sheet at ~88% of the available screen height, and let it
    // scroll internally past that point, so the "0", ".", and "="
    // buttons are always on-screen and tappable — the fix for bug #5.
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('🧮 ${t.calculatorLabel}', style: AppFonts.body(fontSize: 13, weight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _display,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _keyGrid(),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold500),
                  onPressed: widget.onInsertResult == null
                      ? () => Navigator.of(context).pop()
                      : () {
                          final value = double.tryParse(_expression.isEmpty ? '0' : _expression);
                          if (value != null) widget.onInsertResult!(value);
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    widget.onInsertResult == null ? t.closeLabel : t.insertIntoResultFieldLabel,
                    style: AppFonts.body(fontSize: 13, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyGrid() {
    Widget key(String label, {String? value, Color? bg, Color? fg}) {
      return _CalcKey(
        label: label,
        onTap: () => _press(value ?? label),
        background: bg,
        foreground: fg,
      );
    }

    return Column(
      children: [
        Row(children: [
          key('C', bg: AppColors.paper, fg: AppColors.danger),
          key('÷', value: '/', bg: AppColors.teal100, fg: AppColors.teal800),
          key('×', value: '*', bg: AppColors.teal100, fg: AppColors.teal800),
          key('⌫', value: 'back'),
        ]),
        Row(children: [
          key('7'), key('8'), key('9'),
          key('−', value: '-', bg: AppColors.teal100, fg: AppColors.teal800),
        ]),
        Row(children: [
          key('4'), key('5'), key('6'),
          key('+', bg: AppColors.teal100, fg: AppColors.teal800),
        ]),
        Row(children: [
          key('1'), key('2'), key('3'),
          key('=', bg: AppColors.teal700, fg: Colors.white),
        ]),
        Row(children: [
          Expanded(flex: 2, child: key('0')),
          key('.'),
          const Expanded(child: SizedBox()),
        ]),
      ],
    );
  }
}

class _CalcKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? background;
  final Color? foreground;

  const _CalcKey({required this.label, required this.onTap, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: background ?? AppColors.paper,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foreground ?? AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
