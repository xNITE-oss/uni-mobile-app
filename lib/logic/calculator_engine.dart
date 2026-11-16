/// Kalkulyatorning butun mantig'i: tugmalarni qabul qilish, ifodani
/// tekshirish va hisoblash. Bu faylda Flutter'ga bog'liq hech narsa yo'q,
/// shuning uchun uni oddiy unit testlar bilan to'liq tekshirish mumkin.
library;

import 'rational.dart';

/// Ifodada uchraydigan belgilar.
enum Sym { plus, minus, times, divide, percent, leftParen, rightParen }

/// Ifodaning bitta bo'lagi.
sealed class Token {
  const Token();
}

/// Foydalanuvchi terayotgan son. Matn ko'rinishida saqlanadi: "12", "0.", "3.14".
final class NumberToken extends Token {
  const NumberToken(this.text);
  final String text;
}

/// Oldingi hisobning natijasi. Aniq qiymati saqlanadi, shuning uchun
/// 1 ÷ 3 = 0.333… dan keyin × 3 bosilsa, natija aynan 1 chiqadi.
final class ValueToken extends Token {
  const ValueToken(this.value);
  final Rational value;
}

/// Amal belgisi, foiz yoki qavs.
final class SymbolToken extends Token {
  const SymbolToken(this.sym);
  final Sym sym;
}

/// "=" bosilganda chiqishi mumkin bo'lgan xatolar.
enum CalcError {
  divisionByZero("Nolga bo'lib bo'lmaydi"),
  incomplete('Ifoda tugallanmagan');

  const CalcError(this.message);

  /// Ekranda ko'rsatiladigan matn.
  final String message;
}

/// Tarixdagi bitta hisob.
class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.value,
  });

  /// Ifoda, masalan: `12 × (3 + 4)`.
  final String expression;

  /// Natija, masalan: `84`.
  final String result;

  /// Natijaning aniq qiymati.
  final Rational value;
}

/// Minglik xonalarni ajratuvchi belgi (uzilmaydigan bo'sh joy).
const String groupSeparator = ' ';

/// `-1234567.5` → `−1 234 567.5`, `1.5E-8` → `1.5E−8`.
String formatNumberText(String raw) {
  var text = raw;
  var sign = '';
  if (text.startsWith('-')) {
    sign = '−';
    text = text.substring(1);
  }
  var exponent = '';
  final eIndex = text.indexOf('E');
  if (eIndex >= 0) {
    exponent = 'E${text.substring(eIndex + 1).replaceFirst('-', '−')}';
    text = text.substring(0, eIndex);
  }
  final dot = text.indexOf('.');
  final intPart = dot >= 0 ? text.substring(0, dot) : text;
  final rest = dot >= 0 ? text.substring(dot) : '';
  return '$sign${_groupThousands(intPart)}$rest$exponent';
}

/// Aniq qiymatni ekranga chiqariladigan ko'rinishga keltiradi.
String formatRational(Rational value) =>
    formatNumberText(value.toDecimalString());

String _groupThousands(String digits) {
  if (digits.length <= 3) return digits;
  final buffer = StringBuffer();
  final head = digits.length % 3;
  if (head > 0) buffer.write(digits.substring(0, head));
  for (var i = head; i < digits.length; i += 3) {
    if (buffer.isNotEmpty) buffer.write(groupSeparator);
    buffer.write(digits.substring(i, i + 3));
  }
  return buffer.toString();
}

/// Kalkulyator holati va barcha amallari.
class CalculatorEngine {
  /// Bitta sondagi raqamlar soni chegarasi.
  static const int maxDigits = 15;

  /// Ifodadagi bo'laklar soni chegarasi.
  static const int maxTokens = 60;

  /// Tarixda saqlanadigan hisoblar soni.
  static const int maxHistory = 50;

  static const _minus = SymbolToken(Sym.minus);
  static const _times = SymbolToken(Sym.times);
  static const _percent = SymbolToken(Sym.percent);
  static const _leftParen = SymbolToken(Sym.leftParen);
  static const _rightParen = SymbolToken(Sym.rightParen);

  final List<Token> _tokens = [];
  final List<HistoryEntry> _history = [];
  bool _justEvaluated = false;
  CalcError? _error;
  String _lastExpression = '';

  // ---------------------------------------------------------------------
  // Ekran uchun ma'lumotlar
  // ---------------------------------------------------------------------

  /// Joriy ifoda (yoki "=" dan keyin natija). Bo'sh bo'lsa — bo'sh satr.
  String get expression => _format(_tokens);

  /// Asosiy satrda ko'rsatiladigan matn: ifoda yoki `0`.
  String get display => _tokens.isEmpty ? '0' : expression;

  /// Terish paytida ko'rinadigan oldindan hisoblangan natija.
  ///
  /// Ifodada hali amal bo'lmasa yoki uni hisoblab bo'lmasa — bo'sh satr.
  String get preview {
    if (_justEvaluated || _tokens.isEmpty) return '';
    final tokens = _completed(_tokens, dropDangling: true);
    if (!_hasOperation(tokens)) return '';
    try {
      return formatRational(_Parser(tokens).parse());
    } on DivisionByZeroException {
      return '';
    } on FormatException {
      return '';
    }
  }

  /// "=" bosilgandan keyin: hisoblangan ifoda (yuqori satr uchun).
  String get lastExpression => _justEvaluated ? _lastExpression : '';

  /// Oxirgi "=" natijasi ekranda turibdimi.
  bool get justEvaluated => _justEvaluated;

  /// Oxirgi "=" dagi xato (bo'lmasa `null`).
  CalcError? get error => _error;

  /// Hisoblar tarixi, eng yangisi birinchi.
  List<HistoryEntry> get history => List.unmodifiable(_history);

  // ---------------------------------------------------------------------
  // Tugmalar
  // ---------------------------------------------------------------------

  /// Raqam tugmasi (0–9).
  void inputDigit(int digit) {
    assert(digit >= 0 && digit <= 9);
    _beginInput(startsNewExpression: true);
    final last = _last;
    if (last is NumberToken) {
      if (last.text == '0') {
        // "0" dan keyin raqam: "05" emas, "5" bo'ladi.
        _replaceLast(NumberToken('$digit'));
      } else if (_digitCount(last.text) < maxDigits) {
        _replaceLast(NumberToken('${last.text}$digit'));
      }
      return;
    }
    // ")" yoki "%" dan keyin son kelsa, orasiga "×" qo'yiladi.
    final implicitTimes = _endsWithOperand;
    if (!_hasRoomFor(implicitTimes ? 2 : 1)) return;
    if (implicitTimes) _tokens.add(_times);
    _tokens.add(NumberToken('$digit'));
  }

  /// O'nli nuqta tugmasi.
  void inputDot() {
    _beginInput(startsNewExpression: true);
    final last = _last;
    if (last is NumberToken) {
      if (!last.text.contains('.') && _digitCount(last.text) < maxDigits) {
        _replaceLast(NumberToken('${last.text}.'));
      }
      return;
    }
    final implicitTimes = _endsWithOperand;
    if (!_hasRoomFor(implicitTimes ? 2 : 1)) return;
    if (implicitTimes) _tokens.add(_times);
    _tokens.add(const NumberToken('0.'));
  }

  /// Amal tugmasi: [Sym.plus], [Sym.minus], [Sym.times] yoki [Sym.divide].
  void inputOperator(Sym op) {
    assert(_isOperator(op));
    _beginInput(startsNewExpression: false);
    if (op == Sym.minus) {
      _inputMinus();
    } else {
      _inputBinaryOperator(op);
    }
  }

  /// Foiz tugmasi. Faqat son, natija yoki ")" dan keyin qo'yiladi.
  void inputPercent() {
    _beginInput(startsNewExpression: false);
    final last = _last;
    final allowed =
        last is NumberToken ||
        last is ValueToken ||
        _isSym(last, Sym.rightParen);
    if (!allowed || !_hasRoomFor(1)) return;
    _trimTrailingDot();
    _tokens.add(_percent);
  }

  /// "( )" tugmasi: vaziyatga qarab "(" yoki ")" qo'yadi.
  void inputParenthesis() {
    _beginInput(startsNewExpression: true);
    if (!_endsWithOperand) {
      // Boshida, amaldan yoki "(" dan keyin — yangi qavs ochiladi.
      if (_hasRoomFor(1, dangling: true)) _tokens.add(_leftParen);
      return;
    }
    if (_openParens > 0) {
      // Ochiq qavs bor va undan keyin son turibdi — qavs yopiladi.
      if (!_hasRoomFor(1)) return;
      _trimTrailingDot();
      _tokens.add(_rightParen);
    } else {
      // Ochiq qavs yo'q: "5(" → "5 × (".
      if (!_hasRoomFor(2, dangling: true)) return;
      _trimTrailingDot();
      _tokens
        ..add(_times)
        ..add(_leftParen);
    }
  }

  /// Oxirgi belgini o'chiradi. "=" dan keyin bosilsa, hammasini tozalaydi.
  void backspace() {
    _error = null;
    if (_justEvaluated) {
      clear();
      return;
    }
    final last = _last;
    if (last == null) return;
    if (last is NumberToken && last.text.length > 1) {
      _replaceLast(NumberToken(last.text.substring(0, last.text.length - 1)));
    } else {
      _tokens.removeLast();
    }
  }

  /// Hammasini tozalaydi (tarix saqlanib qoladi).
  void clear() {
    _tokens.clear();
    _error = null;
    _justEvaluated = false;
    _lastExpression = '';
  }

  /// "=" tugmasi: ifodani hisoblaydi.
  ///
  /// Xato bo'lsa ([error]) ifoda o'zgarmaydi — foydalanuvchi uni tuzatib,
  /// davom ettirishi mumkin.
  void evaluate() {
    _error = null;
    if (_tokens.isEmpty || _justEvaluated) return;
    if (_isDangling(_tokens.last)) {
      _error = CalcError.incomplete;
      return;
    }
    _trimTrailingDot();
    // Yopilmagan qavslar avtomatik yopiladi: "(2 + 3" → "(2 + 3)".
    final tokens = _completed(_tokens, dropDangling: false);
    try {
      final value = _Parser(tokens).parse();
      final hasOperation = _hasOperation(tokens);
      final expressionText = _format(tokens);
      if (hasOperation) {
        _history.insert(
          0,
          HistoryEntry(
            expression: expressionText,
            result: formatRational(value),
            value: value,
          ),
        );
        if (_history.length > maxHistory) _history.removeLast();
      }
      _lastExpression = hasOperation ? expressionText : '';
      _tokens
        ..clear()
        ..add(ValueToken(value));
      _justEvaluated = true;
    } on DivisionByZeroException {
      _error = CalcError.divisionByZero;
    } on FormatException {
      _error = CalcError.incomplete;
    }
  }

  /// Tarixdagi hisobni qayta ekranga chiqaradi (natijasi bilan davom
  /// ettirish uchun).
  void useHistory(HistoryEntry entry) {
    _error = null;
    _tokens
      ..clear()
      ..add(ValueToken(entry.value));
    _lastExpression = entry.expression;
    _justEvaluated = true;
  }

  /// Tarixni tozalaydi.
  void clearHistory() => _history.clear();

  // ---------------------------------------------------------------------
  // Ichki yordamchi funksiyalar
  // ---------------------------------------------------------------------

  Token? get _last => _tokens.isEmpty ? null : _tokens.last;

  /// Ifoda son, natija, ")" yoki "%" bilan tugayaptimi.
  bool get _endsWithOperand => _isOperandEnd(_last);

  /// Yopilmagan qavslar soni.
  int get _openParens => _countOpenParens(_tokens);

  /// Ifodaga yana [count] ta bo'lak sig'adimi.
  ///
  /// Amal belgisi va "(" kabi "osilib qoladigan" bo'laklar uchun bitta joy
  /// zaxirada qoldiriladi. Shu tufayli chegaraga yetganda ham ifodani
  /// son bilan tugatish mumkin bo'ladi.
  bool _hasRoomFor(int count, {bool dangling = false}) =>
      _tokens.length + count <= (dangling ? maxTokens - 1 : maxTokens);

  void _replaceLast(Token token) => _tokens[_tokens.length - 1] = token;

  /// Har bir tugma bosilishi boshida chaqiriladi: xatoni o'chiradi va
  /// "=" dan keyingi holatni hal qiladi.
  ///
  /// [startsNewExpression] rost bo'lsa (raqam, nuqta, qavs), eski natija
  /// o'chib, yangi ifoda boshlanadi. Aks holda (amal, foiz) hisob eski
  /// natija bilan davom etadi.
  void _beginInput({required bool startsNewExpression}) {
    _error = null;
    if (!_justEvaluated) return;
    _justEvaluated = false;
    if (startsNewExpression) _tokens.clear();
  }

  /// "5." → "5": amal qo'yishdan oldin ortiqcha nuqta olib tashlanadi.
  void _trimTrailingDot() {
    final last = _last;
    if (last is NumberToken && last.text.endsWith('.')) {
      _replaceLast(NumberToken(last.text.substring(0, last.text.length - 1)));
    }
  }

  void _inputMinus() {
    final last = _last;
    final unaryPosition =
        last == null ||
        _isSym(last, Sym.leftParen) ||
        _isSym(last, Sym.times) ||
        _isSym(last, Sym.divide);
    if (unaryPosition) {
      // Manfiy son: "−5", "(−5", "3 × −5".
      if (_hasRoomFor(1, dangling: true)) _tokens.add(_minus);
      return;
    }
    if (_isSym(last, Sym.plus)) {
      _replaceLast(_minus); // "5 +" → "5 −"
      return;
    }
    if (_isSym(last, Sym.minus)) return; // minus allaqachon turibdi
    if (!_hasRoomFor(1, dangling: true)) return;
    _trimTrailingDot();
    _tokens.add(_minus);
  }

  void _inputBinaryOperator(Sym op) {
    // Oxirida turgan amallar (masalan "×" yoki "× −") yangisiga almashadi.
    var start = _tokens.length;
    while (start > 0 && _isOperatorToken(_tokens[start - 1])) {
      start--;
    }
    final hasOperandBefore = start > 0 && _isOperandEnd(_tokens[start - 1]);
    // Ifoda boshida yoki "(" dan keyin "+", "×", "÷" qo'yib bo'lmaydi.
    if (!hasOperandBefore) return;
    final replacing = start < _tokens.length;
    if (!replacing && !_hasRoomFor(1, dangling: true)) return;
    _tokens.removeRange(start, _tokens.length);
    _trimTrailingDot();
    _tokens.add(SymbolToken(op));
  }

  static bool _isOperator(Sym sym) =>
      sym == Sym.plus ||
      sym == Sym.minus ||
      sym == Sym.times ||
      sym == Sym.divide;

  static bool _isOperatorToken(Token token) =>
      token is SymbolToken && _isOperator(token.sym);

  static bool _isSym(Token? token, Sym sym) =>
      token is SymbolToken && token.sym == sym;

  /// Bo'lak "operand oxiri"mi: son, natija, ")" yoki "%".
  static bool _isOperandEnd(Token? token) =>
      token is NumberToken ||
      token is ValueToken ||
      _isSym(token, Sym.rightParen) ||
      _isSym(token, Sym.percent);

  /// Bo'lak "osilib qolgan"mi: amal belgisi yoki "(" — ulardan keyin
  /// albatta yana nimadir kelishi kerak.
  static bool _isDangling(Token token) =>
      _isOperatorToken(token) || _isSym(token, Sym.leftParen);

  static int _digitCount(String text) =>
      text.contains('.') ? text.length - 1 : text.length;

  static int _countOpenParens(List<Token> tokens) {
    var open = 0;
    for (final token in tokens) {
      if (_isSym(token, Sym.leftParen)) open++;
      if (_isSym(token, Sym.rightParen)) open--;
    }
    return open;
  }

  /// Hisoblashga tayyor nusxa qaytaradi: yopilmagan qavslarni yopadi.
  ///
  /// [dropDangling] rost bo'lsa, oxiridagi tugallanmagan qism ("5 + 3 ×"
  /// dagi "×" kabi) tashlab yuboriladi — bu oldindan ko'rsatiladigan
  /// natija uchun kerak.
  static List<Token> _completed(
    List<Token> source, {
    required bool dropDangling,
  }) {
    final tokens = List<Token>.of(source);
    if (dropDangling) {
      while (tokens.isNotEmpty && _isDangling(tokens.last)) {
        tokens.removeLast();
      }
    }
    final open = _countOpenParens(tokens);
    for (var i = 0; i < open; i++) {
      tokens.add(_rightParen);
    }
    return tokens;
  }

  /// Ifodada haqiqiy amal bormi (ikki son orasidagi amal yoki foiz).
  /// Yolg'iz son ("5" yoki "−5") uchun natijani ko'rsatish shart emas.
  static bool _hasOperation(List<Token> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (_isSym(token, Sym.percent)) return true;
      if (i > 0 && _isOperatorToken(token) && _isOperandEnd(tokens[i - 1])) {
        return true;
      }
    }
    return false;
  }

  /// Bo'laklarni ekranga chiqariladigan satrga aylantiradi.
  static String _format(List<Token> tokens) {
    final buffer = StringBuffer();
    Token? previous;
    for (final token in tokens) {
      switch (token) {
        case NumberToken():
          buffer.write(formatNumberText(token.text));
        case ValueToken():
          buffer.write(formatRational(token.value));
        case SymbolToken(sym: Sym.leftParen):
          buffer.write('(');
        case SymbolToken(sym: Sym.rightParen):
          buffer.write(')');
        case SymbolToken(sym: Sym.percent):
          buffer.write('%');
        case SymbolToken(:final sym):
          // Manfiylik belgisi songa yopishib turadi: "−5", "3 × −5".
          final unary = sym == Sym.minus && !_isOperandEnd(previous);
          buffer.write(unary ? '−' : ' ${_operatorChar(sym)} ');
      }
      previous = token;
    }
    return buffer.toString().trimRight();
  }

  static String _operatorChar(Sym sym) => switch (sym) {
    Sym.plus => '+',
    Sym.minus => '−',
    Sym.times => '×',
    Sym.divide => '÷',
    _ => throw ArgumentError.value(sym, 'sym', 'amal belgisi emas'),
  };
}

/// Ifodani hisoblovchi tahlilchi (rekursiv tushish usuli).
///
/// Grammatika:
/// ```
/// ifoda     := qo'shiluvchi (('+' | '−') qo'shiluvchi)*
/// qo'shiluvchi := ko'paytuvchi (('×' | '÷') ko'paytuvchi)*
/// ko'paytuvchi := '−' ko'paytuvchi | birlamchi '%'*
/// birlamchi := son | natija | '(' ifoda ')'
/// ```
///
/// Foiz qoidasi (oddiy kalkulyatorlardagidek):
/// * `200 + 10%` = 220 va `200 − 10%` = 180 — foiz chap tomondagi sondan
///   olinadi;
/// * boshqa hollarda `x%` = x ÷ 100: `200 × 10%` = 20, `50%` = 0.5.
class _Parser {
  _Parser(this._tokens);

  final List<Token> _tokens;
  int _position = 0;

  Rational parse() {
    final value = _expression();
    if (_position != _tokens.length) {
      throw const FormatException('Ortiqcha belgi');
    }
    return value;
  }

  Token? get _peek => _position < _tokens.length ? _tokens[_position] : null;

  bool _peekIs(Sym sym) {
    final token = _peek;
    return token is SymbolToken && token.sym == sym;
  }

  Rational _expression() {
    var result = _term().value;
    while (_peekIs(Sym.plus) || _peekIs(Sym.minus)) {
      final subtract = _peekIs(Sym.minus);
      _position++;
      final right = _term();
      // "200 + 10%": o'ng tomon yolg'iz foiz bo'lsa, u chap tomondan olinadi.
      final amount = right.isPercent ? result * right.value : right.value;
      result = subtract ? result - amount : result + amount;
    }
    return result;
  }

  _Operand _term() {
    final first = _factor();
    var value = first.value;
    var isPercent = first.isPercent;
    while (_peekIs(Sym.times) || _peekIs(Sym.divide)) {
      final divide = _peekIs(Sym.divide);
      _position++;
      final right = _factor().value;
      value = divide ? value / right : value * right;
      isPercent = false;
    }
    return _Operand(value, isPercent: isPercent);
  }

  _Operand _factor() {
    if (_peekIs(Sym.minus)) {
      _position++;
      final inner = _factor();
      return _Operand(-inner.value, isPercent: inner.isPercent);
    }
    var value = _primary();
    var isPercent = false;
    while (_peekIs(Sym.percent)) {
      _position++;
      value = value / Rational.hundred;
      isPercent = true;
    }
    return _Operand(value, isPercent: isPercent);
  }

  Rational _primary() {
    final token = _peek;
    _position++;
    switch (token) {
      case NumberToken():
        return Rational.parse(token.text);
      case ValueToken():
        return token.value;
      case SymbolToken(sym: Sym.leftParen):
        final value = _expression();
        if (!_peekIs(Sym.rightParen)) {
          throw const FormatException('Qavs yopilmagan');
        }
        _position++;
        return value;
      default:
        throw const FormatException('Son kutilgan edi');
    }
  }
}

/// Hisoblangan qiymat va u "yolg'iz foiz" (masalan `10%`) ekanligi belgisi.
class _Operand {
  const _Operand(this.value, {required this.isPercent});

  final Rational value;
  final bool isPercent;
}
