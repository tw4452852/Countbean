import 'package:flutter/material.dart';

import './parser/model.dart';

class Item {
  static const TransactionIcon = Icons.swap_horiz;
  static const AccountActionIcon = Icons.account_balance;
  static const CommodityIcon = Icons.monetization_on;
  static const EventIcon = Icons.event;
  static const OptionIcon = Icons.settings;
  static const BalanceIcon = Icons.check_box;
  static const PadIcon = Icons.last_page;

  bool isVisible;
  final dynamic content;

  IconData get icon {
    switch (content.runtimeType) {
      case Transaction:
        return TransactionIcon;
      case AccountAction:
        return AccountActionIcon;
      case Commodity:
        return CommodityIcon;
      case Event:
        return EventIcon;
      case Option:
        return OptionIcon;
      case Balance:
        return BalanceIcon;
      case Pad:
        return PadIcon;

      default:
        return Icons.build;
    }
  }

  DateTime get date {
    if (content is Option) {
      return DateTime(1);
    }
    if (content is Balance) {
      return content.date.subtract(const Duration(microseconds: 1));
    }
    return content.date;
  }

  Item(this.content, {this.isVisible = false});

  @override
  String toString() => content.toString();
}
