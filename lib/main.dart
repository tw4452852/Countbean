import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expandable/expandable.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:package_info/package_info.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import './parser/parser.dart';
import './parser/widget.dart';
import './statistics.dart';
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
      title: 'Countbean',
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
              child: SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
            ),
        error: (err, stack) => Center(child: Text('Error: $err')));
  }
}

Future<File> createFile(context) async {
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
            decoration: const InputDecoration(labelText: "Name:"),
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
          RaisedButton(
            child: const Text('Create a new sheet'),
            onPressed: () async {
              final f = await createFile(context);

              if (f != null) {
                context.read(currentFileProvider).state = f;
                context.read(sheetsProvider).add(f.path);
              }
            },
          ),
          RaisedButton(
            child: const Text('Import from file'),
            onPressed: () async {
              final f = await FilePicker.getFile();
              final d = await getApplicationDocumentsDirectory();
              if (f != null) {
                final p = path.join(
                    d.path, '${path.basenameWithoutExtension(f.path)}.cb');
                context.read(currentFileProvider).state = await f.copy(p);
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
    final currentFile = useProvider(currentFileProvider);
    return Scaffold(
      appBar: AppBar(
        title: currentFile.state == null
            ? const Text('Home')
            : Text(path.basenameWithoutExtension(currentFile.state.path)),
      ),
      body: currentFile.state == null ? Startup() : Parsing(),
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
              child: SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
            ),
        error: (err, stack) => parserException(err));
  }
}

class Items extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final showedItems = useProvider(currentDisplayedItemsProvider).reversed;

    return ListView.builder(
      itemBuilder: (context, i) => ProviderScope(
        overrides: [
          _currentItem.overrideWithValue(showedItems.elementAt(i)),
        ],
        child: const ItemWidget(),
      ),
    );
  }
}

final _currentItem = ScopedProvider<Item>(null);

class ItemWidget extends HookWidget {
  const ItemWidget({Key key}) : super(key: key);

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
        context.read(currentItemsProvider).del(item);

        Scaffold.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 2),
            content: const Text('Item removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read(currentItemsProvider).add(item);
              },
            ),
          ));
      },
    );
  }
}
