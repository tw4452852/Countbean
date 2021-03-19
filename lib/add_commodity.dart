import 'package:flutter/material.dart';

import './add.dart';
import './parser/model.dart';

class CommodityAddWidget extends StatefulWidget {
  final Function(List) onSave;

  @override
  CommodityAddWidget({Key? key, required this.onSave}) : super(key: key);

  @override
  _CommodityAddWidgetState createState() => _CommodityAddWidgetState();
}

class _CommodityAddWidgetState extends State<CommodityAddWidget>
    with FormWithDate, AutomaticKeepAliveClientMixin {
  String? c;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return form(
      onSave: (_) {
        widget.onSave([
          Commodity(
            date: date,
            currency: c!,
          )
        ]);
      },
      children: [
        TextFormFieldWithSuggestion(
          name: 'Commodity',
          autofocus: true,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Commodity is empty";
            }
            return null;
          },
          onSave: (value) {
            c = value.toUpperCase();
          },
        ),
      ],
    );
  }
}
