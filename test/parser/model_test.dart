import 'package:test/test.dart';
import 'package:countbean/parser/model.dart';

void main() {
  group('Posting.toString()', () {
    test('on the simplest posting', () {
      final Posting posting = Posting(account: 'Assets');
      final String expected = '''Assets''';
      expect(posting.toString(), equals(expected));
    });

    test('on a posting with flag', () {
      final Posting posting = Posting(account: 'Assets:A', flag: '!');
      final String expected = '''! Assets:A''';
      expect(posting.toString(), equals(expected));
    });

    test('on a posting with cost', () {
      final Posting posting =
          Posting(account: 'Assets:A', cost: Cost(amount: 10, currency: 'BRL'));
      final String expected = '''Assets:A 10.00 BRL''';
      expect(posting.toString(), equals(expected));
    });

    test('on a posting with metadata', () {
      final Posting posting =
          Posting(account: 'Assets:B', metadata: {'dont-know': 'don\'t care'});
      final String expected = '''Assets:B
  dont-know: "don't care"''';
      expect(posting.toString(), equals(expected));
    });
  });

  group('Transaction.toString()', () {
    test('on (an invalid) blank transaction', () {
      final Transaction transaction = Transaction(date: DateTime(2018));
      final String expected = '2018-01-01 *';
      expect(transaction.toString(), equals(expected));
    });

    test('on simple transaction', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
      );
      final String expected = '''
2018-01-01 *
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with multiple different postings', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B', cost: Cost(amount: 0.0, currency: 'MONEY')),
          Posting(
              account: 'C', cost: Cost(amount: -999.999, currency: 'MONEY')),
          Posting(account: 'D'),
        ],
      );
      final String expected = '''
2018-01-01 *
  A 10.00 MONEY
  B 0.00 MONEY
  C -1000.00 MONEY
  D''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with tags', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        tags: ['z', 'a', 'b', null, '_0', 'd', '5', 'ç'],
      );
      final String expected = '''
2018-01-01 * #z #a #b #_0 #d #5 #ç
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with links', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        links: ['z', 'a', 'b', null, '_0', 'd', '5', 'ç'],
      );
      final String expected = '''
2018-01-01 * ^z ^a ^b ^_0 ^d ^5 ^ç
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with tags & links', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        tags: ['z', 'a', 'b', '_0', 'd', '5', 'ç'],
        links: ['z', 'a', 'b', '_0', 'd', '5', 'ç'],
      );
      final String expected = '''
2018-01-01 * #z #a #b #_0 #d #5 #ç ^z ^a ^b ^_0 ^d ^5 ^ç
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with a comment', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        comment: 'comment',
      );
      final String expected = '''
2018-01-01 * "comment"
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with a payee and comment', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        payee: 'payee',
        comment: 'comment',
      );
      final String expected = '''
2018-01-01 * "payee" "comment"
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with a payee only', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        payee: 'payee',
      );
      final String expected = '''
2018-01-01 * "payee" ""
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });

    test('on transaction with everything', () {
      final Transaction transaction = Transaction(
        date: DateTime(2018),
        postings: [
          Posting(account: 'A', cost: Cost(amount: 10.0, currency: 'MONEY')),
          Posting(account: 'B'),
        ],
        payee: 'payee',
        comment: 'comment',
        tags: ['a'],
        links: ['a'],
      );
      final String expected = '''
2018-01-01 * "payee" "comment" #a ^a
  A 10.00 MONEY
  B''';
      expect(transaction.toString(), equals(expected));
    });
  });

  group('Cost.toString()', () {
    test('on a cost', () {
      final Cost cost = Cost(amount: 99, currency: 'S');
      final String expected = '''99.00 S''';
      expect(cost.toString(), equals(expected));
    });

    test('on a rounded cost', () {
      final Cost cost = Cost(amount: 99.9999, currency: 'S');
      final String expected = '''100.00 S''';
      expect(cost.toString(), equals(expected));
    });
  });

  test('Option.toString()', () {
    final Option option = Option(key: 'k', value: 'v');
    final String expected = '''option "k" "v"''';
    expect(option.toString(), equals(expected));
  });

  test('Commodity.toString()', () {
    final Commodity commodity = Commodity(
      date: DateTime(2020),
      currency: 'CNY',
    );
    final String expected = '''2020-01-01 commodity CNY''';
    expect(commodity.toString(), equals(expected));
  });

  test('Event.toString()', () {
    final Event event = Event(date: DateTime(2020), key: 'k', value: 'v');
    final String expected = '''2020-01-01 event "k" "v"''';
    expect(event.toString(), equals(expected));
  });

  test('Pad.toString()', () {
    final Pad pad = Pad(
      date: DateTime(2020),
      account: 'k',
      padAccount: 'v',
      cost: () => Cost(amount: 10, currency: 'CNY'),
    );
    final String expected = '''2020-01-01 pad k v ;10.00 CNY''';
    expect(pad.toString(), equals(expected));
  });

  test('Pad without cost.toString()', () {
    final Pad pad = Pad(
      date: DateTime(2020),
      account: 'k',
      padAccount: 'v',
    );
    final String expected = '''2020-01-01 pad k v''';
    expect(pad.toString(), equals(expected));
  });
}
