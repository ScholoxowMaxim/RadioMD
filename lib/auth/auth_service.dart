import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get user => _auth.authStateChanges();

  /// Возвращает [User] при успехе или бросает [FirebaseAuthException]
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow; // Пробрасываем исключение дальше, чтобы LoginScreen получил код ошибки
    }
  }

  /// Возвращает [User] при успехе или бросает [FirebaseAuthException]
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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Преобразует код ошибки Firebase в понятное сообщение на русском
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'invalid-email':
        return 'Некорректный email адрес.';
      case 'operation-not-allowed':
        return 'Вход по email/паролю отключён. Обратитесь к разработчику.';
      case 'weak-password':
        return 'Пароль слишком слабый. Минимум 6 символов.';
      case 'user-disabled':
        return 'Этот аккаунт заблокирован.';
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