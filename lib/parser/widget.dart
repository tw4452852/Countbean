import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:petitparser/petitparser.dart';

Widget parserException(ParserException e) {
  final f = e.failure;
  final i = f.position;
  final lc = Token.lineAndColumnOf(f.buffer, i);
  final c = lc[1];
  final l = lc[0] - 1;
  List<String> lines = LineSplitter.split(f.buffer).toList();

  return ListTile(
    leading: const Icon(Icons.error, color: Colors.red),
    title: const Text('Parsing error:'),
    subtitle: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = l - 2 < 0 ? 0 : l - 2;
            i < (l + 2 > lines.length ? lines.length : l + 2);
            i++)
          i == l
              ? RichText(
                  text: TextSpan(
                    text: '${i + 1}:${lines[i].substring(0, c - 1)}',
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
              : Text('${i + 1}:${lines[i]}'),
        Text(
          e.toString(),
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      ],
    ),
  );
}
