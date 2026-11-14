import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../design/brutal_theme.dart';
import '../design/brutal_widgets.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final auth = AuthController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await auth.signupUser(
        email: email.text,
        password: password.text,
        displayName: name.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_cleanError(error))));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),
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
                    BrutalCard(
                      backgroundColor: BrutalColors.pink,
                      child: Text(
                        'Join the community',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: BrutalColors.ink),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      controller: name,
                      label: 'Display name',
                      hint: 'Your name',
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: email,
                      label: 'Email',
                      hint: 'you@example.com',
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
                    const SizedBox(height: 16),
                    _field(
                      controller: confirmation,
                      label: 'Confirm password',
                      hint: 'Repeat password',
                      obscureText: true,
                      validator: (value) => value != password.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: BrutalPressable(
                        onPressed: loading ? null : submit,
                        backgroundColor: BrutalColors.green,
                        child: Center(
                          child: Text(
                            loading ? 'Creating account…' : 'Create account',
                          ),
                        ),
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
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
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
