import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider? coverImageProvider(String? path) {
  if (path == null || path.isEmpty || path.startsWith('web://')) return null;
  final file = File(path);
  return file.existsSync() ? FileImage(file) : null;
}
