import 'package:flutter/material.dart';

/// Root messenger so services (badge unlocks, sync errors) can show a
/// snackbar regardless of which screen is open.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();
