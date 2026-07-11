import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'app.dart';

void main() {
  AppDI.instance.init();
  runApp(const FHSocialApp());
}
