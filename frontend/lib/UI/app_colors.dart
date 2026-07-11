
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.successOutline,
    required this.onSuccess,
  });

  final Color success;
  final Color successOutline;
  final Color onSuccess;

  @override
  AppColors copyWith({
    Color? success,
    Color? successOutline,
    Color? onSuccess,
  }) {
    return AppColors(
      success: success ?? this.success,
      successOutline: successOutline ?? this.successOutline,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  AppColors lerp(
    ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      successOutline: Color.lerp(successOutline, other.successOutline, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }
}