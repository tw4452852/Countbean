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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './parser/parser.dart';
import './parser/widget.dart';
import './statistics.dart';
import './add.dart';
import './item.dart';
import './search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

Future<List<String>> loadSheets() async {
  final directory = await getApplicationDocumentsDirectory();

  List<File> l = [];
  directory.listSync().forEach((e) {
    if (e is File && path.extension(e.path) == '.cb') l.add(e);
  });
  l.sort((a, b) => b.lastAccessedSync().compareTo(a.lastAccessedSync()));
  return l.map((e) => e.path).toList();
}

final sheetsProvider = StateNotifierProvider<Sheets>((ref) => Sheets());

final currentFileProvider = StateProvider<File>((ref) => null);

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

class MyHomePage extends StatelessWidget {
  @override
  Widget build(context) {
    return FutureBuilder(
        future: loadSheets(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              ),
            );
          }

          final l = snapshot.data;
          if (l.isNotEmpty) {
            context.read(sheetsProvider).reset(l);
            context.read(currentFileProvider).state = File(l.first);
          }
          return Home();
        });
  }
}

Future<File> create(context) async {
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
    final f = File('${directory.path}/$name.cb');
    await f.create();
    return f;
  }

  return null;
}

class Startup extends StatelessWidget {
  @override
  Widget build(context) {
    return Center(
      child: FlatButton(
        child: const Text('Create a new sheet'),
        onPressed: () async {
          final f = await create(context);
          if (f != null) {
            context.read(currentFileProvider).state = f;
          }
        },
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, watch, _) {
            final currentFile = watch(currentFileProvider);
            return currentFile.state == null
                ? const Text('Home')
                : Text(path.basenameWithoutExtension(currentFile.state.path));
          },
        ),
      ),
    );
  }
}
