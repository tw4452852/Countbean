import 'package:countbean/providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:chips_input/chips_input.dart';

import './add.dart';
import './parser/model.dart';

class AccountAddWidget extends StatefulWidget {
  final Function(List) onSave;

  @override
  AccountAddWidget({Key key, @required this.onSave}) : super(key: key);

  @override
  _AccountAddWidgetState createState() => _AccountAddWidgetState();
}

class _AccountAddWidgetState extends State<AccountAddWidget>
    with FormWithDate, AutomaticKeepAliveClientMixin {
  String action = "open", account;
  List<String> cs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final s = context.read(currentStatisticsProvider);
    final currencies = s.currencies.toList();
    final accounts = s.accounts.toList();
    return form(
      onSave: (_) {
        widget.onSave([
          AccountAction(
            date: date,
            action: action,
            account: account,
            currencies: cs,
          )
        ]);
      },
      children: [
        TextFormFieldWithSuggestion(
          initialValue: action,
          name: 'Action',
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Action is empty";
            }
            if (v != "close" && v != "open") {
              return 'Action must be "open" or "close"';
            }
            return null;
          },
          suggestions: ["open", "close"],
          onSave: (value) {
            action = value;
          },
        ),
        TextFormFieldWithSuggestion(
          autofocus: true,
          name: 'Account',
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Account is empty";
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
          onSave: (value) {
            account = value;
          },
          suggestions: accounts,
        ),
        ChipsInput<String>(
          decoration: InputDecoration(
            labelText: 'Currencies',
          ),
          findSuggestions: (String query) {
            final suggestions =
                currencies.where((e) => e.contains(query)).toList();
            if (query != null && query.isNotEmpty) {
              suggestions.add(query.toUpperCase());
            }
            return suggestions;
          },
          suggestionBuilder: (context, currency) {
            return ListTile(
              title: Text(currency),
            );
          },
          chipBuilder: (context, state, currency) {
            return InputChip(
              label: Text(currency),
              onDeleted: () => state.deleteChip(currency),
            );
          },
          onChanged: (l) => cs = l,
        ),
      ],
    );
  }
}
