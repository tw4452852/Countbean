import 'dart:io';

import 'package:countbean/providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

class Items extends StateNotifier<List<Item>> {
  final Reader read;
  Items(this.read, [List<Item>? initItems]) : super(initItems ?? []);

  _updateFile({bool isAppend = false, Iterable<Item>? appendItems}) {
    final file = read(currentFileProvider).state;
    if (file == null) {
      return;
    }

    final entries = isAppend ? appendItems : state;
    final sink =
        file.openWrite(mode: isAppend ? FileMode.append : FileMode.write);
    entries?.forEach((e) => sink.writeln(e));
    sink.flush().then((_) => sink.close());
  }

  add(Iterable<Item> items) {
    int i;
    late bool isAppend;

    for (final item in items) {
      i = state.lastIndexWhere((element) => !element.date.isAfter(item.date)) +
          1;
      isAppend = i == state.length;
      state = [
        ...state.sublist(0, i),
        item,
        ...state.sublist(i),
      ];
    }

    _updateFile(isAppend: isAppend, appendItems: isAppend ? items : null);
    read(currentStatisticsProvider).addItems(items);
  }

  del(Item item) {
    final i = state.indexOf(item);
    if (i != -1) {
      state = [
        ...state.sublist(0, i),
        ...state.sublist(i + 1),
      ];
      _updateFile();
      read(currentStatisticsProvider).delItems([item]);
    }
  }
}
