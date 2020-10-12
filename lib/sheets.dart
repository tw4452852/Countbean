import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class Sheets extends StateNotifier<List<String>> {
  Sheets([List<String> initiSheets]) : super(initiSheets ?? []);

  bool add(String path) {
    if (state.contains(path)) {
      return false;
    }

    File(path).setLastAccessed(DateTime.now());
    state = [
      path,
      ...state,
    ];
    return true;
  }

  bool del(String path) {
    final i = state.indexOf(path);
    if (i == -1) {
      return false;
    }

    File(path).delete();
    state = [
      ...state.sublist(0, i),
      ...state.sublist(i + 1),
    ];
    return true;
  }

  bool rename(String o, String n) {
    final i = state.indexOf(o);
    if (i == -1) {
      return false;
    }

    File(o).rename(n).then((f) => f.setLastAccessed(DateTime.now()));
    state = [
      n,
      ...state.sublist(0, i),
      ...state.sublist(i + 1),
    ];
    return true;
  }

  bool get isEmpty => state == null || state.isEmpty;
  String get first => isEmpty ? null : state.first;
  void reset(List<String> s) => state = s;
}
