import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:petitparser/petitparser.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers.dart';

class ParsingError extends HookWidget {
  final ParserException exception;
  final bool enableEdit;

  ParsingError(this.exception, {Key? key, this.enableEdit = false})
      : super(key: key);

  static List<int> getContextRange(String buf, int position) {
    late int beginPos, endPos;

    final lc = Token.lineAndColumnOf(buf, position);
    final c = lc[1];
    final l = lc[0] - 1;
    List<String> lines = LineSplitter.split(buf).toList();

    final beginLine = l - 2 < 0 ? 0 : l - 2;
    beginPos = beginLine == 0
        ? 0
        : position - c - lines[l - 1].length - 1 - lines[l - 2].length;
    final endLine = l + 2 > lines.length ? lines.length : l + 2;
    endPos = endLine == lines.length
        ? buf.length
        : position + (lines[l].length - c + 1) + lines[l + 1].length + 1;

    return [beginPos, endPos, position - beginPos];
  }

  @override
  Widget build(context) {
    final controller = useTextEditingController();
    final isEditing = useState(false);
    final range = useMemoized(
        () => getContextRange(
            exception.failure.buffer, exception.failure.position),
        [exception]);
    final begin = range[0];
    final end = range[1];
    final position = range[2];
    final f = exception.failure;
    final buf = f.buffer.substring(begin, end);
    List<String> lines = LineSplitter.split(buf).toList();
    final lc = Token.lineAndColumnOf(buf, position);
    final l = lc[0];
    final c = lc[1];

    controller
      ..text = buf
      ..selection = TextSelection.collapsed(offset: position);

    return ListTile(
      leading: const Icon(Icons.error, color: Colors.red),
      title: Text(
        "Parsing error:${f.message}",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      trailing: !enableEdit
          ? null
          : isEditing.value
              ? IconButton(
                  icon: const Icon(Icons.done),
                  onPressed: () async {
                    final cur = context.read(currentFileProvider).state;
                    if (cur != null) {
                      context.read(currentFileProvider).state =
                          await File(cur.path).writeAsString(f.buffer
                              .replaceRange(begin, end, controller.text));
                    }
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    isEditing.value = true;
                  },
                ),
      subtitle: isEditing.value
          ? TextField(
              autofocus: true,
              controller: controller,
              maxLines: null,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  i == l - 1
                      ? RichText(
                          text: TextSpan(
                            text: '${lines[i].substring(0, c - 1)}',
                            style: TextStyle(
                              backgroundColor: Colors.green.withOpacity(0.5),
                            ),
                            children: [
                              TextSpan(
                                text: lines[i][c - 1],
                                style: TextStyle(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                              if (c < lines[i].length)
                                TextSpan(
                                  text: lines[i].substring(c),
                                ),
                            ],
                          ),
                        )
                      : Text('${lines[i]}'),
              ],
            ),
    );
  }
}
