import 'package:countbean/providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:chips_input/chips_input.dart';

import './parser/model.dart';
import './add.dart';
import './providers.dart';

class TransactionAddWidget extends StatefulWidget {
  final Function(List) onSave;

  @override
  TransactionAddWidget({Key key, @required this.onSave}) : super(key: key);

  @override
  _TransactionAddWidgetState createState() => _TransactionAddWidgetState();
}

class _TransactionAddWidgetState extends State<TransactionAddWidget>
    with FormWithDate, AutomaticKeepAliveClientMixin {
  String desc, payee, currency;
  List<List> froms = [[]..length = 2];
  List<List> tos = [[]..length = 2];
  List<String> ts = [];
  List<String> ls = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.read(currentStatisticsProvider);
    final payees = s.payees.toList();
    final accounts = s.accounts.toList();
    final tags = s.tags;
    final links = s.links;
    final currencies = s.currencies.toList();

    return SingleChildScrollView(
      child: form(
        onSave: (_) {
          List<Posting> postings = [];
          [...froms, ...tos].forEach((e) {
            postings.add(Posting(
                account: e[0],
                cost: e[1] == null
                    ? null
                    : Cost(
                        amount: e[1],
                        currency: currency,
                      )));
          });

          widget.onSave([
            Transaction(
              date: date,
              payee: payee,
              comment: desc,
              postings: postings,
              tags: ts,
              links: ls,
            )
          ]);
        },
        validator: (_) {
          num empty = 0, f = 0, t = 0;
          [froms, tos].forEach((l) {
            l.forEach((e) {
              if (e[1] == null) {
                empty++;
              } else if (l == froms) {
                f += e[1];
              } else {
                t += e[1];
              }
            });
          });

          if (empty > 1) {
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(SnackBar(
                duration: Duration(seconds: 1),
                content: const Text('More than one Account fields are empty!'),
              ));
            return "";
          }

          if (empty == 0 && f + t != 0) {
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(SnackBar(
                duration: Duration(seconds: 1),
                content: const Text('Accounts total is not 0!'),
              ));
            return "";
          }

          return null;
        },
        children: [
          TextFormFieldWithSuggestion(
            name: 'Payee',
            suggestions: payees,
            autofocus: true,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Payee is empty";
              }
              return null;
            },
            onSave: (v) {
              payee = v;
            },
          ),
          TextFormFieldWithSuggestion(
            name: 'Description',
            onSave: (v) {
              desc = v;
            },
          ),
          TextFormFieldWithSuggestion(
            name: 'Currency',
            initialValue: currencies.isEmpty ? null : currencies.first,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return "Currency is empty";
              }
              return null;
            },
            suggestions: currencies,
            onSave: (v) {
              currency = v.toUpperCase();
            },
          ),
          SizedBox(height: 10),
          Builder(
            builder: (context) => ChipsInput<String>(
              decoration: InputDecoration(
                labelText: 'Tags',
              ),
              onEditingComplete: () {
                FocusScope.of(context).nextFocus();
              },
              findSuggestions: (String query) {
                final suggestions =
                    tags.where((e) => e.contains(query)).toList();
                if (query != null && query.isNotEmpty) {
                  suggestions.add(query);
                }
                return suggestions;
              },
              suggestionBuilder: (context, tag) {
                return ListTile(
                  title: Text(tag),
                );
              },
              chipBuilder: (context, state, tag) {
                return InputChip(
                  label: Text('#$tag'),
                  onDeleted: () => state.deleteChip(tag),
                );
              },
              onChanged: (l) => ts = l,
            ),
          ),
          SizedBox(height: 10),
          Builder(
            builder: (context) => ChipsInput<String>(
              decoration: InputDecoration(
                labelText: 'Links',
              ),
              onEditingComplete: () {
                FocusScope.of(context).nextFocus();
              },
              findSuggestions: (String query) {
                final suggestions =
                    links.where((e) => e.contains(query)).toList();
                if (query != null && query.isNotEmpty) {
                  suggestions.add(query);
                }
                return suggestions;
              },
              suggestionBuilder: (context, link) {
                return ListTile(
                  title: Text(link),
                );
              },
              chipBuilder: (context, state, link) {
                return InputChip(
                  label: Text('^$link'),
                  onDeleted: () => state.deleteChip(link),
                );
              },
              onChanged: (l) => ls = l,
            ),
          ),
          for (var l in [froms, tos]) ...[
            for (var i = 0; i < l.length; i++)
              Row(
                children: [
                  SizedBox(
                    width: 45,
                    child: l == froms ? const Text('From:') : const Text('To:'),
                  ),
                  Expanded(
                    child: TextFormFieldWithSuggestion(
                      name: "Account",
                      inputDecoration: InputDecoration(
                        labelText: 'Account',
                      ),
                      textCapitalization: TextCapitalization.words,
                      suggestions: accounts,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Account is empty";
                        }
                        l[i][0] = v;
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 5),
                  SizedBox(
                    width: 100,
                    child: Builder(
                      builder: (context) => TextFormField(
                        onEditingComplete: () {
                          FocusScope.of(context).nextFocus();
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Amount",
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (v) {
                          // allow empty
                          if (v == null || v.isEmpty) {
                            l[i][1] = null;
                            return null;
                          }

                          final amount = double.tryParse(v);
                          if (amount == null) {
                            return "Invalid Amount";
                          }
                          l[i][1] = l == froms ? -amount : amount;

                          return null;
                        },
                      ),
                    ),
                  ),
                  i == 0
                      ? IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              l.add([]..length = 2);
                            });
                          },
                        )
                      : IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              l.removeAt(i);
                            });
                          },
                        ),
                ],
              ),
            SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
