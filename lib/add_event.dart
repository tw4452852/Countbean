import 'package:Countbean/providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './parser/model.dart';
import './add.dart';


class EventAddWidget extends StatefulWidget {
  final Function(List) onSave;

  @override
  EventAddWidget({Key key, @required this.onSave}) : super(key: key);

  @override
  _EventAddWidgetState createState() => _EventAddWidgetState();
}

class _EventAddWidgetState extends State<EventAddWidget>
    with FormWithDate, AutomaticKeepAliveClientMixin {
  String k, v = "";

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

  final s = context.read(currentStatisticsProvider);
    final types = s.eventTypes.toList();
    final values = s.eventValues.toList();
    return form(
      onSave: (_) {
        widget.onSave([
          Event(
            date: date,
            key: k,
            value: v,
          )
        ]);
      },
      children: [
        TextFormFieldWithSuggestion(
          name: 'Type',
          autofocus: true,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Type is empty";
            }
            return null;
          },
          suggestions: types,
          onSave: (value) {
            k = value;
          },
        ),
        TextFormFieldWithSuggestion(
          name: 'Value',
          suggestions: values,
          onSave: (value) {
            v = value;
          },
        ),
      ],
    );
  }
}
