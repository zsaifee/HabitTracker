import 'package:flutter/material.dart';
import 'fund_type.dart';

class AppStyle {
  static const eucalyptus = Color(0xFF92ADA4);
  static const roastedPeach = Color(0xFFDAA38F);
  static const cream = Color(0xFFFED8A6);

  // App roles
  static const primary = eucalyptus;
  static const secondary = roastedPeach;
  static const bg = Color(0xFFFFFBF6); // very soft warm off-white

  static LinearGradient headerGradient(BuildContext context) =>
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          eucalyptus,
          cream,
        ],
      );

  static LinearGradient pageWash() => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFBF6),
          Color(0xFFFFFFFF),
        ],
      );

  static Color fundColor(FundType t) {
    switch (t) {
      case FundType.lilTreat:
        return cream;
      case FundType.funPurchase:
        return roastedPeach;
      case FundType.saver:
        return eucalyptus;
    }
  }
}
