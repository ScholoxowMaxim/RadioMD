import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:radiomd/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

Future<void> _handleSignIn() async {
  setState(() => _errorMessage = '');
  try {
    await _auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    // После успешного входа роутер сам перенаправит на главный экран
  } on FirebaseAuthException catch (e) {
    setState(() => _errorMessage = AuthService.getErrorMessage(e));
  } catch (e) {
    setState(() => _errorMessage = 'Неизвестная ошибка. Попробуйте позже.');
  }
}

Future<void> _handleSignUp() async {
  setState(() => _errorMessage = '');
  try {
    await _auth.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    // После успешной регистрации роутер сам перенаправит
  } on FirebaseAuthException catch (e) {
    setState(() => _errorMessage = AuthService.getErrorMessage(e));
  } catch (e) {
    setState(() => _errorMessage = 'Неизвестная ошибка. Попробуйте позже.');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Вход / Регистрация'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.7)),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Пароль',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.7)),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _handleSignIn,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Войти'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _handleSignUp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}