import 'package:test/test.dart';
import 'package:countbean/statistics.dart';
import 'package:countbean/parser/model.dart';
import 'package:countbean/item.dart';
import 'package:countbean/balances.dart';

void main() {
  test('transaction', () {
    final a = Balances('a', [
      Cost(amount: 10, currency: 'CNY'),
      Cost(amount: 20, currency: 'US'),
    ]);

    expect(
        a.deduct([
          Item(Transaction(
            date: DateTime(2020),
            postings: [
              Posting(account: 'b', cost: Cost(amount: 10, currency: 'CNY')),
              Posting(account: 'a'),
            ],
          ))
        ]).toList(),
        [
          Cost(amount: 20, currency: 'CNY'),
          Cost(amount: 20, currency: 'US'),
        ]);
  });

  test('padFrom', () {
    final a = Balances('a', [
      Cost(amount: 10, currency: 'CNY'),
    ]);

    expect(
        a.deduct([
          Item(Pad(
            date: DateTime(2020),
            account: 'a',
            padAccount: 'b',
            cost: () => Cost(amount: 20, currency: 'CNY'),
          ))
        ]).toList(),
        [
          Cost(amount: -10, currency: 'CNY'),
        ]);
  });

  test('padTo', () {
    final a = Balances('a', [
      Cost(amount: 10, currency: 'CNY'),
    ]);

    expect(
        a.deduct([
          Item(Pad(
            date: DateTime(2020),
            account: 'b',
            padAccount: 'a',
            cost: () => Cost(amount: 20, currency: 'CNY'),
          ))
        ]).toList(),
        [
          Cost(amount: 30, currency: 'CNY'),
        ]);
  });

  test('padNotThisAccount', () {
    final a = Balances('a', [
      Cost(amount: 10, currency: 'CNY'),
    ]);

    expect(
        a.deduct([
          Item(Pad(
            date: DateTime(2020),
            account: 'b',
            padAccount: 'c',
            cost: () => Cost(amount: 20, currency: 'CNY'),
          ))
        ]).toList(),
        [
          Cost(amount: 10, currency: 'CNY'),
        ]);
  });
}
