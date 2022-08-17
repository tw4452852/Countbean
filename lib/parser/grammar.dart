import 'package:petitparser/petitparser.dart';

class BeancountGrammarDefinition extends GrammarDefinition {
  const BeancountGrammarDefinition();

  Parser start() => ref0(value).end();
  Parser token(Parser parser) => parser.flatten().trim(anyOf(' \t\r'));

  Parser value() => ref0((transaction() |
          balance() |
          accountAction() |
          option() |
          commodity() |
          event() |
          pad() |
          fullLineComment())
      .star);

  Parser numberToken() => ref1(
      token,
      char('-').optional() &
          char('0').or(digit().plus()) &
          char('.').seq(digit().plus()).optional());
  Parser stringToken() =>
      ref1(token, char('"') & pattern('^"').star() & char('"'));
  Parser flagToken() => ref1(token, char('*') | char('!') | string('txn'));
  Parser dateToken() => ref1(
      token,
      digit().times(4) &
          char('-') &
          digit().times(2) &
          char('-') &
          digit().times(2));
  Parser accountToken() => ref1(
      token,
      accountPreffixPrimitive() &
          (char(':') & tagsCharacterPrimitive().plus()).star());
  Parser currencyToken() => ref1(token, uppercaseCharacterPrimitive().plus());
  Parser tagToken() => ref1(token, char('#') & tagsCharacterPrimitive().plus());
  Parser linkToken() =>
      ref1(token, char('^') & tagsCharacterPrimitive().plus());
  Parser singleMetadataToken() =>
      ref1(token, lowercaseCharacterPrimitive().plus()) &
      ref1(token, char(':')) &
      stringToken() &
      comment();
  Parser metadataToken() => singleMetadataToken().star();
  Parser costToken() => numberToken() & currencyToken();

  Parser tags() => tagToken().star();
  Parser links() => linkToken().star();
  Parser singlePosting() =>
      flagToken().optional() &
      accountToken() &
      costToken().optional() &
      comment() &
      metadataToken();
  Parser postings() => singlePosting().star();
  Parser currencies() => currencyToken().separatedBy(char(',')).optional();
  Parser transaction() =>
      dateToken() &
      flagToken() &
      (stringToken() & stringToken().optional()).optional() &
      tags() &
      links() &
      comment() &
      metadataToken() &
      postings();
  Parser balance() =>
      dateToken() &
      string('balance') &
      accountToken() &
      costToken() &
      comment() &
      metadataToken();
  Parser accountAction() =>
      dateToken() &
      accountActionPrimitive() &
      accountToken() &
      currencies() &
      comment();
  Parser option() =>
      string('option') & stringToken() & stringToken() & comment();
  Parser fullLineComment() =>
      ref1(token, char(';') & noneOf('\n').star() & whitespace().star());
  Parser comment() => ref1(token, fullLineComment() | whitespace().star());
  Parser commodity() =>
      dateToken() &
      string('commodity') &
      currencyToken() &
      comment() &
      metadataToken();
  Parser event() =>
      dateToken() & string('event') & stringToken() & stringToken() & comment();
  Parser pad() =>
      dateToken() & string('pad') & accountToken() & accountToken() & comment();

  Parser accountActionPrimitive() => string('open') | string('close');
  Parser accountPreffixPrimitive() =>
      string('Assets') |
      string('Liabilities') |
      string('Equity') |
      string('Income') |
      string('Expenses');
  Parser uppercaseCharacterPrimitive() => pattern('0-9A-Z_');
  Parser lowercaseCharacterPrimitive() => pattern('0-9a-z_-');
  Parser tagsCharacterPrimitive() => pattern('0-9a-zA-Z-_');
}
