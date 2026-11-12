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
      error.toString().replaceFirst('Exception: ', '').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Text('<-'),
        ),
        title: const Text('CREATE ACCOUNT'),
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
                        'JOIN THE COMMUNITY.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _field(
                      controller: name,
                      label: 'DISPLAY NAME',
                      hint: 'YOUR NAME',
                      validator: (value) =>
                          value == null || value.trim().length < 2
                          ? 'ENTER YOUR NAME.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: email,
                      label: 'EMAIL',
                      hint: 'YOU@EXAMPLE.COM',
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
                    const SizedBox(height: 16),
                    _field(
                      controller: confirmation,
                      label: 'CONFIRM PASSWORD',
                      hint: 'REPEAT PASSWORD',
                      obscureText: true,
                      validator: (value) => value != password.text
                          ? 'PASSWORDS DO NOT MATCH.'
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
                            loading ? 'CREATING...' : 'CREATE ACCOUNT ->',
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
