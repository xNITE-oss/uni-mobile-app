/// Login va parolni tekshirish.
///
/// Bu o'quv loyihasi, shuning uchun bitta sinov hisobi kodning o'zida
/// saqlanadi. Haqiqiy ilovada login va parol serverda tekshiriladi va
/// parol hech qachon ilova kodida saqlanmaydi.
class AuthService {
  const AuthService();

  /// Sinov uchun login.
  static const String demoLogin = 'admin';

  /// Sinov uchun parol.
  static const String demoPassword = '12345';

  /// Login va parol to'g'ri bo'lsa `true` qaytaradi.
  ///
  /// Login katta-kichik harfga bog'liq emas va atrofidagi bo'sh joylar
  /// hisobga olinmaydi (telefon klaviaturasi birinchi harfni katta yozib
  /// yuborishi mumkin). Parol esa aynan mos kelishi shart.
  bool signIn(String login, String password) {
    return login.trim().toLowerCase() == demoLogin && password == demoPassword;
  }
}
