import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import './sheets.dart';
import './item.dart';

Future<List<String>> loadSheets() async {
  final directory = await getApplicationDocumentsDirectory();

  List<File> l = [];
  directory.listSync().forEach((e) {
    if (e is File && path.extension(e.path) == '.cb') l.add(e);
  });
  l.sort((a, b) => b.lastAccessedSync().compareTo(a.lastAccessedSync()));
  return l.map((e) => e.path).toList();
}

final loadingProvider = FutureProvider<List<String>>((ref) => loadSheets());

final sheetsProvider = StateNotifierProvider<Sheets>((ref) {
  final loading = ref.watch(loadingProvider);
  return loading.whenData((value) => Sheets(value)).data.value;
});

final currentFileProvider = StateProvider<File>((ref) {
  final loading = ref.watch(loadingProvider);

  return loading
      .whenData((value) {
        final sheets = ref.read(sheetsProvider);
        return sheets.isEmpty ? null : File(sheets.first);
      })
      .data
      .value;
});

final currentItems = StateNotifierProvider<Items>((ref) {
  final file = ref.watch(currentFileProvider).state;
  return Items(file);
});
