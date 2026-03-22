import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color black = Color(0xFF0A0A0A);
  static const Color gold = Color(0xFFD4AF37);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF888888);
  static const Color darkGrey = Color(0xFF1A1A1A);

  // Text Styles
  static const TextStyle heading = TextStyle(
    color: white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  static const TextStyle subheading = TextStyle(
    color: grey,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle goldText = TextStyle(
    color: gold,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
  );
}