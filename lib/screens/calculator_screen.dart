import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../logic/calculator_engine.dart';
import 'login_screen.dart';

/// Kalkulyator oynasi: tepada ifoda va natija, pastda tugmalar.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.username});

  /// Tizimga kirgan foydalanuvchining logini.
  final String username;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  /// Butun hisoblash mantig'i shu obyektda. Oyna faqat uning holatini
  /// ko'rsatadi va tugma bosilishlarini unga uzatadi.
  final CalculatorEngine _engine = CalculatorEngine();

  /// Tugma bosilganda: amal bajariladi va ekran qayta chiziladi.
  void _press(VoidCallback action) {
    HapticFeedback.selectionClick();
    setState(action);
  }

  /// Tugmalar jadvali (5 qator × 4 ustun).
  List<List<_KeySpec>> _buildKeys() {
    _KeySpec digit(int value) => _KeySpec(
      id: '$value',
      label: '$value',
      kind: _KeyKind.digit,
      action: () => _engine.inputDigit(value),
    );
    _KeySpec operator(String id, String label, Sym sym) => _KeySpec(
      id: id,
      label: label,
      largeLabel: true,
      kind: _KeyKind.operator,
      action: () => _engine.inputOperator(sym),
    );

    return [
      [
        _KeySpec(
          id: 'clear',
          label: 'AC',
          kind: _KeyKind.action,
          action: _engine.clear,
        ),
        _KeySpec(
          id: 'parens',
          label: '( )',
          kind: _KeyKind.operator,
          action: _engine.inputParenthesis,
        ),
        _KeySpec(
          id: 'percent',
          label: '%',
          kind: _KeyKind.operator,
          action: _engine.inputPercent,
        ),
        operator('divide', '÷', Sym.divide),
      ],
      [digit(7), digit(8), digit(9), operator('times', '×', Sym.times)],
      [digit(4), digit(5), digit(6), operator('minus', '−', Sym.minus)],
      [digit(1), digit(2), digit(3), operator('plus', '+', Sym.plus)],
      [
        digit(0),
        _KeySpec(
          id: 'dot',
          label: '.',
          kind: _KeyKind.digit,
          action: _engine.inputDot,
        ),
        _KeySpec(
          id: 'backspace',
          icon: Icons.backspace_outlined,
          semanticLabel: "O'chirish",
          kind: _KeyKind.digit,
          action: _engine.backspace,
          // Uzoq bosib turilsa, hammasi tozalanadi.
          longPressAction: _engine.clear,
        ),
        _KeySpec(
          id: 'equals',
          label: '=',
          largeLabel: true,
          kind: _KeyKind.equals,
          action: _engine.evaluate,
        ),
      ],
    ];
  }

  /// Ekrandagi ifoda yoki natijani nusxalaydi (ekranni uzoq bosganda).
  Future<void> _copyDisplay() async {
    final text = _engine.display.replaceAll(groupSeparator, '');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Nusxalandi'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  /// Hisoblar tarixini pastdan chiqadigan oynada ko'rsatadi.
  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _HistorySheet(
        entries: _engine.history,
        onSelected: (entry) {
          Navigator.of(sheetContext).pop();
          setState(() => _engine.useHistory(entry));
        },
        onClear: () {
          Navigator.of(sheetContext).pop();
          setState(_engine.clearHistory);
        },
      ),
    );
  }

  /// Chiqishni tasdiqlatadi va login oynasiga qaytaradi.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Hisobdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Yo'q"),
          ),
          FilledButton(
            key: const Key('logout_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ha, chiqish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kalkulyator'),
            Text(
              'Foydalanuvchi: ${widget.username}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('history_button'),
            tooltip: 'Tarix',
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Chiqish',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final display = _Display(
              engine: _engine,
              onLongPress: _copyDisplay,
            );
            final keypad = _Keypad(rows: _buildKeys(), onPressed: _press);

            if (constraints.maxWidth > constraints.maxHeight) {
              // Yotiq holat: chapda ekran, o'ngda tugmalar.
              return Row(
                children: [
                  Expanded(child: display),
                  SizedBox(
                    width: math.min(constraints.maxWidth * 0.55, 560),
                    child: keypad,
                  ),
                ],
              );
            }

            // Tik holat: tepada ekran, pastda tugmalar. Planshetda juda
            // kengayib ketmasligi uchun eni cheklangan.
            final width = math.min(constraints.maxWidth, 480.0);
            final keypadHeight = math.min(
              constraints.maxHeight * 0.66,
              width * 1.2,
            );
            return Center(
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    Expanded(child: display),
                    SizedBox(height: keypadHeight, child: keypad),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Ekran (ifoda va natija)
// -------------------------------------------------------------------------

/// Kalkulyator ekrani. Uch satrdan iborat:
/// 1. oldingi ifoda ("=" bosilgandan keyin);
/// 2. joriy ifoda yoki natija (katta shrift);
/// 3. oldindan hisoblangan natija yoki xato xabari.
class _Display extends StatelessWidget {
  const _Display({required this.engine, required this.onLongPress});

  final CalculatorEngine engine;
  final VoidCallback onLongPress;

  static const double _maxFontSize = 64;
  static const double _minFontSize = 28;

  /// Ifodadagi amal belgilari (ikki son orasidagi) va foiz belgisi.
  static final RegExp _operatorPattern = RegExp(r'(?<= )[+−×÷](?= |$)|%');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = engine.error;
    final preview = engine.preview;
    final previous = engine.lastExpression;
    final main = engine.display;
    final secondaryStyle = theme.textTheme.titleLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.bottomRight,
              // Joy yetmasa (masalan, kichik ekranda) satrlar aylantiriladi.
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _SingleLine(
                      child: Text(
                        previous.isEmpty ? '' : '$previous =',
                        key: const Key('display_previous'),
                        style: secondaryStyle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SingleLine(
                      child: Text.rich(
                        _highlightOperators(main, scheme.primary),
                        key: const Key('display_main'),
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: _fitFontSize(main, constraints.maxWidth),
                          height: 1.15,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SingleLine(
                      child: error != null
                          ? Text(
                              error.message,
                              key: const Key('display_error'),
                              style: secondaryStyle?.copyWith(
                                color: scheme.error,
                              ),
                            )
                          : Text(
                              preview.isEmpty ? '' : '= $preview',
                              key: const Key('display_preview'),
                              style: secondaryStyle,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Matn enga sig'adigan shrift o'lchamini tanlaydi. Eng kichik o'lchamda
  /// ham sig'masa, satr gorizontal aylantiriladi.
  static double _fitFontSize(String text, double width) {
    const averageCharWidth = 0.58; // shrift o'lchamiga nisbatan
    final fitted = width / (math.max(text.length, 1) * averageCharWidth);
    return fitted.clamp(_minFontSize, _maxFontSize);
  }

  /// Amal belgilarini boshqa rangda ko'rsatadi.
  static TextSpan _highlightOperators(String text, Color color) {
    final spans = <TextSpan>[];
    var index = 0;
    for (final match in _operatorPattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(color: color),
        ),
      );
      index = match.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return TextSpan(children: spans);
  }
}

/// Bitta satrga sig'dirilgan matn: uzun bo'lsa, oxiri ko'rinib turadi va
/// barmoq bilan chapga-o'ngga surish mumkin.
class _SingleLine extends StatelessWidget {
  const _SingleLine({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: child,
    );
  }
}

// -------------------------------------------------------------------------
// Tugmalar
// -------------------------------------------------------------------------

/// Tugma turi — rangini belgilaydi.
enum _KeyKind { digit, operator, action, equals }

/// Bitta tugma tavsifi.
class _KeySpec {
  const _KeySpec({
    required this.id,
    required this.kind,
    required this.action,
    this.label,
    this.largeLabel = false,
    this.icon,
    this.semanticLabel,
    this.longPressAction,
  }) : assert(label != null || icon != null);

  /// Tugma nomi; testlarda `Key('key_$id')` orqali topiladi.
  final String id;
  final _KeyKind kind;
  final VoidCallback action;
  final String? label;

  /// Amal belgilari (÷ × − + =) raqamlarga qaraganda mayda ko'rinadi,
  /// shuning uchun ular kattaroq shriftda yoziladi.
  final bool largeLabel;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? longPressAction;
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.rows, required this.onPressed});

  final List<List<_KeySpec>> rows;
  final void Function(VoidCallback action) onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
      child: Column(
        children: [
          for (final row in rows)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final spec in row)
                    Expanded(
                      child: _CalcButton(spec: spec, onPressed: onPressed),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({required this.spec, required this.onPressed});

  final _KeySpec spec;
  final void Function(VoidCallback action) onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (spec.kind) {
      _KeyKind.digit => (scheme.surfaceContainerHigh, scheme.onSurface),
      _KeyKind.operator => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _KeyKind.action => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _KeyKind.equals => (scheme.primary, scheme.onPrimary),
    };
    final longPressAction = spec.longPressAction;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        key: Key('key_${spec.id}'),
        color: background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onPressed(spec.action),
          onLongPress: longPressAction == null
              ? null
              : () => onPressed(longPressAction),
          child: Center(
            // Tugma juda kichrayib ketsa (yotiq holat), belgi ham kichrayadi.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: spec.icon != null
                    ? Icon(
                        spec.icon,
                        size: 28,
                        color: foreground,
                        semanticLabel: spec.semanticLabel,
                      )
                    : Text(
                        spec.label!,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontSize: spec.largeLabel ? 36 : 28,
                          height: 1.1,
                          fontWeight: spec.largeLabel
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: foreground,
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

// -------------------------------------------------------------------------
// Tarix
// -------------------------------------------------------------------------

/// Hisoblar tarixi ro'yxati (pastdan chiqadigan oyna ichida).
class _HistorySheet extends StatelessWidget {
  const _HistorySheet({
    required this.entries,
    required this.onSelected,
    required this.onClear,
  });

  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text("Hozircha tarix bo'sh", style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Tarix', style: theme.textTheme.titleLarge),
                ),
                TextButton.icon(
                  key: const Key('history_clear_button'),
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Tozalash'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  key: Key('history_item_$index'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(entry.expression),
                  subtitle: Text(
                    '= ${entry.result}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => onSelected(entry),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
