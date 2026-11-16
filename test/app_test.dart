import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uni_mobile_app/logic/calculator_engine.dart';
import 'package:uni_mobile_app/main.dart';

/// Test ekranini telefon o'lchamiga keltiradi (odatda 360 × 800, tik holat).
void useScreen(WidgetTester tester, [Size size = const Size(360, 800)]) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Login oynasini to'ldirib, "Kirish" tugmasini bosadi.
Future<void> signIn(
  WidgetTester tester, {
  String login = 'admin',
  String password = '12345',
}) async {
  await tester.enterText(find.byKey(const Key('login_field')), login);
  await tester.enterText(find.byKey(const Key('password_field')), password);
  await tapLoginButton(tester);
}

/// "Kirish" tugmasini bosadi. Kichik ekranda tugma pastda qolib ketishi
/// mumkin, shuning uchun avval unga aylantiriladi.
Future<void> tapLoginButton(WidgetTester tester) async {
  final button = find.byKey(const Key('login_button'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

/// Ilovani ochib, kalkulyator oynasigacha boradi.
Future<void> openCalculator(WidgetTester tester) async {
  useScreen(tester);
  await tester.pumpWidget(const KalkulyatorApp());
  await signIn(tester);
}

/// Kalkulyator tugmalarini bosadi. Tugma nomlari bo'sh joy bilan ajratiladi:
/// `'1 2 plus 7 equals'`.
Future<void> tapKeys(WidgetTester tester, String keys) async {
  for (final id in keys.split(' ')) {
    await tester.tap(find.byKey(Key('key_$id')));
    await tester.pump();
  }
}

/// Berilgan kalitli `Text` vidjetidagi matn.
String textOf(WidgetTester tester, String key) {
  final widget = tester.widget<Text>(find.byKey(Key(key)));
  final text = widget.data ?? widget.textSpan!.toPlainText();
  return text.replaceAll(groupSeparator, ' ');
}

const wrongCredentials = "Login yoki parol noto'g'ri";

void main() {
  group('Login oynasi', () {
    testWidgets('ilova login oynasi bilan ochiladi', (tester) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      expect(find.text('Xush kelibsiz'), findsOneWidget);
      expect(find.byKey(const Key('login_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.text('Kirish'), findsOneWidget);
      expect(find.byKey(const Key('key_equals')), findsNothing);
    });

    testWidgets('bo\'sh maydonlar bilan kirib bo\'lmaydi', (tester) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await tapLoginButton(tester);

      expect(find.text('Loginni kiriting'), findsOneWidget);
      expect(find.text('Parolni kiriting'), findsOneWidget);
      expect(find.byKey(const Key('login_error')), findsNothing);
      expect(find.byKey(const Key('key_equals')), findsNothing);
    });

    testWidgets('faqat bo\'sh joydan iborat login qabul qilinmaydi', (
      tester,
    ) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await signIn(tester, login: '   ');

      expect(find.text('Loginni kiriting'), findsOneWidget);
      expect(find.text('Parolni kiriting'), findsNothing);
      expect(find.byKey(const Key('key_equals')), findsNothing);
    });

    testWidgets('noto\'g\'ri parolda xato xabari chiqadi', (tester) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await signIn(tester, password: 'xato');

      expect(find.text(wrongCredentials), findsOneWidget);
      expect(find.byKey(const Key('key_equals')), findsNothing);
    });

    testWidgets('noto\'g\'ri loginda xato xabari chiqadi', (tester) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await signIn(tester, login: 'boshqa');

      expect(find.text(wrongCredentials), findsOneWidget);
      expect(find.byKey(const Key('key_equals')), findsNothing);
    });

    testWidgets('parol katta-kichik harfga va bo\'sh joyga sezgir', (
      tester,
    ) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await signIn(tester, password: '12345 ');

      expect(find.text(wrongCredentials), findsOneWidget);
    });

    testWidgets('tahrirlash boshlanganda xato xabari yo\'qoladi', (
      tester,
    ) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());
      await signIn(tester, password: 'xato');
      expect(find.text(wrongCredentials), findsOneWidget);

      await tester.enterText(find.byKey(const Key('password_field')), '1');
      await tester.pump();

      expect(find.text(wrongCredentials), findsNothing);
    });

    testWidgets('parolni ko\'rsatish va yashirish', (tester) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());
      final passwordInput = find.descendant(
        of: find.byKey(const Key('password_field')),
        matching: find.byType(EditableText),
      );
      bool obscured() => tester.widget<EditableText>(passwordInput).obscureText;

      expect(obscured(), isTrue);

      await tester.tap(find.byKey(const Key('password_visibility_button')));
      await tester.pump();
      expect(obscured(), isFalse);

      await tester.tap(find.byKey(const Key('password_visibility_button')));
      await tester.pump();
      expect(obscured(), isTrue);
    });

    testWidgets('to\'g\'ri login va parol kalkulyatorni ochadi', (
      tester,
    ) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await signIn(tester);

      expect(find.text('Kalkulyator'), findsOneWidget);
      expect(find.text('Foydalanuvchi: admin'), findsOneWidget);
      expect(find.byKey(const Key('key_equals')), findsOneWidget);
      expect(find.byKey(const Key('login_field')), findsNothing);
    });

    testWidgets('login katta harf va bo\'sh joy bilan ham qabul qilinadi', (
      tester,
    ) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await signIn(tester, login: '  Admin ');

      expect(find.text('Foydalanuvchi: Admin'), findsOneWidget);
      expect(find.byKey(const Key('key_equals')), findsOneWidget);
    });

    testWidgets('klaviaturadagi "tayyor" tugmasi ham kiritadi', (tester) async {
      useScreen(tester);
      await tester.pumpWidget(const KalkulyatorApp());

      await tester.enterText(find.byKey(const Key('login_field')), 'admin');
      await tester.enterText(find.byKey(const Key('password_field')), '12345');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('key_equals')), findsOneWidget);
    });
  });

  group('Kalkulyator oynasi', () {
    testWidgets('boshida ekranda 0 turadi', (tester) async {
      await openCalculator(tester);

      expect(textOf(tester, 'display_main'), '0');
      expect(textOf(tester, 'display_preview'), '');
      expect(textOf(tester, 'display_previous'), '');
    });

    testWidgets('barcha 20 ta tugma bor', (tester) async {
      await openCalculator(tester);

      const ids = [
        'clear', 'parens', 'percent', 'divide', //
        '7', '8', '9', 'times',
        '4', '5', '6', 'minus',
        '1', '2', '3', 'plus',
        '0', 'dot', 'backspace', 'equals',
      ];
      for (final id in ids) {
        expect(find.byKey(Key('key_$id')), findsOneWidget, reason: id);
      }
    });

    testWidgets('12 + 7 × 3 = 33', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '1 2 plus 7 times 3');
      expect(textOf(tester, 'display_main'), '12 + 7 × 3');
      expect(textOf(tester, 'display_preview'), '= 33');

      await tapKeys(tester, 'equals');
      expect(textOf(tester, 'display_main'), '33');
      expect(textOf(tester, 'display_previous'), '12 + 7 × 3 =');
      expect(textOf(tester, 'display_preview'), '');
    });

    testWidgets('har bir raqam tugmasi o\'z raqamini yozadi', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '1 2 3 4 5 6 7 8 9 0');

      expect(textOf(tester, 'display_main'), '1 234 567 890');
    });

    testWidgets('to\'rt amal tugmalari', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '8 plus 2 equals');
      expect(textOf(tester, 'display_main'), '10');
      await tapKeys(tester, '8 minus 2 equals');
      expect(textOf(tester, 'display_main'), '6');
      await tapKeys(tester, '8 times 2 equals');
      expect(textOf(tester, 'display_main'), '16');
      await tapKeys(tester, '8 divide 2 equals');
      expect(textOf(tester, 'display_main'), '4');
    });

    testWidgets('0.1 + 0.2 = 0.3', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '0 dot 1 plus 0 dot 2 equals');

      expect(textOf(tester, 'display_main'), '0.3');
    });

    testWidgets('qavs va foiz tugmalari', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, 'parens 2 plus 3 parens times 4 equals');
      expect(textOf(tester, 'display_main'), '20');

      await tapKeys(tester, '2 0 0 plus 1 0 percent equals');
      expect(textOf(tester, 'display_main'), '220');
    });

    testWidgets('natija bilan hisobni davom ettirish', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '1 divide 3 equals');
      expect(textOf(tester, 'display_main'), '0.333333333333333');

      await tapKeys(tester, 'times 3 equals');
      expect(textOf(tester, 'display_main'), '1');
    });

    testWidgets('nolga bo\'lishda xabar chiqadi', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '5 divide 0 equals');

      expect(textOf(tester, 'display_error'), "Nolga bo'lib bo'lmaydi");
      expect(textOf(tester, 'display_main'), '5 ÷ 0');

      // Keyingi tugma xabarni o'chiradi.
      await tapKeys(tester, 'backspace');
      expect(find.byKey(const Key('display_error')), findsNothing);
    });

    testWidgets('tugallanmagan ifodada xabar chiqadi', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '5 plus equals');

      expect(textOf(tester, 'display_error'), 'Ifoda tugallanmagan');
      expect(textOf(tester, 'display_main'), '5 +');
    });

    testWidgets('o\'chirish va AC tugmalari', (tester) async {
      await openCalculator(tester);

      await tapKeys(tester, '1 2 3 backspace');
      expect(textOf(tester, 'display_main'), '12');

      await tapKeys(tester, 'plus 4 clear');
      expect(textOf(tester, 'display_main'), '0');
    });

    testWidgets('o\'chirish tugmasini uzoq bosish hammasini tozalaydi', (
      tester,
    ) async {
      await openCalculator(tester);
      await tapKeys(tester, '1 2 plus 3');

      await tester.longPress(find.byKey(const Key('key_backspace')));
      await tester.pump();

      expect(textOf(tester, 'display_main'), '0');
    });

    testWidgets('juda uzun ifoda ekranga sig\'adi', (tester) async {
      await openCalculator(tester);

      for (var i = 0; i < 12; i++) {
        await tapKeys(tester, '1 2 3 4 5 6 7 8 9 times');
      }
      await tapKeys(tester, '2 equals');

      expect(tester.takeException(), isNull);
      expect(textOf(tester, 'display_main'), contains('E'));
    });

    testWidgets('tarix: ko\'rish, qayta ishlatish va tozalash', (tester) async {
      await openCalculator(tester);

      // Boshida tarix bo'sh.
      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();
      expect(find.text("Hozircha tarix bo'sh"), findsOneWidget);
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(find.text("Hozircha tarix bo'sh"), findsNothing);

      // Ikkita hisob.
      await tapKeys(tester, '2 plus 3 equals');
      await tapKeys(tester, '4 times 5 equals');

      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();
      expect(find.text('4 × 5'), findsOneWidget);
      expect(find.text('= 20'), findsOneWidget);
      expect(find.text('2 + 3'), findsOneWidget);
      expect(find.text('= 5'), findsOneWidget);

      // Eski hisobni tanlash uning natijasini ekranga qaytaradi.
      await tester.tap(find.byKey(const Key('history_item_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history_item_1')), findsNothing);
      expect(textOf(tester, 'display_main'), '5');
      expect(textOf(tester, 'display_previous'), '2 + 3 =');

      await tapKeys(tester, 'plus 1 equals');
      expect(textOf(tester, 'display_main'), '6');

      // Tozalash.
      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history_clear_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('history_button')));
      await tester.pumpAndSettle();
      expect(find.text("Hozircha tarix bo'sh"), findsOneWidget);
    });

    testWidgets('ekranni uzoq bosish natijani nusxalaydi', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openCalculator(tester);
      await tapKeys(tester, '1 0 0 0 times 3 equals');
      expect(textOf(tester, 'display_main'), '3 000');

      await tester.longPress(find.byKey(const Key('display_main')));
      await tester.pump();

      // Nusxada minglik ajratgichlar bo'lmaydi.
      expect(copied, '3000');
      expect(find.text('Nusxalandi'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('chiqish: bekor qilish va tasdiqlash', (tester) async {
      await openCalculator(tester);
      await tapKeys(tester, '7');

      // Bekor qilinsa, kalkulyator o'z holatida qoladi.
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      expect(find.text('Hisobdan chiqmoqchimisiz?'), findsOneWidget);
      await tester.tap(find.text("Yo'q"));
      await tester.pumpAndSettle();
      expect(find.text('Hisobdan chiqmoqchimisiz?'), findsNothing);
      expect(textOf(tester, 'display_main'), '7');

      // Tasdiqlansa, login oynasiga qaytiladi va maydonlar bo'sh bo'ladi.
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout_confirm_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('key_equals')), findsNothing);
      expect(find.text('Xush kelibsiz'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const Key('login_field')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        isEmpty,
      );

      // Qayta kirilganda kalkulyator toza holatda ochiladi.
      await signIn(tester);
      expect(textOf(tester, 'display_main'), '0');
    });
  });

  group('Turli ekran o\'lchamlari', () {
    const sizes = {
      'kichik telefon (320 × 480)': Size(320, 480),
      'telefon (360 × 640)': Size(360, 640),
      'katta telefon (412 × 915)': Size(412, 915),
      'yotiq telefon (800 × 360)': Size(800, 360),
      'kichik yotiq telefon (568 × 320)': Size(568, 320),
      'planshet, tik (800 × 1280)': Size(800, 1280),
      'planshet, yotiq (1280 × 800)': Size(1280, 800),
    };

    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets(name, (tester) async {
        useScreen(tester, size);
        await tester.pumpWidget(const KalkulyatorApp());
        expect(tester.takeException(), isNull);

        // Xato xabarlari bilan birga ham login oynasi sig'ishi kerak.
        await tapLoginButton(tester);
        expect(find.text('Loginni kiriting'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await signIn(tester);
        expect(tester.takeException(), isNull);

        // Uzun ifoda, natija va xato xabari bilan ham joylashuv buzilmaydi.
        await tapKeys(
          tester,
          '1 2 3 4 5 6 7 8 9 times parens 9 8 7 6 5 4 3 2 1 plus 0 dot 5',
        );
        expect(tester.takeException(), isNull);
        await tapKeys(tester, 'equals');
        expect(textOf(tester, 'display_main'), '1.21932631174364E17');
        await tapKeys(tester, 'divide 0 equals');
        expect(textOf(tester, 'display_error'), "Nolga bo'lib bo'lmaydi");
        expect(tester.takeException(), isNull);

        // Har bir tugma ekran ichida va bosish mumkin bo'lgan o'lchamda.
        final screen = Offset.zero & size;
        for (final element in find.byType(InkWell).evaluate()) {
          final box = element.renderObject! as RenderBox;
          final rect = box.localToGlobal(Offset.zero) & box.size;
          expect(screen.contains(rect.topLeft), isTrue, reason: '$rect');
          expect(
            screen.contains(rect.bottomRight - const Offset(1, 1)),
            isTrue,
            reason: '$rect',
          );
        }
      });
    }
  });
}
