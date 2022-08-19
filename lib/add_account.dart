import 'package:countbean/providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './add.dart';
import './parser/model.dart';

class AccountAddWidget extends ConsumerStatefulWidget {
  final Function(List) onSave;

  @override
  AccountAddWidget({Key? key, required this.onSave}) : super(key: key);

  @override
  _AccountAddWidgetState createState() => _AccountAddWidgetState();
}

class _AccountAddWidgetState extends ConsumerState<AccountAddWidget>
    with FormWithDate, AutomaticKeepAliveClientMixin {
  String action = "open";
  String? account;
  List<String> cs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final s = ref.read(currentStatisticsProvider);
    final currencies = s.currencies.toList();
    final accounts = s.accounts.toList();
    return form(
      onSave: (_) {
        widget.onSave([
          AccountAction(
            date: date,
            action: action,
            account: account!,
            currencies: cs,
          )
        ]);
      },
      children: [
        Row(
          children: [
            TextWithModal(
              name: "Action",
              suggestions: ["open", "close"],
              onsave: (v) {
                action = v;
              },
            ),
            Expanded(
              child: TextFormFieldWithSuggestion(
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
            ),
          ],
        ),
        Chips(
          name: 'Currency',
          suggestions: currencies,
          result: cs,
        ),
      ],
    );
  }
}
