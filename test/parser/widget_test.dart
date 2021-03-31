import 'package:test/test.dart';
import 'package:countbean/parser/widget.dart';

void main() {
  group('ParsingError.getContextRange()', () {
    test('in between', () {
      final input = "1\n2\n3\n4\n5\n6\n7";
      final position = input.indexOf('4');
      final begin = input.indexOf('2');
      final end = input.indexOf('5') + 1;
      final expectedPosition = "2\n3\n4\n5\n".indexOf('4');
      expect(ParsingError.getContextRange(input, position),
          equals([begin, end, expectedPosition]));
    });
    test('at beginning', () {
      final input = "1\n2\n3\n4\n5\n6\n7";
      final position = input.indexOf('2');
      final begin = 0;
      final end = input.indexOf('3') + 1;
      final expectedPosition = "1\n2\n3\n".indexOf('2');
      expect(ParsingError.getContextRange(input, position),
          equals([begin, end, expectedPosition]));
    });
    test('in the end', () {
      final input = "1\n2\n3\n4\n5\n6\n7";
      final position = input.indexOf('6');
      final begin = input.indexOf('4');
      final end = input.length;
      final expectedPosition = "4\n5\n6\n7".indexOf('6');
      expect(ParsingError.getContextRange(input, position),
          equals([begin, end, expectedPosition]));
    });
  });
}
