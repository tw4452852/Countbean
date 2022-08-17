import 'package:intl/intl.dart';

class Cost {
  double amount;
  String currency;

  Cost({
    required this.amount,
    required this.currency,
  });

  Cost copyWith({
    double? amount,
    String? currency,
  }) {
    return Cost(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() => '${amount.toStringAsFixed(2)} $currency';

  Cost operator +(Cost other) {
    if (currency != other.currency) {
      throw Exception('Not same currency: $currency, ${other.currency}');
    }
    return Cost(
      amount: amount + other.amount,
      currency: currency,
    );
  }

  Cost operator -(Cost other) {
    if (currency != other.currency) {
      throw Exception('Not same currency: $currency, ${other.currency}');
    }
    return Cost(
      amount: amount - other.amount,
      currency: currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cost &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          currency == other.currency;

  @override
  int get hashCode => amount.hashCode ^ currency.hashCode;
}

class Option {
  String key;
  String value;

  Option({
    required this.key,
    required this.value,
  });

  Option copyWith({
    String? key,
    String? value,
  }) {
    return Option(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  String toString() => 'option "$key" "$value"';
}

class Commodity {
  DateTime date;
  String currency;
  Map<String, String>? metadata;

  Commodity({
    required this.date,
    required this.currency,
    this.metadata,
  });

  Commodity copyWith({
    DateTime? date,
    String? currency,
    Map<String, String>? metadata,
  }) {
    return Commodity(
      date: date ?? this.date,
      currency: currency ?? this.currency,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();
    buffer.write(formatter.format(date));
    buffer.write(' commodity $currency');

    final metadata = this.metadata;
    if (metadata != null) {
      for (MapEntry<String, String> meta in metadata.entries) {
        buffer.writeln('\n  ${meta.key}: "${meta.value}"');
      }
    }

    return buffer.toString();
  }
}

class Event {
  DateTime date;
  String key;
  String value;

  Event({
    required this.date,
    required this.key,
    required this.value,
  });

  Event copyWith({
    DateTime? date,
    String? key,
    String? value,
  }) {
    return Event(
      date: date ?? this.date,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();
    buffer.write(formatter.format(date));
    buffer.write(' event "$key" "$value"');

    return buffer.toString();
  }
}

class Posting {
  String flag;
  String account;
  Cost? cost;
  Map<String, String>? metadata;

  Posting({
    String? flag,
    required this.account,
    this.cost,
    this.metadata,
  }) : flag = flag ?? '*';

  Posting copyWith({
    String? flag,
    String? account,
    Cost? cost,
    Map<String, String>? metadata,
  }) {
    return Posting(
      flag: flag ?? this.flag,
      account: account ?? this.account,
      cost: cost ?? this.cost,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();

    if (flag != '*') buffer.write('$flag ');

    buffer.write('$account');

    if (cost != null) {
      buffer.write(' $cost');
    }

    final metadata = this.metadata;
    if (metadata != null) {
      for (MapEntry<String, String> meta in metadata.entries) {
        buffer.write('\n  ${meta.key}: "${meta.value}"');
      }
    }

    return buffer.toString();
  }
}

final formatter = new DateFormat('yyyy-MM-dd');

class Transaction {
  DateTime date;
  String flag;
  String? payee;
  String? comment;
  List<String>? tags;
  List<String>? links;
  Map<String, String>? metadata;
  List<Posting>? postings;

  Transaction({
    required this.date,
    String? flag,
    this.payee,
    this.comment,
    this.tags,
    this.links,
    this.metadata,
    this.postings,
  }) : flag = flag ?? '*';

  Transaction copyWith({
    DateTime? date,
    String? flag,
    String? payee,
    String? comment,
    List<String>? tags,
    List<String>? links,
    Map<String, String>? metadata,
    List<Posting>? postings,
  }) {
    return Transaction(
      date: date ?? this.date,
      flag: flag ?? this.flag,
      payee: payee ?? this.payee,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      links: links ?? this.links,
      metadata: metadata ?? this.metadata,
      postings: postings ?? this.postings,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();
    buffer.write(formatter.format(date));
    buffer.write(' $flag');

    final payee = this.payee;
    final comment = this.comment;
    if (payee != null && payee.isNotEmpty) {
      buffer.write(' "$payee" "${comment ?? ''}"');
    } else {
      if (comment != null && comment.isNotEmpty) {
        buffer.write(' "$comment"');
      }
    }

    final tags = this.tags;
    if (tags != null) {
      for (String tag in tags) {
        buffer.write(' #$tag');
      }
    }
    final links = this.links;
    if (links != null) {
      for (String link in links) {
        buffer.write(' ^$link');
      }
    }

    final metadata = this.metadata;
    if (metadata != null) {
      for (MapEntry<String, String> meta in metadata.entries) {
        buffer.write('\n  ${meta.key}: "${meta.value}"');
      }
    }

    final postings = this.postings;
    if (postings != null) {
      for (Posting posting in postings) {
        buffer.write('\n  ${posting.toString().replaceAll('\n', '\n  ')}');
      }
    }

    return buffer.toString();
  }
}

class Balance {
  DateTime date;
  String account;
  Cost cost;
  Map<String, String>? metadata;

  Balance({
    required this.date,
    required this.account,
    required this.cost,
    this.metadata,
  });

  Balance copyWith({
    DateTime? date,
    String? account,
    Cost? cost,
    Map<String, String>? metadata,
  }) {
    return Balance(
      date: date ?? this.date,
      account: account ?? this.account,
      cost: cost ?? this.cost,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();
    buffer.write('${formatter.format(date)} balance $account $cost');

    final metadata = this.metadata;
    if (metadata != null) {
      for (MapEntry<String, String> meta in metadata.entries) {
        buffer.write('\n  ${meta.key}: "${meta.value}"');
      }
    }

    return buffer.toString();
  }
}

class AccountAction {
  DateTime date;
  String action;
  String account;
  List<String>? currencies;

  AccountAction({
    required this.date,
    required this.action,
    required this.account,
    this.currencies,
  });

  AccountAction copyWith({
    DateTime? date,
    String? action,
    String? account,
    List<String>? currencies,
  }) {
    return AccountAction(
      date: date ?? this.date,
      action: action ?? this.action,
      account: account ?? this.account,
      currencies: currencies ?? this.currencies,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();
    buffer.write(formatter.format(date));
    buffer.write(' $action $account');

    final currencies = this.currencies;
    if (currencies != null && currencies.isNotEmpty) {
      buffer.write(' ${currencies.join(',')}');
    }

    return buffer.toString();
  }
}

typedef GetCost = Cost Function();

class Pad {
  DateTime date;
  String account, padAccount;
  Cost? cost;

  Pad({
    required this.date,
    required this.account,
    required this.padAccount,
    this.cost,
  });

  Pad copyWith({
    DateTime? date,
    String? account,
    String? padAccount,
    Cost? cost,
  }) {
    return Pad(
      date: date ?? this.date,
      account: account ?? this.account,
      padAccount: padAccount ?? this.padAccount,
      cost: cost ?? this.cost,
    );
  }

  @override
  String toString() {
    final buffer = new StringBuffer();
    buffer.write(formatter.format(date));
    buffer.write(' pad $account $padAccount');
    final cost = this.cost;
    if (cost != null) {
      buffer.write(' ;$cost');
    }

    return buffer.toString();
  }
}
