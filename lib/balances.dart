import 'package:countbean/parser/model.dart';
import 'package:countbean/item.dart';
import 'package:countbean/statistics.dart';

class Balances {
  String account = "unknown";
  Map<String, Cost> items = {};

  Balances(String account, Iterable<Cost> currencies) {
    this.account = account;
    this.items =
        Map.fromIterable(currencies, key: (c) => c.currency, value: (c) => c);
  }

  Iterable<Cost> deduct(Iterable<Item> items) {
    final ret = Map.of(this.items);
    for (var i = 0; i < items.length; i++) {
      final e = items.elementAt(i).content;

      if (e is Transaction) {
        final fillCost = Statistics.computeCosts(e.postings);
        e.postings?.forEach((p) {
          if (p.account == account) {
            final Cost cost = p.cost ?? fillCost!;
            ret.update(cost.currency, (v) => v - cost);
          }
        });
      }

      if (e is Pad) {
        final c = e.cost;
        if (c != null) {
          ret.update(
            c.currency,
            (v) {
              if (e.account == account) return v - c;
              if (e.padAccount == account) return v + c;
              return v;
            },
          );
        }
      }
    }
    return ret.entries.map((e) => e.value);
  }
}
