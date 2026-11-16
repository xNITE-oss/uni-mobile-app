import 'package:material_ui/material_ui.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const KalkulyatorApp());
}

/// Ilovaning ildiz vidjeti: mavzu (yorug' va qorong'i) hamda birinchi oyna.
///
/// Ilova har doim login oynasi bilan ochiladi. To'g'ri login va parol
/// kiritilgach, kalkulyator oynasiga o'tiladi.
class KalkulyatorApp extends StatelessWidget {
  const KalkulyatorApp({super.key});

  /// Butun ilova ranglari shu bitta rangdan hosil qilinadi.
  static const Color _seedColor = Color(0xFF3D5AFE);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulyator',
      debugShowCheckedModeBanner: false,
      // Telefon sozlamasiga qarab yorug' yoki qorong'i mavzu tanlanadi.
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const LoginScreen(),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
        // Ranglar tanlangan rangga yaqin, yorqinroq chiqadi.
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
    );
  }
}
