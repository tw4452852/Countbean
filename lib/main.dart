import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expandable/expandable.dart';
import 'package:package_info/package_info.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:widgets_visibility_provider/widgets_visibility_provider.dart';
import 'package:petitparser/petitparser.dart';

import './parser/widget.dart';
import './parser/parser.dart';
import './add.dart';
import './item.dart';
import './search.dart';
import './providers.dart';

void main() async {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'countbean',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  @override
  Widget build(context, ref) {
    final loading = ref.watch(loadingProvider);
    return loading.when(
        data: (_) => Home(),
        loading: () => Center(
              child: const SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
            ),
        error: (err, stack) => Center(child: Text('Error: $err')));
  }
}

Future<File?> createFile(context) async {
  final directory = (await getExternalStorageDirectory())!;
  final name = await showDialog<String>(
      context: context,
      builder: (context) {
        String? input;
        return AlertDialog(
          scrollable: true,
          title: const Text('Create a new sheet'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: "Name:"),
            onChanged: (v) => input = v,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("CANCEL"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(input ??= "");
              },
            ),
          ],
        );
      });
  if (name != null && name.isNotEmpty) {
    return await File('${directory.path}/$name.cb').create();
  }
  return null;
}

class Startup extends HookConsumerWidget {
  @override
  Widget build(context, ref) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            child: const Text('Create a empty sheet'),
            onPressed: () async {
              final f = await createFile(context);

              if (f != null) {
                ref.read(currentFileProvider.notifier).state = f;
                ref.read(sheetsProvider.notifier).add(f.path);
              }
            },
          ),
          ElevatedButton(
            child: const Text('Import from file'),
            onPressed: () async {
              final f = await FilePicker.platform.pickFiles();
              final d = (await getExternalStorageDirectory())!;
              if (f != null) {
                final filePath = f.files.first.path;
                if (filePath == null) return null;
                final p = path.join(
                    d.path, '${path.basenameWithoutExtension(filePath)}.cb');
                ref.read(currentFileProvider.notifier).state =
                    await File(filePath).copy(p);
                ref.read(sheetsProvider.notifier).add(p);
              }
            },
          ),
        ],
      ),
    );
  }
}

class Home extends HookConsumerWidget {
  @override
  Widget build(context, ref) {
    final currentFile = ref.watch(currentFileProvider);
    final parsing = ref.watch(parsingProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentFile == null
            ? const Text('Home')
            : Text(path.basenameWithoutExtension(currentFile.path)),
        actions: [
          Consumer(
            builder: (context, watch, child) {
              final searchPattern = ref.watch(searchPatternProvider);
              return Row(
                children: [
                  if (searchPattern.isNotEmpty)
                    SizedBox(
                      width: 100,
                      child: Chip(
                        label: Text(
                          searchPattern,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          ref.read(searchPatternProvider.notifier).state = '';
                        },
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final pattern = await showSearch<String?>(
                        context: context,
                        delegate: SearchBarViewDelegate(
                            ref.read(currentStatisticsProvider)),
                        query: searchPattern,
                      );
                      if (pattern != null && pattern != searchPattern) {
                        ref.read(searchPatternProvider.notifier).state =
                            pattern;
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: currentFile == null ? Startup() : Parsing(),
      drawer: MyDrawer(),
      floatingActionButton: currentFile == null
          ? null
          : parsing.maybeWhen(
              orElse: () => null,
              data: (_) => FloatingActionButton(
                onPressed: () async {
                  final List? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddWidget(),
                    ),
                  );
                  if (result != null && result.isNotEmpty) {
                    ref
                        .read(currentItemsProvider.notifier)
                        .add(result.map((e) => Item(e)));
                  }
                },
                child: const Icon(Icons.create),
              ),
            ),
    );
  }
}

class MyDrawer extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.read(currentFileProvider);
    final items = ref.read(currentItemsProvider);
    final ctx = useContext();

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawerHeader(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (data != null) {
                  final version = data.version;
                  final buildNumber = data.buildNumber;
                  return Center(
                    child: Text(
                        "Version:$version${buildNumber.isNotEmpty ? '+$buildNumber' : ''}"),
                  );
                } else {
                  return Center(
                    child: const SizedBox(
                      child: CircularProgressIndicator(),
                      width: 60,
                      height: 60,
                    ),
                  );
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New'),
            onTap: () async {
              final directory = (await getExternalStorageDirectory())!;
              final name = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String? input;
                    return AlertDialog(
                      scrollable: true,
                      title: const Text('Create a new sheet'),
                      content: TextField(
                        autofocus: true,
                        decoration: InputDecoration(labelText: "Name:"),
                        onChanged: (v) => input = v,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text("CANCEL"),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop(input);
                          },
                        ),
                      ],
                    );
                  });
              if (name != null && name.isNotEmpty) {
                await ref
                    .read(sheetsProvider.notifier)
                    .add('${directory.path}/$name.cb');
                Navigator.pop(context);
              }
            },
          ),
          if (file != null) ...[
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      content: Text(
                          'Do you want to delete "${path.basenameWithoutExtension(file.path)}" ?'),
                      actions: [
                        TextButton(
                          child: const Text("YES"),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                        TextButton(
                          child: const Text("NO"),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ],
                    );
                  },
                );
                if (confirm != null && confirm == true) {
                  final s = ref.read(sheetsProvider.notifier);
                  s.del(file.path);
                  final first = s.first;
                  ref.read(currentFileProvider.notifier).state =
                      first == null ? null : File(first);
                  Navigator.pop(context);
                }
              },
            ),
            if (items.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Export'),
                onTap: () async {
                  String defaultDir;
                  if (Platform.isAndroid) {
                    defaultDir = (await getExternalStorageDirectory())!.path;
                  } else {
                    defaultDir =
                        (await getApplicationDocumentsDirectory()).path;
                  }

                  final dest = await showDialog<String>(
                      context: ctx,
                      builder: (context) {
                        String name = '${path.basename(file.path)}';
                        String dir = defaultDir;
                        return AlertDialog(
                          scrollable: true,
                          title: const Text('Export to:'),
                          content: StatefulBuilder(
                            builder: (context, setState) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final p = await FilePicker.platform
                                        .getDirectoryPath();
                                    if (p != null && p != dir)
                                      setState(() => dir = p);
                                  },
                                  child: Text(
                                    "Dir: $dir",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  autofocus: true,
                                  initialValue: name,
                                  onChanged: (v) => setState(() => name = v),
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("CANCEL"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text("OK"),
                              onPressed: () {
                                Navigator.of(context).pop(
                                    name.isEmpty ? null : path.join(dir, name));
                              },
                            ),
                          ],
                        );
                      });
                  if (dest != null) {
                    await File(dest).create(recursive: true);
                    await file.copy(dest);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text('Exported to $dest'),
                      ));
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Import'),
              onTap: () async {
                final src = await FilePicker.platform.pickFiles();
                if (src != null) {
                  final result = await showDialog<List>(
                    context: ctx,
                    barrierDismissible: false,
                    builder: (context) {
                      return FutureBuilder<List>(
                        future: File(src.files.single.path!)
                            .readAsString()
                            .then((data) => BeancountParserDefinition()
                                .build()
                                .parse(data)
                                .value),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return AlertDialog(
                              scrollable: true,
                              contentPadding: EdgeInsets.only(top: 10),
                              content: ParsingError(
                                  snapshot.error as ParserException),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text("OK"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            );
                          } else {
                            if (snapshot.hasData) {
                              Future.delayed(Duration.zero, () {
                                Navigator.pop(context, snapshot.data);
                              });
                            }
                            return SimpleDialog(
                              children: [
                                Center(
                                  child: const SizedBox(
                                    child: CircularProgressIndicator(),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    },
                  );

                  if (result != null && result.isNotEmpty) {
                    ref
                        .read(currentItemsProvider.notifier)
                        .add(result.map((e) => Item(e)));

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text('Imported ${result.length} entries.'),
                      ));
                  }
                }
              },
            ),
          ],
          Divider(),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: const Text('Sheets'),
          ),
          Expanded(
            child: ListView(
              children: ref
                  .read(sheetsProvider)
                  .map((e) => ListTile(
                        title: Text(path.basenameWithoutExtension(e)),
                        onTap: () async {
                          ref.read(currentFileProvider.notifier).state =
                              await ref.read(sheetsProvider.notifier).open(e);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class Parsing extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, ref) {
    final parsing = ref.watch(parsingProvider);

    return parsing.when(
      data: (_) => Items(),
      loading: () => Center(
        child: const SizedBox(
          child: CircularProgressIndicator(),
          width: 60,
          height: 60,
        ),
      ),
      error: (err, stack) =>
          ParsingError(err as ParserException, enableEdit: true),
    );
  }
}

class Items extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showedItems = ref.watch(currentDisplayedItemsProvider).reversed;
    final scrollController = useScrollController();

    return WidgetsVisibilityProvider(
      child: Column(
        children: [
          AccountsStatistics(scrollController),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: showedItems.length,
              itemBuilder: (context, i) => VisibleNotifierWidget(
                data: showedItems.length - i,
                builder: (context, notification, positionData) => ProviderScope(
                  overrides: [
                    _currentItem.overrideWithValue(showedItems.elementAt(i)),
                  ],
                  child: const ItemWidget(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountsStatistics extends HookConsumerWidget {
  final ScrollController scrollController;
  AccountsStatistics(this.scrollController, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(statisticsAccountsProvider);
    final balances = ref.watch(currentDisplayAccountBalancingsProvider);
    final s = ref.read(currentStatisticsProvider);

    return GestureDetector(
      onDoubleTap: () => scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
      child: ListTile(
        leading: const Icon(Icons.equalizer),
        title: const Text('Account statistics'),
        trailing: IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            final v = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(100, 100, 0, 200),
              items: s.accounts
                  .map((e) => PopupMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
            );
            if (v != null && v.isNotEmpty && !accounts.contains(v)) {
              accounts.add(v);
              ref.read(statisticsAccountsProvider.notifier).state =
                  List.from(accounts);
            }
          },
        ),
        subtitle: accounts.isEmpty
            ? null
            : WidgetsVisibilityBuilder(
                buildWhen: (previous, current) =>
                    previous.positionDataList.first.data !=
                    current.positionDataList.first.data,
                builder: (context, event) {
                  final items = ref.read(currentDisplayedItemsProvider);
                  final positions = event.positionDataList;
                  int endIndex = positions.isNotEmpty
                      ? event.positionDataList.first.data
                      : items.length;
                  if (endIndex > items.length) {
                    endIndex = items.length;
                  }

                  final deductItems = items.sublist(endIndex);
                  return Wrap(
                    children: balances.map(
                      (b) {
                        final currencies = b.deduct(deductItems);
                        return Chip(
                          labelPadding: EdgeInsets.only(left: 15),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${b.account}:'),
                              ...currencies
                                  .map((e) => Text(e.toString()))
                                  .toList(),
                            ],
                          ),
                          onDeleted: () {
                            accounts.remove(b.account);
                            ref
                                .read(statisticsAccountsProvider.notifier)
                                .state = List.from(accounts);
                          },
                        );
                      },
                    ).toList(),
                  );
                },
              ),
      ),
    );
  }
}

final _currentItem = Provider<Item>((ref) => Item("uninitialized"));

class ItemWidget extends HookConsumerWidget {
  const ItemWidget({Key? key}) : super(key: key);

  static const _maxLines = 3;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(_currentItem);
    final lines = LineSplitter.split(item.toString()).toList();
    final content = lines.sublist(1).join("\n");
    final needCollapse = lines.length > _maxLines;

    return Dismissible(
      key: ObjectKey(item),
      child: Card(
        child: !needCollapse
            ? ListTile(
                leading: Icon(item.icon),
                // leading: Text(i.toString()),
                title: Text(lines[0]),
                subtitle: content.isEmpty ? null : Text(content),
              )
            : ExpandableNotifier(
                child: ListTile(
                  leading: Icon(item.icon),
                  title: Text(lines[0]),
                  subtitle: Expandable(
                    collapsed: Text(
                      content,
                      maxLines: _maxLines - 1,
                    ),
                    expanded: Text(content),
                  ),
                  trailing: Builder(
                    builder: (context) {
                      final controller = ExpandableController.of(context);
                      if (controller == null) return SizedBox.shrink();
                      return IconButton(
                        icon: Icon(controller.expanded
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: () {
                          controller.toggle();
                        },
                      );
                    },
                  ),
                ),
              ),
      ),
      onDismissed: (direction) {
        final items = ref.read(currentItemsProvider.notifier);
        items.del(item);

        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: const Text('Item removed'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  items.add([item]);
                },
              ),
            ),
          );
      },
    );
  }
}
