import 'package:Countbean/providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './parser/model.dart';
import './item.dart';

typedef Filter = bool Function(Item item);

class SearchBarViewDelegate extends SearchDelegate<String> {
  static List<Filter> generateFilters(String s) {
    final List<Filter> ret = [];

    s.split(' ').where((e) => e.isNotEmpty).forEach((e) {
      if (e.startsWith('DateFrom:')) {
        final d = formatter.parse(e.split(':')[1]);
        ret.add((item) {
          return item.date.isAfter(d) || item.date == d;
        });
      } else if (e.startsWith('DateTo')) {
        final d = formatter.parse(e.split(':')[1]);
        ret.add((item) {
          return item.date.isBefore(d) || item.date == d;
        });
      } else {
        ret.add((item) {
          return item.toString().contains(e);
        });
      }
    });
    return ret;
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
      IconButton(
        icon: Icon(Icons.done),
        onPressed: () {
          close(context, query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final statistics = context.read(currentStatisticsProvider);
    final Set<String> allSuggestions = {
      "DateFrom:",
      "DateTo:",
      ...statistics.tags.map((e) => '#$e').toList(),
      ...statistics.links.map((e) => '^$e').toList(),
      ...statistics.accounts,
      ...statistics.eventTypes,
      ...statistics.eventValues,
      ...statistics.payees
    };
    final filters = query.split(' ');
    final last = filters[filters.length - 1];
    final already = filters
        .sublist(0, filters.length - 1)
        .where((e) => e.isNotEmpty)
        .toList();
    Set<String> suggestions = {};

    DateTime dateFrom, dateTo;
    already.forEach((e) {
      if (e.startsWith('DateFrom:')) {
        dateFrom = formatter.parse(e.split(':')[1]);
        allSuggestions.remove('DateFrom:');
      }
      if (e.startsWith('DateTo:')) {
        dateTo = formatter.parse(e.split(':')[1]);
        allSuggestions.remove('DateTo:');
      }
      allSuggestions.remove(e);
    });
    suggestions = allSuggestions.where((e) => e.contains(last)).toSet();

    return ListView(
      children: suggestions
          .map((e) => ListTile(
                title: Text(e),
                onTap: () async {
                  if (e == 'DateFrom:' || e == 'DateTo:') {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                        context: context,
                        firstDate: dateFrom ?? formatter.parse('1988-11-13'),
                        initialDate: dateTo ?? now,
                        lastDate: dateTo ?? now);
                    if (d == null) {
                      return;
                    }
                    e += formatter.format(d);
                  }
                  filters[filters.length - 1] = '$e ';
                  query = filters.join(' ');
                },
              ))
          .toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }
}
