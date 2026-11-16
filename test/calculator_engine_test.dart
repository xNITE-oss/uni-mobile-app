import 'package:flutter_test/flutter_test.dart';
import 'package:uni_mobile_app/logic/calculator_engine.dart';

/// Tugmalar ketma-ketligini bosadi. Belgilar:
/// `0`–`9` raqamlar, `.` nuqta, `+ - * /` amallar, `%` foiz,
/// `p` qavs tugmasi, `=` teng, `C` tozalash, `<` o'chirish.
void press(CalculatorEngine engine, String keys) {
  for (final key in keys.split('')) {
    switch (key) {
      case '+':
        engine.inputOperator(Sym.plus);
      case '-':
        engine.inputOperator(Sym.minus);
      case '*':
        engine.inputOperator(Sym.times);
      case '/':
        engine.inputOperator(Sym.divide);
      case '.':
        engine.inputDot();
      case '%':
        engine.inputPercent();
      case 'p':
        engine.inputParenthesis();
      case '=':
        engine.evaluate();
      case 'C':
        engine.clear();
      case '<':
        engine.backspace();
      default:
        engine.inputDigit(int.parse(key));
    }
  }
}

/// Uzilmaydigan bo'sh joylarni oddiy bo'sh joyga almashtiradi.
String plain(String text) => text.replaceAll(groupSeparator, ' ');

/// Tugmalarni bosib, ekrandagi asosiy satrni qaytaradi.
String display(String keys) {
  final engine = CalculatorEngine();
  press(engine, keys);
  return plain(engine.display);
}

/// Tugmalarni bosib, oldindan ko'rsatiladigan natijani qaytaradi.
String preview(String keys) {
  final engine = CalculatorEngine();
  press(engine, keys);
  return plain(engine.preview);
}

CalculatorEngine engineAfter(String keys) {
  final engine = CalculatorEngine();
  press(engine, keys);
  return engine;
}

void main() {
  group('Oddiy amallar', () {
    test('qo\'shish', () => expect(display('2+3='), '5'));
    test('ayirish', () => expect(display('9-4='), '5'));
    test('ko\'paytirish', () => expect(display('6*7='), '42'));
    test('bo\'lish', () => expect(display('8/2='), '4'));
    test('kasr natija', () => expect(display('7/2='), '3.5'));
    test('manfiy natija', () => expect(display('2-5='), '−3'));
    test('ko\'p xonali sonlar', () => expect(display('125+375='), '500'));
    test('nol bilan amallar', () {
      expect(display('0+0='), '0');
      expect(display('5*0='), '0');
      expect(display('0/5='), '0');
      expect(display('5-5='), '0');
    });
  });

  group('Amallar tartibi', () {
    test('ko\'paytirish qo\'shishdan oldin', () {
      expect(display('2+3*4='), '14');
      expect(display('2*3+4='), '10');
    });
    test('bo\'lish ayirishdan oldin', () => expect(display('10-6/2='), '7'));
    test('aralash ifoda', () => expect(display('2+3*4-5/5='), '13'));
    test('bir xil darajali amallar chapdan o\'ngga', () {
      expect(display('100/10/2='), '5');
      expect(display('10-3-2='), '5');
      expect(display('2*6/4='), '3');
    });
  });

  group('Qavslar', () {
    test('qavs tartibni o\'zgartiradi', () {
      expect(display('p2+3p*4='), '20');
    });
    test('sondan keyin qavs — ko\'paytirish', () {
      final engine = engineAfter('2p3+4p');
      expect(plain(engine.display), '2 × (3 + 4)');
      press(engine, '=');
      expect(plain(engine.display), '14');
    });
    test('ikki qavs yonma-yon — ko\'paytirish', () {
      final engine = engineAfter('p2+3pp4+5p');
      expect(plain(engine.display), '(2 + 3) × (4 + 5)');
      press(engine, '=');
      expect(plain(engine.display), '45');
    });
    test('ichma-ich qavslar', () {
      final engine = engineAfter('pp2+3p*4p-1');
      expect(plain(engine.display), '((2 + 3) × 4) − 1');
      press(engine, '=');
      expect(plain(engine.display), '19');
    });
    test('yopilmagan qavs "=" da avtomatik yopiladi', () {
      final engine = engineAfter('2*p3+4=');
      expect(plain(engine.display), '14');
      expect(plain(engine.lastExpression), '2 × (3 + 4)');
    });
    test('qavsdan keyin son — ko\'paytirish', () {
      expect(display('p5p3'), '(5) × 3');
      expect(display('p2+3p4='), '20');
    });
    test('manfiy ifoda qavs oldida', () => expect(display('-p2+3p='), '−5'));
  });

  group('O\'nli kasrlar (aniqlik)', () {
    test('0.1 + 0.2 = 0.3', () => expect(display('0.1+0.2='), '0.3'));
    test('1.1 × 1.1 = 1.21', () => expect(display('1.1*1.1='), '1.21'));
    test('0.3 − 0.1 = 0.2', () => expect(display('0.3-0.1='), '0.2'));
    test('4.35 × 100 = 435', () => expect(display('4.35*100='), '435'));
    test('1 ÷ 3', () => expect(display('1/3='), '0.333333333333333'));
    test('2 ÷ 3 yaxlitlanadi', () {
      expect(display('2/3='), '0.666666666666667');
    });
    test('1 ÷ 3 × 3 = 1', () => expect(display('1/3=*3='), '1'));
    test('1 ÷ 3 × 3 bitta ifodada', () => expect(display('1/3*3='), '1'));
    test('chekli kasrlar', () {
      expect(display('10/4='), '2.5');
      expect(display('1/8='), '0.125');
    });
    test('nuqtadan boshlangan son', () => expect(display('.5+.5='), '1'));
  });

  group('Foiz', () {
    test('songa foiz qo\'shish', () => expect(display('200+10%='), '220'));
    test('sondan foiz ayirish', () => expect(display('200-10%='), '180'));
    test('sonning foizi', () => expect(display('200*10%='), '20'));
    test('foizga bo\'lish', () => expect(display('200/10%='), '2 000'));
    test('yolg\'iz foiz', () => expect(display('50%='), '0.5'));
    test('foiz yig\'indidan olinadi', () {
      expect(display('100+50+10%='), '165');
    });
    test('ketma-ket foizlar', () => expect(display('100+10%+10%='), '121'));
    test('qavsdan keyin foiz', () {
      expect(display('p5+5p%='), '0.1');
      expect(display('200+p5+5p%='), '220');
    });
    test('foizdan keyin ko\'paytirish', () {
      expect(display('50%*4='), '2');
      expect(display('100+10%*2='), '100.2');
    });
    test('foizdan keyin son — ko\'paytirish', () {
      final engine = engineAfter('50%5');
      expect(plain(engine.display), '50% × 5');
      press(engine, '=');
      expect(plain(engine.display), '2.5');
    });
    test('foiz faqat sondan keyin qo\'yiladi', () {
      expect(display('%'), '0');
      expect(display('5+%'), '5 +');
      expect(display('p%'), '(');
      expect(display('5%%'), '5%');
    });
  });

  group('Nolga bo\'lish', () {
    test('xato ko\'rsatiladi, ifoda saqlanadi', () {
      final engine = engineAfter('5/0=');
      expect(engine.error, CalcError.divisionByZero);
      expect(plain(engine.display), '5 ÷ 0');
      expect(engine.justEvaluated, isFalse);
      expect(engine.history, isEmpty);
    });
    test('0 ÷ 0 ham xato', () {
      expect(engineAfter('0/0=').error, CalcError.divisionByZero);
    });
    test('qavs ichida nol chiqsa', () {
      expect(engineAfter('5/p3-3p=').error, CalcError.divisionByZero);
    });
    test('oldindan natija ko\'rsatilmaydi', () {
      expect(preview('5/0'), '');
    });
    test('keyingi tugma xatoni o\'chiradi', () {
      final engine = engineAfter('5/0=');
      press(engine, '<');
      expect(engine.error, isNull);
      expect(plain(engine.display), '5 ÷');
      press(engine, '2=');
      expect(plain(engine.display), '2.5');
    });
  });

  group('Tugallanmagan ifoda', () {
    test('amal bilan tugasa xato', () {
      final engine = engineAfter('5+=');
      expect(engine.error, CalcError.incomplete);
      expect(plain(engine.display), '5 +');
    });
    test('ochiq qavs bilan tugasa xato', () {
      expect(engineAfter('p=').error, CalcError.incomplete);
      expect(engineAfter('5*p=').error, CalcError.incomplete);
    });
    test('yolg\'iz minus xato', () {
      expect(engineAfter('-=').error, CalcError.incomplete);
    });
    test('bo\'sh ekranda "=" hech narsa qilmaydi', () {
      final engine = engineAfter('=');
      expect(engine.error, isNull);
      expect(engine.display, '0');
      expect(engine.justEvaluated, isFalse);
    });
    test('xatodan keyin ifodani davom ettirish mumkin', () {
      final engine = engineAfter('5+=');
      press(engine, '3=');
      expect(engine.error, isNull);
      expect(plain(engine.display), '8');
    });
  });

  group('Raqam kiritish qoidalari', () {
    test('boshidagi ortiqcha nollar olinadi', () {
      expect(display('007'), '7');
      expect(display('000'), '0');
      expect(display('00.5'), '0.5');
      expect(display('5+007'), '5 + 7');
    });
    test('bitta sonda faqat bitta nuqta', () {
      expect(display('1..2'), '1.2');
      expect(display('1.2.3'), '1.23');
    });
    test('nuqta bo\'sh joyda "0." bo\'ladi', () {
      expect(display('.'), '0.');
      expect(display('5+.'), '5 + 0.');
      expect(display('p.5'), '(0.5');
    });
    test('kasr qismidagi nollar saqlanadi', () {
      expect(display('1.50'), '1.50');
      expect(display('0.00'), '0.00');
      expect(display('1.50+1='), '2.5');
    });
    test('bitta sonda 15 tadan ortiq raqam bo\'lmaydi', () {
      expect(display('1234567890123456789'), '123 456 789 012 345');
      expect(display('1.234567890123456789'), '1.23456789012345');
      expect(display('123456789012345.'), '123 456 789 012 345');
    });
    test('ifoda uzunligi cheklangan', () {
      // 29 marta "1+" — 58 ta bo'lak. Yana bitta son sig'adi, lekin
      // undan keyingi amal belgisi endi qabul qilinmaydi.
      final engine = engineAfter('1+' * 29);
      press(engine, '1+');
      expect(plain(engine.display), endsWith('+ 1'));
      press(engine, '=');
      expect(engine.error, isNull);
      expect(plain(engine.display), '30');
    });
    test('chegaraga yetganda ham ifodani tugatish mumkin', () {
      for (final keys in ['1+' * 100, 'p' * 100, '1*-' * 100, '5p' * 100]) {
        final engine = engineAfter(keys);
        press(engine, '2=');
        expect(engine.error, isNull, reason: keys);
        expect(engine.justEvaluated, isTrue, reason: keys);
      }
    });
  });

  group('Amal belgilarini kiritish qoidalari', () {
    test('ketma-ket amal — oxirgisi qoladi', () {
      expect(display('5+*'), '5 ×');
      expect(display('5+*3='), '15');
      expect(display('5*/+-'), '5 −');
    });
    test('ko\'paytirish va bo\'lishdan keyin manfiy son', () {
      expect(display('5*-3'), '5 × −3');
      expect(display('5*-3='), '−15');
      expect(display('8/-2='), '−4');
    });
    test('"× −" dan keyin amal ikkalasini almashtiradi', () {
      expect(display('5*-+'), '5 +');
      expect(display('5*-+3='), '8');
    });
    test('plyusdan keyin minus uni almashtiradi', () {
      expect(display('5+-'), '5 −');
      expect(display('5+-3='), '2');
    });
    test('ikki marta minus bitta bo\'lib qoladi', () {
      expect(display('5--'), '5 −');
      expect(display('5--3='), '2');
      expect(display('--5'), '−5');
      expect(display('5*--3='), '−15');
    });
    test('boshida minus — manfiy son', () {
      expect(display('-5'), '−5');
      expect(display('-5+3='), '−2');
      expect(display('p-5p*2='), '−10');
    });
    test('boshida va qavsdan keyin + × ÷ qo\'yilmaydi', () {
      expect(display('+5'), '5');
      expect(display('*5'), '5');
      expect(display('/5'), '5');
      expect(display('p+'), '(');
      expect(display('p*2'), '(2');
      expect(display('-+'), '−');
      expect(display('p-*'), '(−');
    });
    test('amaldan oldin ortiqcha nuqta olinadi', () {
      expect(display('5.+3'), '5 + 3');
      expect(display('5.-'), '5 −');
      expect(display('5.%'), '5%');
      expect(display('p5.p'), '(5)');
      expect(display('5.='), '5');
    });
    test('qavs tugmasi vaziyatga qarab ochadi yoki yopadi', () {
      expect(display('p'), '(');
      expect(display('pp'), '((');
      expect(display('5p'), '5 × (');
      expect(display('5+p'), '5 + (');
      expect(display('p5p'), '(5)');
      expect(display('p5pp'), '(5) × (');
      expect(display('p5%p'), '(5%)');
    });
  });

  group('O\'chirish va tozalash', () {
    test('oxirgi raqam o\'chadi', () {
      expect(display('123<'), '12');
      expect(display('1<'), '0');
      expect(display('0.<'), '0');
      expect(display('1.5<'), '1.');
    });
    test('amal va qavs o\'chadi', () {
      expect(display('12+<'), '12');
      expect(display('12+3<'), '12 +');
      expect(display('5*-<'), '5 ×');
      expect(display('p<'), '0');
      expect(display('p5p<'), '(5');
      expect(display('5%<'), '5');
    });
    test('bo\'sh ekranda o\'chirish xato bermaydi', () {
      expect(display('<<<'), '0');
    });
    test('natijadan keyin o\'chirish hammasini tozalaydi', () {
      final engine = engineAfter('2+3=<');
      expect(engine.display, '0');
      expect(engine.justEvaluated, isFalse);
      expect(engine.lastExpression, '');
    });
    test('AC hammasini tozalaydi, tarix qoladi', () {
      final engine = engineAfter('2+3=12+3C');
      expect(engine.display, '0');
      expect(engine.expression, '');
      expect(engine.preview, '');
      expect(engine.error, isNull);
      expect(engine.history, hasLength(1));
    });
    test('o\'chirgandan keyin davom ettirish', () {
      expect(display('12+35<4='), '46');
    });
  });

  group('"=" dan keyingi holat', () {
    test('natija va oldingi ifoda ko\'rinadi', () {
      final engine = engineAfter('2+3=');
      expect(engine.display, '5');
      expect(plain(engine.lastExpression), '2 + 3');
      expect(engine.justEvaluated, isTrue);
      expect(engine.preview, '');
    });
    test('raqam bosilsa yangi ifoda boshlanadi', () {
      final engine = engineAfter('2+3=4');
      expect(engine.display, '4');
      expect(engine.lastExpression, '');
    });
    test('amal bosilsa natija bilan davom etadi', () {
      expect(display('2+3=+4'), '5 + 4');
      expect(display('2+3=+4='), '9');
      expect(display('2+3=*2='), '10');
      expect(display('2-5=*2='), '−6');
      expect(display('2-5=-1='), '−4');
    });
    test('nuqta bosilsa yangi son boshlanadi', () {
      expect(display('2+3=.5'), '0.5');
    });
    test('foiz natijaga qo\'llanadi', () {
      expect(display('2+3=%'), '5%');
      expect(display('2+3=%='), '0.05');
    });
    test('qavs bosilsa yangi ifoda boshlanadi', () {
      expect(display('2+3=p'), '(');
    });
    test('ikkinchi "=" hech narsani o\'zgartirmaydi', () {
      final engine = engineAfter('2+3===');
      expect(engine.display, '5');
      expect(engine.history, hasLength(1));
    });
    test('yolg\'iz son tarixga yozilmaydi', () {
      final engine = engineAfter('5=');
      expect(engine.display, '5');
      expect(engine.justEvaluated, isTrue);
      expect(engine.lastExpression, '');
      expect(engine.history, isEmpty);
    });
    test('zanjir hisob aniqlikni yo\'qotmaydi', () {
      // 10 ÷ 3 = 3.333…, × 3 = 10 (9.999… emas)
      expect(display('10/3=*3='), '10');
      // 2 ÷ 7 × 7 − 2 = 0
      expect(display('2/7=*7=-2='), '0');
    });
  });

  group('Sonlarni ko\'rsatish', () {
    test('minglik xonalar ajratiladi', () {
      expect(display('1234567'), '1 234 567');
      expect(display('1000*1000='), '1 000 000');
      expect(display('999+1='), '1 000');
      expect(display('123'), '123');
    });
    test('kasr qismi guruhlanmaydi', () {
      expect(display('1234.5678'), '1 234.5678');
      expect(display('1234567.5+0='), '1 234 567.5');
    });
    test('guruhlash uzilmaydigan bo\'sh joy bilan', () {
      expect(engineAfter('1000').display, '1${groupSeparator}000');
    });
    test('ifoda yozilishi', () {
      expect(display('12+3*p4-1p'), '12 + 3 × (4 − 1)');
      expect(display('1000/-2.5'), '1 000 ÷ −2.5');
    });
    test('15 xonali butun sonlar aniq chiqadi', () {
      expect(display('123456789012345+1='), '123 456 789 012 346');
      expect(display('999999999999999-1='), '999 999 999 999 998');
    });
    test('juda katta sonlar ilmiy ko\'rinishda', () {
      expect(display('999999999999999+1='), '1E15');
      expect(
        display('999999999999999*999999999999999='),
        '9.99999999999998E29',
      );
    });
    test('juda kichik sonlar ilmiy ko\'rinishda', () {
      expect(display('1/1000000='), '0.000001');
      expect(display('1/10000000='), '1E−7');
      expect(display('0-1/40000000='), '−2.5E−8');
    });
    test('ilmiy ko\'rinishdagi natija bilan davom ettirish', () {
      expect(display('999999999999999+1=/1000='), '1 000 000 000 000');
    });
  });

  group('Oldindan ko\'rsatiladigan natija', () {
    test('amal bo\'lsa ko\'rinadi', () {
      expect(preview('2+3'), '5');
      expect(preview('2+3*4'), '14');
      expect(preview('1000*3'), '3 000');
    });
    test('yolg\'iz son uchun ko\'rinmaydi', () {
      expect(preview(''), '');
      expect(preview('2'), '');
      expect(preview('-2'), '');
      expect(preview('2+'), '');
      expect(preview('p2'), '');
    });
    test('tugallanmagan qism hisobga olinmaydi', () {
      expect(preview('2+3*'), '5');
      expect(preview('2+3*p'), '5');
      expect(preview('2+3*-'), '5');
      expect(preview('p2+3'), '5');
      expect(preview('2*p3+4'), '14');
    });
    test('foiz uchun ko\'rinadi', () {
      expect(preview('50%'), '0.5');
      expect(preview('200+10%'), '220');
    });
    test('"=" dan keyin ko\'rinmaydi', () {
      expect(preview('2+3='), '');
    });
  });

  group('Tarix', () {
    test('hisoblar yangi birinchi bo\'lib saqlanadi', () {
      final engine = engineAfter('2+3=4*5=');
      expect(engine.history, hasLength(2));
      expect(plain(engine.history[0].expression), '4 × 5');
      expect(engine.history[0].result, '20');
      expect(plain(engine.history[1].expression), '2 + 3');
      expect(engine.history[1].result, '5');
    });
    test('xato hisob tarixga yozilmaydi', () {
      expect(engineAfter('5/0=').history, isEmpty);
      expect(engineAfter('5+=').history, isEmpty);
    });
    test('tarixdagi natijani qayta ishlatish', () {
      final engine = engineAfter('2+3=4*5=');
      engine.useHistory(engine.history[1]);
      expect(engine.display, '5');
      expect(plain(engine.lastExpression), '2 + 3');
      expect(engine.justEvaluated, isTrue);
      press(engine, '+1=');
      expect(engine.display, '6');
    });
    test('tarixdagi natija aniq qiymatini saqlaydi', () {
      final engine = engineAfter('1/3=C');
      engine.useHistory(engine.history.single);
      press(engine, '*3=');
      expect(engine.display, '1');
    });
    test('tarixni tozalash', () {
      final engine = engineAfter('2+3=4*5=');
      engine.clearHistory();
      expect(engine.history, isEmpty);
    });
    test('tarix uzunligi cheklangan', () {
      final engine = CalculatorEngine();
      for (var i = 0; i < CalculatorEngine.maxHistory + 5; i++) {
        press(engine, '$i+1=');
      }
      expect(engine.history, hasLength(CalculatorEngine.maxHistory));
      // Eng yangisi birinchi turadi.
      expect(engine.history.first.result, '${CalculatorEngine.maxHistory + 5}');
    });
    test('tarix ro\'yxatini tashqaridan o\'zgartirib bo\'lmaydi', () {
      final engine = engineAfter('2+3=');
      expect(() => engine.history.clear(), throwsUnsupportedError);
    });
  });

  group('formatNumberText', () {
    test('ishora, guruhlash va daraja', () {
      expect(plain(formatNumberText('-1234567.5')), '−1 234 567.5');
      expect(formatNumberText('1.5E-8'), '1.5E−8');
      expect(formatNumberText('-1E30'), '−1E30');
      expect(formatNumberText('0.'), '0.');
      expect(formatNumberText('12'), '12');
    });
  });
}
