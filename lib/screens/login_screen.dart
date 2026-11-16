import 'package:material_ui/material_ui.dart';

import '../logic/auth_service.dart';
import 'calculator_screen.dart';

/// Login oynasi: login va parol so'raladi, to'g'ri bo'lsa kalkulyator
/// oynasi ochiladi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService = const AuthService()});

  /// Login va parolni tekshiruvchi xizmat.
  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Parol yashirilganmi (nuqtalar bilan ko'rsatiladimi).
  bool _obscurePassword = true;

  /// Login yoki parol noto'g'ri bo'lganda ko'rsatiladigan xabar.
  String? _authError;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// "Kirish" tugmasi bosilganda ishlaydi.
  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _authError = null);

    // 1. Maydonlar to'ldirilganini tekshirish.
    if (!_formKey.currentState!.validate()) return;

    // 2. Login va parolni tekshirish.
    final login = _loginController.text.trim();
    final signedIn = widget.authService.signIn(login, _passwordController.text);
    if (!signedIn) {
      setState(() => _authError = "Login yoki parol noto'g'ri");
      return;
    }

    // 3. Kalkulyator oynasiga o'tish. `pushReplacement` login oynasini
    //    yopadi, shuning uchun "orqaga" tugmasi bu yerga qaytarmaydi.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CalculatorScreen(username: login),
      ),
    );
  }

  /// Foydalanuvchi maydonni tahrirlay boshlasa, eski xato xabari o'chadi.
  void _clearAuthError(String _) {
    if (_authError != null) setState(() => _authError = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.calculate_rounded,
                          size: 52,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Xush kelibsiz',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kalkulyatordan foydalanish uchun tizimga kiring',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('login_field'),
                      controller: _loginController,
                      decoration: const InputDecoration(
                        labelText: 'Login',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: _clearAuthError,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Loginni kiriting'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password_field'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Parol',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          key: const Key('password_visibility_button'),
                          tooltip: _obscurePassword
                              ? "Parolni ko'rsatish"
                              : 'Parolni yashirish',
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: _clearAuthError,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Parolni kiriting'
                          : null,
                    ),
                    if (_authError != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _authError!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('login_button'),
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        textStyle: theme.textTheme.titleMedium,
                      ),
                      child: const Text('Kirish'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sinov uchun: login — ${AuthService.demoLogin}, '
                      'parol — ${AuthService.demoPassword}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Qizil fonli xato xabari.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('login_error'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
