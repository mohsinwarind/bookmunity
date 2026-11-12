import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/bookmunity.sqlite');
  return NativeDatabase.createInBackground(file);
}
