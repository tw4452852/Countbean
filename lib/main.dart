import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expandable/expandable.dart';
import 'package:package_info/package_info.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:widgets_visibility_provider/widgets_visibility_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ext_storage/ext_storage.dart';
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

class MyHomePage extends HookWidget {
  @override
  Widget build(context) {
    final loading = useProvider(loadingProvider);
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
  final directory = await getApplicationDocumentsDirectory();
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

class Startup extends HookWidget {
  @override
  Widget build(context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            child: const Text('Create a empty sheet'),
            onPressed: () async {
              final f = await createFile(context);

              if (f != null) {
                context.read(currentFileProvider).state = f;
                context.read(sheetsProvider).add(f.path);
              }
            },
          ),
          ElevatedButton(
            child: const Text('Import from file'),
            onPressed: () async {
              final f = await FilePicker.platform.pickFiles();
              final d = await getApplicationDocumentsDirectory();
              if (f != null) {
                final filePath = f.files.first.path;
                if (filePath == null) return null;
                final p = path.join(
                    d.path, '${path.basenameWithoutExtension(filePath)}.cb');
                context.read(currentFileProvider).state =
                    await File(filePath).copy(p);
                context.read(sheetsProvider).add(p);
              }
            },
          ),
        ],
      ),
    );
  }
}

class Home extends HookWidget {
  @override
  Widget build(context) {
    final currentFile = useProvider(currentFileProvider).state;
    final parsing = useProvider(parsingProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentFile == null
            ? const Text('Home')
            : Text(path.basenameWithoutExtension(currentFile.path)),
        actions: [
          Consumer(
            builder: (context, watch, child) {
              final searchPattern = watch(searchPatternProvider);
              return Row(
                children: [
                  if (searchPattern.state.isNotEmpty)
                    SizedBox(
                      width: 100,
                      child: Chip(
                        label: Text(
                          searchPattern.state,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          searchPattern.state = '';
                        },
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final pattern = await showSearch<String?>(
                        context: context,
                        delegate: SearchBarViewDelegate(),
                        query: searchPattern.state,
                      );
                      if (pattern != null && pattern != searchPattern.state) {
                        searchPattern.state = pattern;
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
                    context
                        .read(currentItemsProvider)
                        .add(result.map((e) => Item(e)));
                  }
                },
                child: const Icon(Icons.create),
              ),
            ),
    );
  }
}

class MyDrawer extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final file = context.read(currentFileProvider).state;
    final items = context.read(currentItemsProvider.state);
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
              final directory = await getApplicationDocumentsDirectory();
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
                context.read(currentFileProvider).state = await context
                    .read(sheetsProvider)
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
                  final s = context.read(sheetsProvider);
                  s.del(file.path);
                  final first = s.first;
                  context.read(currentFileProvider).state =
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
                    final permission = await Permission.storage.request();
                    if (!permission.isGranted) {
                      return;
                    }
                    defaultDir = path.join(
                      (await ExtStorage.getExternalStorageDirectory())!,
                      'cb',
                    );
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
                            .then(
                                (data) => BeancountParser().parse(data).value),
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
                    context
                        .read(currentItemsProvider)
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
              children: context
                  .read(sheetsProvider.state)
                  .map((e) => ListTile(
                        title: Text(path.basenameWithoutExtension(e)),
                        onTap: () async {
                          context.read(currentFileProvider).state =
                              await context.read(sheetsProvider).open(e);
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

class Parsing extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final parsing = useProvider(parsingProvider);

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

class Items extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final showedItems = useProvider(currentDisplayedItemsProvider)!.reversed;
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

class AccountsStatistics extends HookWidget {
  final ScrollController scrollController;
  AccountsStatistics(this.scrollController, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final accounts = useProvider(statisticsAccountsProvider);
    final items = useProvider(currentDisplayedItemsProvider);
    final s = context.read(currentStatisticsProvider);

    if (items == null) return SizedBox.shrink();

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
            if (v != null && v.isNotEmpty && !accounts.state.contains(v)) {
              accounts.state.add(v);
              accounts.state = List.from(accounts.state);
            }
          },
        ),
        subtitle: accounts.state.isEmpty
            ? null
            : WidgetsVisibilityBuilder(
                buildWhen: (previous, current) => !listEquals(
                    previous.positionDataList.map((e) => e.data).toList(),
                    current.positionDataList.map((e) => e.data).toList()),
                builder: (context, event) {
                  final positions = event.positionDataList;
                  int endIndex = positions.isNotEmpty
                      ? event.positionDataList.first.data
                      : items.length;
                  if (endIndex > items.length) {
                    endIndex = items.length;
                  }

                  final validItems = items.sublist(0, endIndex);
                  return Wrap(
                    children: accounts.state.map(
                      (a) {
                        final balance = s.balance(a, validItems);
                        return Chip(
                          labelPadding: EdgeInsets.only(left: 15),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$a:'),
                              ...balance
                                  .map((e) => Text(e.toString()))
                                  .toList(),
                            ],
                          ),
                          onDeleted: () {
                            accounts.state.remove(a);
                            accounts.state = List.from(accounts.state);
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

final _currentItem = ScopedProvider<Item>(null);

class ItemWidget extends HookWidget {
  const ItemWidget({Key? key}) : super(key: key);

  static const _maxLines = 3;
  @override
  Widget build(BuildContext context) {
    final item = useProvider(_currentItem);
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
        final items = context.read(currentItemsProvider);
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
