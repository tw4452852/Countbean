import 'package:countbean/providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './add.dart';
import './parser/model.dart';

class BalanceAddWidget extends ConsumerStatefulWidget {
  final Function(List) onSave;

  @override
  BalanceAddWidget({Key? key, required this.onSave}) : super(key: key);

  @override
  _BalanceAddWidgetState createState() => _BalanceAddWidgetState();
}

class _BalanceAddWidgetState extends ConsumerState<BalanceAddWidget>
    with FormWithDate, AutomaticKeepAliveClientMixin {
  String? account, currency;
  double? amount;
  bool withPad = false;
  String? padAccount;

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
          if (withPad)
            Pad(
              date: date.subtract(const Duration(days: 1)),
              account: account!,
              padAccount: padAccount!,
            ),
          Balance(
            date: date,
            account: account!,
            cost: Cost(
              amount: amount!,
              currency: currency!,
            ),
          ),
        ]);
      },
      children: [
        TextFormFieldWithSuggestion(
          name: "Account",
          autofocus: true,
          suggestions: accounts,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Account is empty";
            }
            return null;
          },
          onSave: (v) {
            account = v;
          },
        ),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Amount",
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Amount is empty";
            }

            if (double.tryParse(v) == null) {
              return "Invalid Amount";
            }

            return null;
          },
          onSaved: (v) {
            if (v != null) amount = double.parse(v);
          },
        ),
        TextFormFieldWithSuggestion(
          name: 'Currency',
          initialValue: currencies.isEmpty ? "" : currencies.first,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return "Currency is empty";
            }
            return null;
          },
          suggestions: currencies,
          onSave: (v) {
            currency = v;
          },
        ),
        Row(
          children: [
            Checkbox(
              value: withPad,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    withPad = v;
                  });
                }
              },
            ),
            const Text('Insert pad'),
          ],
        ),
        Visibility(
          visible: withPad,
          child: TextFormFieldWithSuggestion(
            name: "Pad Account",
            goUp: true,
            suggestions: accounts,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Pad Account is empty";
              }
              return null;
            },
            onSave: (v) {
              padAccount = v;
            },
          ),
        ),
      ],
    );
  }
}
