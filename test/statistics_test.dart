import 'package:test/test.dart';
import 'package:countbean/statistics.dart';
import 'package:countbean/parser/model.dart';

void main() {
  group('Statistics.addItems()', () {
    final s = Statistics();

    test('Events', () {
      s.reset();
      s.addItems([
        Event(
          date: DateTime(2020),
          key: "k",
          value: "v",
        ),
        Event(
          date: DateTime(2020),
          key: "kk",
          value: "vv",
        ),
      ]);
      expect(s.eventTypes, equals({'k', 'kk'}));
      expect(s.eventValues, equals({'v', 'vv'}));
    });

    test('AccountActions', () {
      s.reset();
      s.addItems([
        AccountAction(
          date: DateTime(2020),
          action: "open",
          account: "a",
          currencies: ['c'],
        ),
        AccountAction(
          date: DateTime(2020),
          action: "close",
          account: "a",
        ),
      ]);
      expect(s.accounts, equals({'a'}));
      expect(s.currencies, equals({'c'}));
    });

    test('Transactions', () {
      s.reset();
      s.addItems([
        Transaction(
          date: DateTime(2020),
          payee: 'p1',
          tags: ['t1', 't2'],
          links: ['l1', 'l2'],
          postings: [
            Posting(account: 'a', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a', cost: Cost(amount: -10, currency: 'CNY')),
          ],
        ),
      ]);

      expect(s.accounts, equals({'a', 'b'}));
      expect(s.tags, equals({'t1', 't2'}));
      expect(s.links, equals({'l1', 'l2', 'l3'}));
      expect(s.payees, equals({'p1', 'p2'}));
      expect(s.currencies, equals({'CNY'}));
    });

    test('reset', () {
      s.reset();
      expect(s.accounts, isEmpty);
      expect(s.currencies, isEmpty);
      expect(s.payees, isEmpty);
      expect(s.links, isEmpty);
      expect(s.tags, isEmpty);
      expect(s.eventTypes, isEmpty);
      expect(s.eventValues, isEmpty);
    });
  });

  group('Statistics.balance()', () {
    test('normal', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a', cost: Cost(amount: -10, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -15, currency: 'CNY')),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a', cost: Cost(amount: 10, currency: 'USD')),
          ],
        ),
      ];

      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 5, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -5, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with empty', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 5, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -5, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with balance only', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Balance(
          date: DateTime(2020, 1, 2),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 5, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -5, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with pad only', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 2),
          account: 'a',
          padAccount: 'b',
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 5, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -5, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with balance and pad', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 2),
          account: 'a',
          padAccount: 'b',
        ),
        Balance(
          date: DateTime(2020, 1, 2),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -20, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with balance and pad then remove transaction', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 2),
          account: 'a',
          padAccount: 'b',
        ),
        Balance(
          date: DateTime(2020, 1, 2),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);
      final removed = items.removeAt(1);
      s.delItems([removed]);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -20, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with balance and pad then remove balance', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 2),
          account: 'a',
          padAccount: 'b',
        ),
        Balance(
          date: DateTime(2020, 1, 2),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);
      final removed = items.removeAt(4);
      s.delItems([removed]);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 5, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -5, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with balance and pad then remove pad', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b'),
            Posting(account: 'a', cost: Cost(amount: 15, currency: 'CNY')),
          ],
        ),
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 2),
          account: 'a',
          padAccount: 'b',
        ),
        Balance(
          date: DateTime(2020, 1, 2),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);
      final removed = items.removeAt(3);
      s.delItems([removed]);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 5, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -5, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('with balance and multiple pads', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 2),
          account: 'b',
          padAccount: 'a',
        ),
        Balance(
          date: DateTime(2020, 1, 3),
          account: 'b',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
        Transaction(
          date: DateTime(2020, 1, 4),
          postings: [
            Posting(account: 'c', cost: Cost(amount: -10, currency: 'USD')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020, 1, 5),
          account: 'a',
          padAccount: 'c',
        ),
        Balance(
          date: DateTime(2020, 1, 6),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
            Cost(amount: 10, currency: 'USD'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
          ]));
      expect(
          s.balance('c', items),
          equals([
            Cost(amount: -40, currency: 'CNY'),
            Cost(amount: -10, currency: 'USD'),
          ]));
    });

    test('restore balance', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020),
          account: 'a',
          padAccount: 'b',
        ),
        Balance(
          date: DateTime(2020, 1, 3),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -20, currency: 'CNY'),
          ]));

      s.delItems([items.last]);
      expect(
          s.balance('a', items),
          equals([
            Cost(amount: -10, currency: 'CNY'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: 10, currency: 'CNY'),
          ]));

      s.addItems([items.last]);
      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -20, currency: 'CNY'),
          ]));
    });

    test('with pad and add transaction later', () {
      final s = Statistics()..reset();
      final items = [
        Transaction(
          date: DateTime(2020),
          payee: 'p2',
          tags: ['t1'],
          links: ['l1', 'l3'],
          postings: [
            Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
            Posting(account: 'a'),
          ],
        ),
        Pad(
          date: DateTime(2020),
          account: 'a',
          padAccount: 'b',
        ),
        Balance(
          date: DateTime(2020, 1, 3),
          account: 'a',
          cost: Cost(amount: 20, currency: 'CNY'),
        ),
      ];
      s.addItems(items);

      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -20, currency: 'CNY'),
          ]));

      final item = Transaction(
        date: DateTime(2020, 1, 4),
        postings: [
          Posting(account: 'b', cost: Cost(amount: 5, currency: 'CNY')),
          Posting(account: 'a'),
        ],
      );
      s.addItems([item]);
      expect(
          s.balance('a', [...items, item]),
          equals([
            Cost(amount: 15, currency: 'CNY'),
          ]));
      expect(
          s.balance('b', [...items, item]),
          equals([
            Cost(amount: -15, currency: 'CNY'),
          ]));

      s.addItems([item.copyWith(date: DateTime(2020, 1, 2))]);
      items.insert(1, item.copyWith(date: DateTime(2020, 1, 2)));
      expect(
          s.balance('a', items),
          equals([
            Cost(amount: 20, currency: 'CNY'),
          ]));
      expect(
          s.balance('b', items),
          equals([
            Cost(amount: -20, currency: 'CNY'),
          ]));
    });
  });
}
