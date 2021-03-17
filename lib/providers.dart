import 'dart:io';

import 'package:countbean/statistics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import './sheets.dart';
import './item.dart';
import './parser/parser.dart';
import './search.dart';

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
  if (loading.data == null) return null;

  final sheets = ref.read(sheetsProvider);
  return sheets.isEmpty ? null : File(sheets.first);
});

final parsingProvider = FutureProvider<List>((ref) async {
  final currentFile = ref.watch(currentFileProvider).state;

  if (currentFile == null) return null;

  return BeancountParser().parse(await currentFile.readAsString()).value;
});

final currentItemsProvider = StateNotifierProvider<Items>((ref) {
  final items = ref.watch(parsingProvider);

  if (items.data == null) return null;

  return Items(ref.read, items.data.value.map((e) => Item(e)).toList());
});

final searchPatternProvider = StateProvider<String>((ref) {
  ref.watch(currentFileProvider);
  return '';
});

final statisticsAccountsProvider = StateProvider<List<String>>((ref) {
  ref.watch(currentFileProvider);
  return [];
});

final currentDisplayedItemsProvider = Provider<List<Item>>((ref) {
  final searchPattern = ref.watch(searchPatternProvider).state;
  final items = ref.watch(currentItemsProvider.state);

  final filters = SearchBarViewDelegate.generateFilters(searchPattern);
  return items?.where((element) {
    if (filters == null || filters.isEmpty) return true;
    for (final filter in filters) {
      if (!filter(element)) return false;
    }
    return true;
  })?.toList();
});

final currentStatisticsProvider = Provider<Statistics>((ref) {
  final items = ref.watch(parsingProvider);
  return Statistics()..addItems(items.data.value);
});
