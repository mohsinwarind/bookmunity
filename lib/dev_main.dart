// TEMPORARY local verification entrypoint (not committed).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/library/presentation/library_screen.dart';
import 'main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: appProviderOverrides,
      child: const BookmunityApp(home: LibraryScreen()),
    ),
  );
}
