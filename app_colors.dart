// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ✅ Primary brand color
  static const Color primary = Color(0xFF1976D2);

  static const Color textColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  // ✅ Accent color
  static const Color accent = Color(0xFFFFA000);

  // ✅ Background colors
  static const Color scaffoldBackground = Color(0xFFF7F8FA);
  static const Color cardBackground = Colors.white;
  static const Color cardColor = Colors.white;

  // ✅ Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // ✅ Borders and other elements
  static const Color border = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color error = Color(0xFFD32F2F);

  // ✅ Old names for backward compatibility (so errors stop)
  static const Color backgroundColor = scaffoldBackground;
  static const Color primaryColor = primary;
}
