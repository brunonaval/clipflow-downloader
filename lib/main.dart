import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    try {
      await windowManager.ensureInitialized();
    } catch (_) {}
  }
  runApp(const ClipFlowApp());
}
