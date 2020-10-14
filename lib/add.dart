import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import './parser/model.dart';
import './item.dart';
import './add_balance.dart';
import './add_transaction.dart';
import './add_event.dart';
import './add_account.dart';
import './add_commodity.dart';

class AddWidget extends HookWidget {
  final List<String> types = const [
    "Transaction",
    "Balance",
    "Event",
    "AccountAction",
    "Commodity",
  ];
  final List<IconData> icons = const [
    Item.TransactionIcon,
    Item.BalanceIcon,
    Item.EventIcon,
    Item.AccountActionIcon,
    Item.CommodityIcon,
  ];
  final List<GlobalKey<FormState>> keys =
      List.generate(5, (_) => GlobalKey<FormState>(), growable: false);

  @override
  Widget build(BuildContext context) {
    List items;
    final tabController = useTabController(initialLength: types.length);

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add'),
          bottom: TabBar(
            controller: tabController,
            isScrollable: true,
            tabs: [
              for (var i = 0; i < types.length; i++)
                Tab(
                  icon: Icon(icons[i]),
                  text: types[i],
                ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.done),
              onPressed: () {
                final i = tabController.index;
                if (keys[i].currentState.validate()) {
                  keys[i].currentState.save();
                  Navigator.of(context).pop(items);
                }
              },
            ),
          ],
        ),
        body: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
          ),
          child: TabBarView(
            controller: tabController,
            children: [
              Form(
                key: keys[0],
                child: TransactionAddWidget(
                  onSave: (l) => items = l,
                ),
              ),
              Form(
                key: keys[1],
                child: BalanceAddWidget(
                  onSave: (l) => items = l,
                ),
              ),
              Form(
                key: keys[2],
                child: EventAddWidget(
                  onSave: (l) => items = l,
                ),
              ),
              Form(
                key: keys[3],
                child: AccountAddWidget(
                  onSave: (l) => items = l,
                ),
              ),
              Form(
                key: keys[4],
                child: CommodityAddWidget(
                  onSave: (l) => items = l,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

mixin FormWithDate<T extends StatefulWidget> on State<T> {
  DateTime date;
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    date = DateTime.now();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Widget form({
    @required List<Widget> children,
    FormFieldSetter onSave,
    FormFieldValidator validator,
    bool withDate = true,
  }) =>
      FormField(
        onSaved: (_) {
          _formKey.currentState.save();
          if (onSave != null) {
            onSave(_);
          }
        },
        validator: (_) {
          if (_formKey.currentState.validate()) {
            if (validator != null) {
              return validator(_);
            }
            return null;
          }
          return "Validate failed";
        },
        builder: (state) {
          return Form(
            key: _formKey,
            child: FocusScope(
              child: Column(
                children: [
                  if (withDate)
                    TextFormFieldWithSuggestion(
                      name: 'Date',
                      initialValue: formatter.format(date),
                      controller: _dateController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Type is empty";
                        }
                        if (DateTime.tryParse(v) == null) {
                          return "Invalid date format";
                        }
                        return null;
                      },
                      onSave: (v) {
                        date = DateTime.parse(v);
                      },
                      inputDecoration: InputDecoration(
                        enabled: false,
                        labelText: 'Date',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.date_range),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: date.subtract(
                                Duration(days: 365),
                              ),
                              initialDate: date,
                              lastDate: date.add(
                                Duration(days: 365),
                              ),
                            );
                            if (d != null && d != date) {
                              _dateController.text = formatter.format(d);
                            }
                          },
                        ),
                      ),
                    ),
                  ...children,
                ],
              ),
            ),
          );
        },
      );
}

class TextFormFieldWithSuggestion extends HookWidget {
  final String name, initialValue;
  final List<String> suggestions;
  final FormFieldValidator<String> validator;
  final FormFieldSetter onSave;
  final InputDecoration inputDecoration;
  final TextEditingController controller;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  TextFormFieldWithSuggestion({
    Key key,
    @required this.name,
    this.suggestions,
    this.validator,
    this.onSave,
    this.initialValue,
    this.controller,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    InputDecoration inputDecoration,
  })  : inputDecoration = inputDecoration ?? InputDecoration(labelText: name),
        super(key: key);


  @override
  Widget build(BuildContext context) {
    controller?.text = initialValue;
    final texteditingController = controller ?? useTextEditingController(text: initialValue);

    return TypeAheadFormField<String>(
      keepSuggestionsOnSuggestionSelected: true,
      autoFlipDirection: true,
      hideOnEmpty: true,
      hideOnError: true,
      hideOnLoading: true,
      validator: validator,
      onSaved: onSave,
      textFieldConfiguration: TextFieldConfiguration(
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          controller: texteditingController,
          decoration: inputDecoration,
          onEditingComplete: () {
            FocusScope.of(context).nextFocus();
          }),
      suggestionsCallback: (pattern) {
        return suggestions.where((e) => e.contains(pattern));
      },
      onSuggestionSelected: (suggestion) {
        texteditingController.text = suggestion;
        FocusScope.of(context).nextFocus();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
    );
  }
}
