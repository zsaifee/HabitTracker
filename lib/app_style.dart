import 'package:flutter/material.dart';
import 'fund_type.dart';


class AppStyle {
  // Pastel-ish palette
  static const primary = Color(0xFF7C5CFF); // periwinkle
  static const secondary = Color(0xFFFF5DA2); // pink
  static const tertiary = Color(0xFF2AD4D9); // aqua
  static const sunshine = Color(0xFFFFC857); // warm yellow
  static const mint = Color(0xFF7AE7C7);
  static const bg = Color(0xFFF7F6FF); // soft lilac-gray

  static LinearGradient headerGradient(BuildContext context) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary],
      );

  static LinearGradient pageWash() => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF7F6FF), Color(0xFFFFFFFF)],
      );

  static Color fundColor(FundType t) {
    switch (t) {
      case FundType.lilTreat:
        return sunshine;
      case FundType.funPurchase:
        return secondary;
      case FundType.saver:
        return tertiary;
    }
  }
}