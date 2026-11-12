// Drift's WebDatabase is the stable compatibility backend for this target.
// ignore_for_file: deprecated_member_use, experimental_member_use

import 'package:drift/web.dart';

Future<WebDatabase> createDatabaseExecutor() async {
  return WebDatabase.withStorage(DriftWebStorage.indexedDb('bookmunity'));
}
