import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn();
  }

  Stream<User?> get user => _auth.authStateChanges();

  /// Вход через Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

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

  /// Регистрация с email и паролем
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Вход с email и паролем
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

  /// Выход
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Понятные сообщения об ошибках
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'invalid-email':
        return 'Некорректный email адрес.';
      case 'operation-not-allowed':
        return 'Вход по email/паролю отключён.';
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
      case 'account-exists-with-different-credential':
        return 'Этот email уже используется через другой способ входа.';
      default:
        return 'Ошибка: ${e.message}';
    }
  }
}