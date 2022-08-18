import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class Sheets extends StateNotifier<List<String>> {
  Sheets([List<String>? initiSheets]) : super(initiSheets ?? []);

  Future<File> add(String path) async {
    final f = File(path);

    if (state.contains(path)) {
      return f;
    }

    state = [
      path,
      ...state,
    ];
    return f.create(recursive: true);
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

  Future<File?> rename(String o, String n) async {
    final i = state.indexOf(o);
    if (i == -1) {
      return null;
    }

    state = [
      n,
      ...state.sublist(0, i),
      ...state.sublist(i + 1),
    ];
    return File(o).rename(n).then((f) {
      f.setLastAccessed(DateTime.now());
      return f;
    });
  }

  Future<File?> open(String p) async {
    final i = state.indexOf(p);
    if (i == -1) {
      return null;
    }

    state = [
      p,
      ...state.sublist(0, i),
      ...state.sublist(i + 1),
    ];
    final f = File(p);

    return f.setLastAccessed(DateTime.now()).then((_) => f);
  }

  bool get isEmpty => state.isEmpty;
  String? get first => isEmpty ? null : state.first;
  void reset(List<String> s) => state = s;
}
