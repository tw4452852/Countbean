import 'package:collection/collection.dart';
import './parser/model.dart';
import './item.dart';

class Statistics {
  List<Transaction> _transactions = [];
  List<Pad> _pads = [];
  Set<String> accounts = {};
  Set<String> payees = {};
  Set<String> currencies = {};
  Set<String> links = {};
  Set<String> tags = {};
  Set<String> eventTypes = {};
  Set<String> eventValues = {};

  reset() {
    _transactions.clear();
    _pads.clear();

    accounts.clear();
    payees.clear();
    currencies.clear();
    links.clear();
    tags.clear();
    eventTypes.clear();
    eventValues.clear();
  }

  static Cost? computeCosts(List<Posting>? postings) {
    if (postings == null) return null;

    double sum = 0;
    int? emptyIndex;
    late String currency;
    for (var i = 0; i < postings.length; i++) {
      if (postings[i].cost == null) {
        emptyIndex = i;
        continue;
      }
      sum += postings[i].cost!.amount;
      currency = postings[i].cost!.currency;
    }
    return emptyIndex == null
        ? null
        : Cost(
            amount: -sum,
            currency: currency,
          );
  }

  List<Cost> balance(String account, Iterable<Item> items) {
    final List<Cost> ret = [];

    int getSlot(String currency) {
      for (var i = 0; i < ret.length; i++) {
        if (ret[i].currency == currency) {
          return i;
        }
      }
      ret.add(Cost(amount: 0, currency: currency));
      return ret.length - 1;
    }

    for (var i = 0; i < items.length; i++) {
      final e = items.elementAt(i).content;

      if (e is Transaction) {
        final fillCost = computeCosts(e.postings);
        e.postings?.forEach((p) {
          if (p.account == account) {
            final Cost cost = p.cost ?? fillCost!;
            ret[getSlot(cost.currency)] += cost;
          }
        });
      }

      if (e is Pad) {
        final c = e.cost;
        if (c != null) {
          final i = getSlot(c.currency);

          if (e.account == account) ret[i] += c;
          if (e.padAccount == account) ret[i] -= c;
        }
      }
    }
    return ret;
  }

  _updatePads(DateTime date, String account, Cost cost) {
    final p = _pads.firstWhereOrNull(
      (p) => p.date.isAfter(date) && p.account == account && p.cost != null,
    );
    if (p != null) {
      p.cost = p.cost! - cost;
    }
  }

  addItems(Iterable<Item>? items) {
    items?.forEach((item) {
      final e = item.content;
      if (e is AccountAction) {
        accounts.add(e.account);
        e.currencies?.forEach((e) => currencies.add(e));
      }
      if (e is Transaction) {
        final ts = e.tags;
        final ls = e.links;
        final payee = e.payee;
        if (payee != null) {
          payees.add(payee);
        }
        if (ts != null && ts.isNotEmpty) {
          tags.addAll(ts);
        }
        if (ls != null && ls.isNotEmpty) {
          links.addAll(ls);
        }
        final fillCost = computeCosts(e.postings);
        e.postings?.forEach((p) {
          accounts.add(p.account);
          if (p.cost != null) {
            currencies.add(p.cost!.currency);
          }

          _updatePads(e.date, p.account, p.cost ?? fillCost!);
        });
        final index =
            _transactions.lastIndexWhere((t) => !t.date.isAfter(e.date)) + 1;
        _transactions.insert(index, e);
      }
      if (e is Event) {
        eventTypes.add(e.key);
        eventValues.add(e.value);
      }

      if (e is Pad) {
        final i = _pads.lastIndexWhere((p) => !p.date.isAfter(e.date)) + 1;
        _pads.insert(i, e);
      }

      if (e is Balance) {
        final pendingPad = _pads.lastWhereOrNull(
          (p) => p.account == e.account && p.cost == null,
        );
        if (pendingPad != null) {
          final i = _pads.indexOf(pendingPad);

          final t = _transactions
              .takeWhile((t) => t.date.isBefore(e.date))
              .fold<Cost>(
            Cost(amount: 0, currency: e.cost.currency),
            (sum, t) {
              final fillCost = computeCosts(t.postings);
              t.postings?.forEach((p) {
                if (p.account == e.account &&
                    (p.cost ?? fillCost)!.currency == e.cost.currency) {
                  sum += p.cost ?? fillCost!;
                }
              });
              return sum;
            },
          );

          final p = _pads.sublist(0, i).where((p) {
            final c = p.cost;
            return c != null &&
                c.currency == e.cost.currency &&
                (p.account == e.account || p.padAccount == e.account);
          }).fold<Cost>(
            Cost(amount: 0, currency: e.cost.currency),
            (sum, p) {
              final cost = p.cost!;
              p.account == e.account ? sum += cost : sum -= cost;
              return sum;
            },
          );

          final c = e.cost - t - p;
          pendingPad.cost = c;

          _updatePads(pendingPad.date, pendingPad.account, c);
          _updatePads(pendingPad.date, pendingPad.padAccount,
              c.copyWith(amount: 0 - c.amount));
        }
      }
    });
  }

  delItems(Iterable<Item> items) {
    items.forEach((item) {
      final e = item.content;
      if (e is Pad) {
        final c = e.cost;
        if (c != null) {
          _updatePads(e.date, e.padAccount, c);
          _updatePads(e.date, e.account, c.copyWith(amount: 0 - c.amount));
        }
        _pads.remove(e);
      }
      if (e is Transaction) {
        final fillCost = computeCosts(e.postings);
        e.postings?.forEach((p) {
          final cost = p.cost ?? fillCost!;
          _updatePads(
              e.date, p.account, cost.copyWith(amount: 0 - cost.amount));
        });
        _transactions.remove(e);
      }
      if (e is Balance) {
        final p = _pads.lastWhereOrNull(
            (p) => p.account == e.account && p.date.isBefore(e.date));
        if (p != null && p.cost != null) {
          final c = p.cost!;
          _updatePads(p.date, p.padAccount, c);
          _updatePads(p.date, p.account, c.copyWith(amount: 0 - c.amount));
          p.cost = null;
        }
      }
    });
  }
}
