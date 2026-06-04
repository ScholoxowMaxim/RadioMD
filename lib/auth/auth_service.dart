import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Сервис для работы с аутентификацией пользователей
/// Обеспечивает вход/регистрацию через Google и Email/пароль
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(); // Инициализация Google Sign-In
  }

  /// Поток состояния аутентификации (когда пользователь входит/выходит)
  Stream<User?> get user => _auth.authStateChanges();

  /// Вход через Google
  /// Возвращает User если успешно, null если отменено или ошибка
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Показываем Google диалог выбора аккаунта
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Пользователь отменил вход

      // 2. Получаем токены аутентификации
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Создаем Firebase credential из токенов Google
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Входим в Firebase с этими credential
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Ошибка Google Sign-In: ${e.code}');
      return null;
    } catch (e) {
      print('Ошибка Google Sign-In: $e');
      return null;
    }
  }

  /// Регистрация нового пользователя с email и паролем
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow; // Пробрасываем ошибку для обработки на UI
    }
  }

  /// Вход существующего пользователя по email и паролю
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Выход из аккаунта
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Выход из Google
    await _auth.signOut();         // Выход из Firebase
  }

  /// Преобразование Firebase ошибок в понятные пользователю сообщения
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'invalid-email':
        return 'Некорректный email адрес.';
      case 'weak-password':
        return 'Пароль слишком слабый. Минимум 6 символов.';
      case 'user-not-found':
        return 'Пользователь с таким email не найден.';
      case 'wrong-password':
        return 'Неверный пароль.';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже.';
      case 'network-request-failed':
        return 'Проблема с интернет-соединением.';
      default:
        return 'Ошибка: ${e.message}';
    }
  }
}