import 'dart:io';

import 'package:countbean/statistics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import './sheets.dart';
import './item.dart';
import './parser/parser.dart';
import './search.dart';
import './balances.dart';

Future<List<String>> loadSheets() async {
  final directory = (await getExternalStorageDirectory())!;

  List<File> l = [];
  directory.listSync().forEach((e) {
    if (e is File && path.extension(e.path) == '.cb') l.add(e);
  });
  l.sort((a, b) => b.lastAccessedSync().compareTo(a.lastAccessedSync()));
  return l.map((e) => e.path).toList();
}

final loadingProvider = FutureProvider<List<String>>((ref) => loadSheets());

final sheetsProvider = StateNotifierProvider<Sheets, List<String>>((ref) {
  final loading = ref.watch(loadingProvider);

  final data = loading.whenData((value) => Sheets(value)).asData;

  if (data == null) return Sheets();
  return data.value;
});

final currentFileProvider = StateProvider<File?>((ref) {
  final loading = ref.watch(loadingProvider);
  if (loading.asData == null) return null;

  final sheets = ref.read(sheetsProvider.notifier);
  return sheets.isEmpty ? null : File(sheets.first!);
});

final parsingProvider = FutureProvider<List?>((ref) async {
  final currentFile = ref.watch(currentFileProvider);

  if (currentFile == null) return null;

  return BeancountParserDefinition()
      .build()
      .parse(await currentFile.readAsString())
      .value;
});

final currentItemsProvider = StateNotifierProvider<Items, List<Item>>((ref) {
  final items = ref.watch(parsingProvider);

  final data = items.asData;
  if (data == null) return Items(ref.read);

  return Items(ref.read, data.value?.map((e) => Item(e)).toList());
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
  final searchPattern = ref.watch(searchPatternProvider);
  final items = ref.watch(currentItemsProvider);

  final filters = SearchBarViewDelegate.generateFilters(searchPattern);
  return items.where((element) {
    if (filters.isEmpty) return true;
    for (final filter in filters) {
      if (!filter(element)) return false;
    }
    return true;
  }).toList();
});

final currentStatisticsProvider = Provider<Statistics>((ref) {
  final items = ref.watch(parsingProvider);
  return Statistics()..addItems(items.asData?.value?.map((e) => Item(e)));
});

final currentDisplayAccountBalancingsProvider = Provider<List<Balances>>((ref) {
  final accounts = ref.watch(statisticsAccountsProvider);
  final items = ref.watch(currentDisplayedItemsProvider);
  final s = ref.watch(currentStatisticsProvider);

  return accounts.map((a) => Balances(a, s.balance(a, items))).toList();
});
