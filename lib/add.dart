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
    List? items;
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
                final currentState = keys[i].currentState;
                if (currentState != null && currentState.validate()) {
                  currentState.save();
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
  late DateTime date;
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
    required List<Widget> children,
    FormFieldSetter? onSave,
    FormFieldValidator? validator,
    bool withDate = true,
  }) =>
      FormField(
        onSaved: (_) {
          _formKey.currentState?.save();
          if (onSave != null) {
            onSave(_);
          }
        },
        validator: (_) {
          final currentState = _formKey.currentState;
          if (currentState != null) {
            if (currentState.validate()) {
              if (validator != null) {
                return validator(_);
              }
              return null;
            }
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
  final String name;
  final String initialValue;
  final List<String>? suggestions;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter? onSave;
  final InputDecoration inputDecoration;
  final TextEditingController? controller;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final bool goUp;

  @override
  TextFormFieldWithSuggestion({
    Key? key,
    required this.name,
    this.suggestions,
    this.validator,
    this.onSave,
    String? initialValue,
    this.controller,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    InputDecoration? inputDecoration,
    this.goUp = false,
  })  : inputDecoration = inputDecoration ?? InputDecoration(labelText: name),
        initialValue = initialValue ?? "",
        super(key: key);

  @override
  Widget build(BuildContext context) {
    controller?.text = initialValue;
    final texteditingController =
        controller ?? useTextEditingController(text: initialValue);

    return TypeAheadFormField<String?>(
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
        final suggestions = this.suggestions;
        return suggestions == null
            ? Iterable.empty()
            : suggestions
                .where((e) => e.toLowerCase().contains(pattern.toLowerCase()));
      },
      onSuggestionSelected: (suggestion) {
        texteditingController.text = suggestion!;
        FocusScope.of(context).nextFocus();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion!),
        );
      },
      direction: goUp ? AxisDirection.up : AxisDirection.down,
    );
  }
}

class Chips extends HookWidget {
  final String name;
  final List<String> suggestions;
  final List<String>? result;

  Chips({
    Key? key,
    required this.name,
    this.suggestions = const [],
    this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chips = useState<Set<String>>({});
    useValueChanged<Set<String>, Null>(chips.value, (_, __) {
      if (result != null) {
        result!.replaceRange(0, result!.length, chips.value);
      }
    });

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide()),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Text("$name:"),
        title: chips.value.isEmpty
            ? const Text('')
            : Wrap(
                children: chips.value
                    .map((e) => Chip(
                        label: Text(e),
                        onDeleted: () {
                          chips.value.remove(e);
                          chips.value = Set.from(chips.value);
                        }))
                    .toList(),
              ),
        subtitle: suggestions.isEmpty
            ? null
            : Wrap(
                children: suggestions
                    .map((e) => ActionChip(
                          label: Text(e),
                          onPressed: () {
                            chips.value.add(e);
                            chips.value = Set.from(chips.value);
                          },
                        ))
                    .toList(),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final c = await showDialog<String>(
              context: context,
              builder: (context) {
                String? input;
                return AlertDialog(
                  scrollable: true,
                  title: Text('Create a new $name'),
                  content: TextField(
                    autofocus: true,
                    onChanged: (v) => input = v,
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("CANCEL"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop(input ??= "");
                      },
                    ),
                  ],
                );
              },
            );
            if (c != null && name.isNotEmpty) {
              chips.value.add(c);
              chips.value = Set.from(chips.value);
            }
          },
        ),
      ),
    );
  }
}

typedef OnSave = void Function(String value);

class TextWithModal extends HookWidget {
  final String name;
  final List<String> suggestions;
  final OnSave onsave;

  TextWithModal({
    Key? key,
    required this.name,
    required this.onsave,
    this.suggestions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = useState<String>('');
    final focusNode = useFocusNode();

    return TextButton(
      focusNode: focusNode,
      onPressed: () async {
        focusNode.requestFocus();
        final value = await showModalBottomSheet<String>(
          context: context,
          builder: (BuildContext context) {
            return ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text("${suggestions[index]}"),
                    onTap: () => Navigator.of(context).pop(suggestions[index]),
                  );
                });
          },
        );
        if (value != null && value != result.value) {
          result.value = value;
          onsave(value);
          FocusScope.of(context).nextFocus();
        }
      },
      child: result.value.isEmpty ? Text('<$name>') : Text('${result.value}'),
    );
  }
}
