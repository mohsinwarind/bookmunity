import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../design/brand_logo.dart';
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
      _message('Enter your email first.');
      return;
    }
    try {
      await auth.sendPasswordReset(email.text);
      if (mounted) _message('Password reset email sent.');
    } catch (error) {
      if (mounted) _message(_cleanError(error));
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                    const Center(child: BrandLogo(height: 150)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Bookmunity',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Read. Connect. Belong.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    BrutalCard(
                      backgroundColor: BrutalColors.yellow,
                      child: Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: BrutalColors.ink),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      controller: email,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: password,
                      label: 'Password',
                      hint: 'At least 6 characters',
                      obscureText: obscure,
                      suffix: IconButton(
                        tooltip: obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password is too short.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: BrutalPressable(
                        onPressed: loading ? null : submit,
                        backgroundColor: BrutalColors.blue,
                        foregroundColor: Colors.white,
                        child: Center(
                          child: Text(loading ? 'Signing in…' : 'Sign in'),
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
                        child: const Text('New here? Create an account'),
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
