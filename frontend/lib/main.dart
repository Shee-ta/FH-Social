import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDI.instance.init();
  runApp(const FHSocialApp());
}
