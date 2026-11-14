import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../design/brutal_theme.dart';
import '../data/social_models.dart';
import '../data/social_repository.dart';

enum UsernameAvailability { idle, checking, available, taken, unknown }

/// Checks whether a username is free, debounced while the user types.
class UsernameChecker extends ChangeNotifier {
  UsernameChecker({
    Future<bool> Function(String username)? check,
    this.debounce = const Duration(milliseconds: 450),
  }) : _check =
           check ??
           ((name) => isUsernameAvailable(FirebaseFirestore.instance, name));

  final Future<bool> Function(String username) _check;
  final Duration debounce;

  UsernameAvailability _state = UsernameAvailability.idle;
  UsernameAvailability get state => _state;
  String _value = '';
  Timer? _timer;
  int _token = 0;

  void onChanged(String value) {
    _value = value.trim();
    _timer?.cancel();
    final token = ++_token;
    if (Usernames.validate(_value) != null) {
      _set(UsernameAvailability.idle);
      return;
    }
    _set(UsernameAvailability.checking);
    _timer = Timer(debounce, () => _run(_value, token));
  }

  /// Checks now (used on submit). Returns true when free, false when
  /// taken, null when it could not be checked (offline / not set up).
  Future<bool?> checkNow(String value) async {
    _timer?.cancel();
    _value = value.trim();
    return _run(_value, ++_token);
  }

  Future<bool?> _run(String value, int token) async {
    try {
      final free = await _check(value);
      if (token == _token) {
        _set(
          free ? UsernameAvailability.available : UsernameAvailability.taken,
        );
      }
      return free;
    } catch (_) {
      if (token == _token) _set(UsernameAvailability.unknown);
      return null;
    }
  }

  void _set(UsernameAvailability state) {
    if (_state == state) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// A username text field with format validation and a live
/// "available / taken" indicator.
class UsernameField extends StatelessWidget {
  const UsernameField({
    required this.controller,
    required this.checker,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  final TextEditingController controller;
  final UsernameChecker checker;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: checker,
      builder: (context, _) {
        final state = checker.state;
        final (Widget? suffix, String? helper) = switch (state) {
          UsernameAvailability.checking => (
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            'Checking…',
          ),
          UsernameAvailability.available => (
            const Icon(Icons.check_circle, color: BrutalColors.green),
            'Available',
          ),
          UsernameAvailability.taken => (
            Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
            null,
          ),
          UsernameAvailability.unknown || UsernameAvailability.idle => (
            null,
            '3–20 letters, numbers or underscores',
          ),
        };
        return TextFormField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: textInputAction,
          onChanged: checker.onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixText: '@',
            helperText: helper,
            suffixIcon: suffix,
            errorText: state == UsernameAvailability.taken
                ? 'That username is taken.'
                : null,
          ),
          validator: Usernames.validate,
        );
      },
    );
  }
}
