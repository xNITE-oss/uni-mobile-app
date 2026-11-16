/// Aniq kasr sonlar (surat / maxraj) bilan ishlash.
///
/// Kalkulyator `double` o'rniga shu sinfdan foydalanadi. Shuning uchun
/// 0.1 + 0.2 = 0.3 yoki 1 ÷ 3 × 3 = 1 kabi natijalar yaxlitlash xatosisiz,
/// aniq chiqadi.
library;

/// Nolga bo'lishga urinilganda tashlanadigan xato.
class DivisionByZeroException implements Exception {
  const DivisionByZeroException();

  @override
  String toString() => 'DivisionByZeroException: nolga bo\'lib bo\'lmaydi';
}

/// Qisqartirilgan oddiy kasr: [numerator] / [denominator].
///
/// Maxraj har doim musbat, surat va maxraj o'zaro tub bo'ladi.
class Rational implements Comparable<Rational> {
  const Rational._(this.numerator, this.denominator);

  /// Kasrni yaratadi va uni qisqartiradi.
  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var n = numerator;
    var d = denominator ?? BigInt.one;
    if (d == BigInt.zero) throw const DivisionByZeroException();
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  /// Butun sondan kasr yaratadi.
  factory Rational.fromInt(int value) =>
      Rational._(BigInt.from(value), BigInt.one);

  /// O'nli yozuvdagi matnni o'qiydi: "12", "3.14", "5.", ".5".
  factory Rational.parse(String text) {
    final match = _decimalPattern.firstMatch(text);
    final intPart = match?.group(1) ?? '';
    final fracPart = match?.group(2) ?? '';
    if (match == null || (intPart.isEmpty && fracPart.isEmpty)) {
      throw FormatException('Noto\'g\'ri son', text);
    }
    final digits = '${intPart.isEmpty ? '0' : intPart}$fracPart';
    return Rational(BigInt.parse(digits), _ten.pow(fracPart.length));
  }

  final BigInt numerator;
  final BigInt denominator;

  static final Rational zero = Rational._(BigInt.zero, BigInt.one);
  static final Rational one = Rational._(BigInt.one, BigInt.one);
  static final Rational hundred = Rational.fromInt(100);

  static final BigInt _ten = BigInt.from(10);
  static final RegExp _decimalPattern = RegExp(r'^(\d*)(?:\.(\d*))?$');
  static final RegExp _trailingZeros = RegExp(r'0+$');

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;
  bool get isInteger => denominator == BigInt.one;

  Rational operator +(Rational other) => Rational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator -(Rational other) => Rational(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator *(Rational other) =>
      Rational(numerator * other.numerator, denominator * other.denominator);

  Rational operator /(Rational other) {
    if (other.isZero) throw const DivisionByZeroException();
    return Rational(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  Rational operator -() => Rational._(-numerator, denominator);

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  /// Sonni o'nli yozuvga o'tkazadi.
  ///
  /// Natija ko'pi bilan [significantDigits] ta ma'noli raqamgacha
  /// yaxlitlanadi (5 va undan katta bo'lsa yuqoriga). Juda katta yoki juda
  /// kichik sonlar ilmiy ko'rinishda yoziladi: `1.5E20`, `2.5E-8`.
  String toDecimalString({int significantDigits = 15}) {
    assert(significantDigits > 0);
    if (isZero) return '0';

    final a = numerator.abs();
    final d = denominator;

    // e = floor(log10(a / d)) — sonning o'nli darajasi.
    var e = a.toString().length - d.toString().length;
    final atLeastPower = e >= 0
        ? a.compareTo(d * _ten.pow(e)) >= 0
        : (a * _ten.pow(-e)).compareTo(d) >= 0;
    if (!atLeastPower) e -= 1;

    // q = a / d * 10^(N - 1 - e), eng yaqin butun songacha yaxlitlangan.
    final shift = significantDigits - 1 - e;
    final scaledNum = shift >= 0 ? a * _ten.pow(shift) : a;
    final scaledDen = shift >= 0 ? d : d * _ten.pow(-shift);
    var q = scaledNum ~/ scaledDen;
    final remainder = scaledNum % scaledDen;
    if (remainder * BigInt.two >= scaledDen) q += BigInt.one;
    if (q == _ten.pow(significantDigits)) {
      // Yaxlitlashda 9.99… → 10.0 bo'lib ketdi.
      q = q ~/ _ten;
      e += 1;
    }

    // Ma'noli raqamlar (oxiridagi nollarsiz); qiymat = d1.d2d3… × 10^e.
    var digits = q.toString().replaceFirst(_trailingZeros, '');
    if (digits.isEmpty) digits = '0';

    String body;
    if (e >= _minPlainExponent && e <= _maxPlainExponent) {
      if (e >= 0) {
        final intLength = e + 1;
        body = digits.length <= intLength
            ? digits.padRight(intLength, '0')
            : '${digits.substring(0, intLength)}.${digits.substring(intLength)}';
      } else {
        body = '0.${'0' * (-e - 1)}$digits';
      }
    } else {
      final mantissa = digits.length == 1
          ? digits
          : '${digits[0]}.${digits.substring(1)}';
      body = '${mantissa}E$e';
    }
    return isNegative ? '-$body' : body;
  }

  /// Oddiy (ilmiy bo'lmagan) yozuv chegaralari: 0.000001 dan
  /// 999 999 999 999 999 gacha.
  static const int _minPlainExponent = -6;
  static const int _maxPlainExponent = 14;

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}
