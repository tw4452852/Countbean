import 'package:flutter/material.dart';

import './add.dart';

class OptionAddWidget extends StatefulWidget {
  final Function(dynamic) onSave;

  @override
  OptionAddWidget({Key key, @required this.onSave}) : super(key: key);

  @override
  _OptionAddWidgetState createState() => _OptionAddWidgetState();
}

class _OptionAddWidgetState extends State<OptionAddWidget> with FormWithDate {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
