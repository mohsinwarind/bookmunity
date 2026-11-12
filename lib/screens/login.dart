import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../design/brutal_theme.dart';
import '../design/brutal_widgets.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await auth.loginUser(email: email.text, password: password.text);
    } catch (error) {
      if (mounted) _message(_cleanError(error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty || !email.text.contains('@')) {
      _message('ENTER YOUR EMAIL FIRST.');
      return;
    }
    try {
      await auth.sendPasswordReset(email.text);
      if (mounted) _message('RESET EMAIL SENT.');
    } catch (error) {
      if (mounted) _message(_cleanError(error));
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').toUpperCase();

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOOKMUNITY',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('READ. CONNECT. BELONG.'),
                    const SizedBox(height: 36),
                    BrutalCard(
                      backgroundColor: BrutalColors.yellow,
                      child: Text(
                        'WELCOME BACK.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      controller: email,
                      label: 'EMAIL',
                      hint: 'YOU@EXAMPLE.COM',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'ENTER A VALID EMAIL.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: password,
                      label: 'PASSWORD',
                      hint: 'MINIMUM 6 CHARACTERS',
                      obscureText: obscure,
                      suffix: BrutalPressable(
                        onPressed: () => setState(() => obscure = !obscure),
                        padding: const EdgeInsets.all(10),
                        child: Text(obscure ? 'SHOW' : 'HIDE'),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'PASSWORD IS TOO SHORT.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text('RESET PASSWORD'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: BrutalPressable(
                        onPressed: loading ? null : submit,
                        backgroundColor: BrutalColors.blue,
                        foregroundColor: BrutalColors.paper,
                        child: Center(
                          child: Text(loading ? 'SIGNING IN...' : 'SIGN IN ->'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupPage()),
                        ),
                        child: const Text('NEW HERE? CREATE ACCOUNT ->'),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix,
      ),
    );
  }
}
