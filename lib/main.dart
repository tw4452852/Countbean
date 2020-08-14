import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:expandable/expandable.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:package_info/package_info.dart';

import './parser/parser.dart';
import './parser/widget.dart';
import './statistics.dart';
import './add.dart';
import './item.dart';
import './search.dart';

Set<String> recent = {};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getRecent();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ValueNotifier<String>>(
          create: (_) => ValueNotifier<String>("")),
    ],
    child: MyApp(),
  ));
}

Future<void> getRecent() async {
  final directory = await getApplicationDocumentsDirectory();

  List<File> l = [];
  directory.listSync().forEach((e) {
    if (e is File && path.extension(e.path) == '.cb') l.add(e);
  });
  l.sort((a, b) => b.lastAccessedSync().compareTo(a.lastAccessedSync()));
  recent = l.map((e) => e.path).toSet();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countbean',
      home: MyHomePage(),
    );
  }
}

bool isTakenAccount(Item item, List<Filter> _filters) {
  if (_filters == null || _filters.isEmpty) {
    return true;
  }
  for (var i = 0; i < _filters.length; i++) {
    if (!_filters[i](item)) {
      return false;
    }
  }
  return true;
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File file;
  List<Item> items;
  final ScrollController scrollController = ScrollController();
  bool isScrolling = false;
  Statistics statistics = Statistics();
  final visiblityThreshold = 0.8;
  Timer _visibleCallbackTimer;
  final _visibleCallbackInterval = const Duration(milliseconds: 20);
  ValueNotifier<List<Item>> visibleItems = ValueNotifier<List<Item>>(null);

  void _visibleCallback() {
    _visibleCallbackTimer = null;
    if (!isScrolling) {
      visibleItems.value =
          items.sublist(0, items.lastIndexWhere((e) => e.isVisible) + 1);
    }
  }

  _updateFile(Iterable entries, {bool isAppend = false}) {
    final sink =
        file.openWrite(mode: isAppend ? FileMode.append : FileMode.write);
    entries.forEach((e) => sink.writeln(e));
    sink.flush().then((_) => sink.close());
  }

  bool _insertItem(Item item) {
    final i = items.lastIndexWhere((e) => !e.date.isAfter(item.date)) + 1;
    items.insert(i, item);
    return i + 1 == items.length;
  }

  @override
  void initState() {
    super.initState();
    file = recent.isNotEmpty ? File(recent.first) : null;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  static const _maxLines = 3;
  Widget _itemWidget(context, item) {
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
        final i = items.indexOf(item);
        setState(() {
          items.removeAt(i);
          statistics.delItems([item.content]);
        });
        Scaffold.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 2),
            content: const Text('Item removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  items.insert(i, item);
                  statistics.addItems([item.content]);
                });
              },
            ),
          )).closed.then((reason) {
            if (reason != SnackBarClosedReason.action) {
              _updateFile(items);
            }
          });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: file == null
            ? const Text('Home')
            : Text(path.basenameWithoutExtension(file.path)),
        flexibleSpace: InkWell(
          onDoubleTap: () {
            scrollController.animateTo(
              0,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          },
        ),
        actions: [
          Consumer<ValueNotifier<String>>(
            builder: (context, searchPattern, _) {
              return Row(
                children: [
                  if (searchPattern.value.isNotEmpty)
                    SizedBox(
                      width: 100,
                      child: Chip(
                        label: Text(
                          searchPattern.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          searchPattern.value = '';
                        },
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final pattern = await showSearch<String>(
                        context: context,
                        delegate: SearchBarViewDelegate(),
                        query: searchPattern.value,
                      );
                      if (pattern != null && pattern != searchPattern.value) {
                        searchPattern.value = pattern;
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData) {
                    final version = snapshot.data.version;
                    final buildNumber = snapshot.data.buildNumber;
                    return Center(
                      child: Text(
                          "Version:$version${buildNumber != null && buildNumber.isNotEmpty ? '+$buildNumber' : ''}"),
                    );
                  } else {
                    return Center(
                      child: SizedBox(
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
                      String input;
                      return AlertDialog(
                        scrollable: true,
                        title: const Text('Create a new sheet'),
                        content: TextField(
                          autofocus: true,
                          decoration: InputDecoration(labelText: "Name:"),
                          onChanged: (v) => input = v,
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: const Text("CANCEL"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          FlatButton(
                            child: const Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop(input);
                            },
                          ),
                        ],
                      );
                    });
                if (name != null && name.isNotEmpty) {
                  final f = File('${directory.path}/$name.cb');
                  await f.create();
                  setState(() {
                    file = f;
                    items = [];
                    recent.add(f.path);
                  });
                  Navigator.pop(context);
                }
              },
            ),
            if (file != null) ...[
              Builder(
                builder: (context) {
                  return ListTile(
                    leading: const Icon(Icons.arrow_downward),
                    title: const Text('Import'),
                    onTap: () async {
                      final src = await FilePicker.getFile();
                      if (src != null) {
                        final result = await showDialog<List>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return FutureBuilder<List>(
                              future: src.readAsString().then((data) =>
                                  BeancountParser().parse(data).value),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return AlertDialog(
                                    scrollable: true,
                                    contentPadding: EdgeInsets.only(top: 10),
                                    content: parserException(snapshot.error),
                                    actions: <Widget>[
                                      FlatButton(
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
                                        child: SizedBox(
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
                          bool isAppend = false;
                          result
                              .forEach((e) => isAppend = _insertItem(Item(e)));
                          statistics.addItems(result);
                          _updateFile(
                            isAppend ? result : items,
                            isAppend: isAppend,
                          );

                          Navigator.pop(context);
                          setState(() {});
                          Scaffold.of(context)
                            ..removeCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              duration: const Duration(seconds: 1),
                              content:
                                  Text('Imported ${result.length} entries.'),
                            ));
                        }
                      }
                    },
                  );
                },
              ),
              if (Platform.isAndroid && items != null && items.isNotEmpty)
                Builder(
                  builder: (context) => ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text('Export'),
                    onTap: () async {
                      final extRoot = await getExternalStorageDirectory();
                      final dest = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            String p = '${path.basename(file.path)}';
                            return AlertDialog(
                              scrollable: true,
                              title: const Text('Export to:'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${extRoot.path}/',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextFormField(
                                    autofocus: true,
                                    initialValue: p,
                                    onChanged: (v) => p = v,
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: const Text("CANCEL"),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                FlatButton(
                                  child: const Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop(p);
                                  },
                                ),
                              ],
                            );
                          });
                      if (dest != null && dest.isNotEmpty) {
                        final p = path.join(extRoot.path, dest);
                        await File(p).create(recursive: true);
                        await file.copy(p);
                        Navigator.pop(context);
                        Scaffold.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            duration: const Duration(seconds: 1),
                            content: const Text('Exported'),
                          ));
                      }
                    },
                  ),
                ),
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
                          FlatButton(
                            child: const Text("YES"),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                          FlatButton(
                            child: const Text("NO"),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm) {
                    file.delete();
                    setState(() {
                      recent.remove(file.path);
                      file = null;
                      items = null;
                    });
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text('Rename'),
                onTap: () async {
                  final cur = path.basenameWithoutExtension(file.path);
                  final name = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        String input;
                        return AlertDialog(
                          scrollable: true,
                          title: const Text('Rename'),
                          content: TextFormField(
                            initialValue: cur,
                            autofocus: true,
                            decoration: InputDecoration(labelText: "Name:"),
                            onChanged: (v) => input = v,
                          ),
                          actions: <Widget>[
                            FlatButton(
                              child: const Text("CANCEL"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            FlatButton(
                              child: const Text("OK"),
                              onPressed: () {
                                Navigator.of(context).pop(input);
                              },
                            ),
                          ],
                        );
                      });
                  if (name != null && name.isNotEmpty) {
                    if (cur != name) {
                      final p = path.join(path.dirname(file.path), "$name.cb");
                      recent.remove(file.path);
                      recent.add(p);
                      file = await file.rename(p);
                      await file.setLastAccessed(DateTime.now());
                      setState(() {});
                    }
                    Navigator.pop(context);
                  }
                },
              ),
            ],
            Divider(),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: const Text('Recent'),
            ),
            Expanded(
              child: ListView(
                children: recent
                    .map((e) => ListTile(
                          title: Text(path.basenameWithoutExtension(e)),
                          onTap: () async {
                            final fi = File(e);
                            await fi.setLastAccessed(DateTime.now());
                            setState(() {
                              file = fi;
                              items = null;
                            });
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      body: file == null
          ? Container()
          : items == null
              ? FutureBuilder<List>(
                  key: ObjectKey(file),
                  future: file
                      .readAsString()
                      .then((data) => BeancountParser().parse(data).value),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return parserException(snapshot.error);
                    } else {
                      if (snapshot.hasData) {
                        final result = snapshot.data;
                        statistics.reset();
                        statistics.addItems(result);
                        items = result.map<Item>((e) => Item(e)).toList();
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => setState(() {}));
                      }

                      return Center(
                        child: SizedBox(
                          child: CircularProgressIndicator(),
                          width: 60,
                          height: 60,
                        ),
                      );
                    }
                  },
                )
              : Column(
                  children: [
                    ChangeNotifierProvider<ValueNotifier<List<Item>>>.value(
                      value: visibleItems,
                      child: StatisticsWidget(),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollEndNotification) {
                            isScrolling = false;
                          }
                          if (scrollNotification is ScrollStartNotification) {
                            isScrolling = true;
                          }
                          return true;
                        },
                        child: Consumer<ValueNotifier<String>>(
                          builder: (context, searchPattern, _) {
                            final filters =
                                SearchBarViewDelegate.generateFilters(
                                    searchPattern.value);
                            return ListView.builder(
                              key: ValueKey(searchPattern.value +
                                  items.hashCode.toString()),
                              itemCount: items.length,
                              controller: scrollController,
                              itemBuilder: (context, i) {
                                final item = items.reversed.elementAt(i);
                                return Visibility(
                                  visible: isTakenAccount(item, filters),
                                  child: VisibilityDetector(
                                    key: ObjectKey(item),
                                    onVisibilityChanged: (vi) {
                                      _visibleCallbackTimer?.cancel();
                                      _visibleCallbackTimer = Timer(
                                          _visibleCallbackInterval,
                                          _visibleCallback);
                                      item.isVisible = vi.visibleFraction >
                                              visiblityThreshold
                                          ? true
                                          : false;
                                    },
                                    child: _itemWidget(context, item),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: file == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final List result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWidget(),
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  bool isAppend = false;
                  result.forEach((e) => isAppend = _insertItem(Item(e)));
                  setState(() {});
                  statistics.addItems(result);
                  _updateFile(
                    isAppend ? result : items,
                    isAppend: isAppend,
                  );
                }
              },
              child: const Icon(Icons.create),
            ),
    );
  }
}

class StatisticsWidget extends StatefulWidget {
  @override
  StatisticsWidget({Key key}) : super(key: key);

  @override
  _StatisticsWidgetState createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  final statistics = Statistics();
  Set<String> statisticAccounts = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return statistics.accounts.isNotEmpty
        ? ListTile(
            leading: const Icon(Icons.equalizer),
            title: const Text('Account statistics'),
            trailing: IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                final v = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(100, 100, 0, 200),
                  items: statistics.accounts
                      .map((e) => PopupMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                );
                if (v != null &&
                    v.isNotEmpty &&
                    !statisticAccounts.contains(v)) {
                  setState(() {
                    statisticAccounts.add(v);
                  });
                }
              },
            ),
            subtitle: statisticAccounts.isEmpty
                ? null
                : Consumer2<ValueNotifier<String>, ValueNotifier<List<Item>>>(
                    builder: (context, searchPattern, visibleItems, _) {
                      final filters = SearchBarViewDelegate.generateFilters(
                          searchPattern.value);
                      final validItems = visibleItems.value
                          .where((e) => isTakenAccount(e, filters))
                          .map((e) => e.content);

                      return Wrap(
                        children: statisticAccounts.map((a) {
                          final balance = statistics.balance(a, validItems);
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
                              setState(() {
                                statisticAccounts.remove(a);
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
          )
        : SizedBox.shrink();
  }
}