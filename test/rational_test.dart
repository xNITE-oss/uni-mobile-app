import 'package:flutter_test/flutter_test.dart';
import 'package:uni_mobile_app/logic/rational.dart';

Rational r(int numerator, [int denominator = 1]) =>
    Rational(BigInt.from(numerator), BigInt.from(denominator));

void main() {
  group('Rational: yaratish va qisqartirish', () {
    test('kasr qisqartiriladi', () {
      expect(r(2, 4), r(1, 2));
      expect(r(10, 5), r(2));
      expect(r(0, 7), Rational.zero);
    });

    test('maxraj har doim musbat', () {
      final value = r(1, -2);
      expect(value.numerator, BigInt.from(-1));
      expect(value.denominator, BigInt.from(2));
    });

    test('maxraj nol bo\'lsa xato', () {
      expect(() => r(1, 0), throwsA(isA<DivisionByZeroException>()));
    });
  });

  group('Rational.parse', () {
    test('butun va o\'nli sonlar', () {
      expect(Rational.parse('12'), r(12));
      expect(Rational.parse('3.14'), r(157, 50));
      expect(Rational.parse('0.1'), r(1, 10));
      expect(Rational.parse('007'), r(7));
    });

    test('nuqta bilan tugagan yoki boshlangan son', () {
      expect(Rational.parse('5.'), r(5));
      expect(Rational.parse('.5'), r(1, 2));
    });

    test('noto\'g\'ri matn xato beradi', () {
      expect(() => Rational.parse(''), throwsFormatException);
      expect(() => Rational.parse('.'), throwsFormatException);
      expect(() => Rational.parse('abc'), throwsFormatException);
      expect(() => Rational.parse('1.2.3'), throwsFormatException);
      expect(() => Rational.parse('-5'), throwsFormatException);
    });
  });

  group('Rational: amallar', () {
    test('qo\'shish, ayirish, ko\'paytirish, bo\'lish', () {
      expect(r(1, 2) + r(1, 3), r(5, 6));
      expect(r(1, 2) - r(1, 3), r(1, 6));
      expect(r(2, 3) * r(3, 4), r(1, 2));
      expect(r(1, 2) / r(1, 4), r(2));
      expect(-r(3, 4), r(-3, 4));
    });

    test('0.1 + 0.2 aynan 0.3 ga teng', () {
      expect(
        Rational.parse('0.1') + Rational.parse('0.2'),
        Rational.parse('0.3'),
      );
    });

    test('1 / 3 * 3 aynan 1 ga teng', () {
      expect(r(1) / r(3) * r(3), Rational.one);
    });

    test('nolga bo\'lish xato beradi', () {
      expect(
        () => r(5) / Rational.zero,
        throwsA(isA<DivisionByZeroException>()),
      );
    });

    test('solishtirish', () {
      expect(r(1, 3).compareTo(r(1, 2)), lessThan(0));
      expect(r(1, 2).compareTo(r(2, 4)), 0);
      expect(r(-1).compareTo(r(-2)), greaterThan(0));
    });

    test('xossalar', () {
      expect(Rational.zero.isZero, isTrue);
      expect(r(-1, 2).isNegative, isTrue);
      expect(r(4, 2).isInteger, isTrue);
      expect(r(1, 2).isInteger, isFalse);
    });
  });

  group('Rational.toDecimalString', () {
    test('butun sonlar', () {
      expect(Rational.zero.toDecimalString(), '0');
      expect(r(7).toDecimalString(), '7');
      expect(r(100).toDecimalString(), '100');
      expect(r(-42).toDecimalString(), '-42');
      expect(r(123456789012345).toDecimalString(), '123456789012345');
    });

    test('chekli o\'nli kasrlar aniq chiqadi', () {
      expect(r(1, 2).toDecimalString(), '0.5');
      expect(r(1, 8).toDecimalString(), '0.125');
      expect(r(12345, 10).toDecimalString(), '1234.5');
      expect(r(-5, 2).toDecimalString(), '-2.5');
      expect(r(1, 10).toDecimalString(), '0.1');
    });

    test('cheksiz kasrlar 15 ta ma\'noli raqamgacha yaxlitlanadi', () {
      expect(r(1, 3).toDecimalString(), '0.333333333333333');
      expect(r(2, 3).toDecimalString(), '0.666666666666667');
      expect(r(-1, 3).toDecimalString(), '-0.333333333333333');
      expect(r(1, 7).toDecimalString(), '0.142857142857143');
      expect(r(100, 3).toDecimalString(), '33.3333333333333');
      expect(r(22, 7).toDecimalString(), '3.14285714285714');
    });

    test('yaxlitlashda xona oshishi (9.99… → 10)', () {
      // 0.99999999999999995 → 1
      final almostOne = Rational(
        BigInt.parse('99999999999999995'),
        BigInt.parse('100000000000000000'),
      );
      expect(almostOne.toDecimalString(), '1');
      // 999999999999999.5 → 1E15
      final big = Rational(BigInt.parse('9999999999999995'), BigInt.from(10));
      expect(big.toDecimalString(), '1E15');
    });

    test('ma\'noli raqamlar sonini berish mumkin', () {
      expect(r(2, 3).toDecimalString(significantDigits: 3), '0.667');
      expect(r(1, 3).toDecimalString(significantDigits: 1), '0.3');
      expect(r(12345).toDecimalString(significantDigits: 2), '12000');
      expect(r(995, 100).toDecimalString(significantDigits: 2), '10');
    });

    test('juda katta sonlar ilmiy ko\'rinishda', () {
      expect(Rational(BigInt.from(10).pow(15)).toDecimalString(), '1E15');
      expect(
        Rational(BigInt.from(10).pow(14)).toDecimalString(),
        '100000000000000',
      );
      expect(
        Rational(BigInt.parse('1234567890123450')).toDecimalString(),
        '1.23456789012345E15',
      );
      expect(
        Rational(BigInt.from(15) * BigInt.from(10).pow(19)).toDecimalString(),
        '1.5E20',
      );
      expect(Rational(-BigInt.from(10).pow(30)).toDecimalString(), '-1E30');
    });

    test('juda kichik sonlar ilmiy ko\'rinishda', () {
      expect(r(1, 1000000).toDecimalString(), '0.000001');
      expect(r(1, 10000000).toDecimalString(), '1E-7');
      expect(r(-25, 1000000000).toDecimalString(), '-2.5E-8');
      expect(r(123, 100000000).toDecimalString(), '0.00000123');
    });
  });
}
