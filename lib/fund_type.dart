import 'package:flutter/material.dart';



enum FundType { lilTreat, funPurchase }

extension FundTypeX on FundType {
  String get label {
    switch (this) {
      case FundType.lilTreat:
        return 'a lil treat';
      case FundType.funPurchase:
        return 'fun purchase';
    }
  }

  IconData get icon {
    switch (this) {
      case FundType.lilTreat:
        return Icons.coffee;
      case FundType.funPurchase:
        return Icons.shopping_bag;
      
    }
  }

  String get key {
    switch (this) {
      case FundType.lilTreat:
        return 'fund_lilTreat';
      case FundType.funPurchase:
        return 'fund_funPurchase';
      
    }
  }
}