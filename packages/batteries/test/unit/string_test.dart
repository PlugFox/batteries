import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

void main() => group(
      'string',
      () {
        const date = 'Моя дата: "2002-02-27T14:00:00-0500"!';
        test('split_to_numbers', () {
          expect(
            () => date.splitToNumbers(),
            returnsNormally,
          );
          expect(
            () => ''.splitToNumbers(),
            returnsNormally,
          );
          expect(
            ''.splitToNumbers(8).length,
            8,
          );
          expect(
            date.splitToNumbers(8),
            equals(<int>[2002, 2, 27, 14, 0, 0, 500, 0]),
          );
          expect(
            date.splitToNumbers(3),
            equals(<int>[2002, 2, 27]),
          );
          expect(
            date.splitToNumbers(0),
            equals(<int>[]),
          );
          expect(
            '1.2'.splitToNumbers(2),
            equals(<int>[1, 2]),
          );
          expect(
            '1.2'.splitToNumbers(3),
            equals(<int>[1, 2, 0]),
          );
          expect(
            ''.splitToNumbers(2),
            equals(<int>[0, 0]),
          );
        });

        test('only_digits', () {
          expect(
            date.onlyDigit,
            equals('200202271400000500'),
          );
        });
        test('only_cyrillic', () {
          expect(
            date.onlyCyrillic,
            equals('Моядата'),
          );
        });

        test('only_latin', () {
          expect(
            date.onlyLatin,
            equals('T'),
          );
        });

        test('transliteration', () {
          expect(
            date.transliteration,
            equals('Moya data: "2002-02-27T14:00:00-0500"!'),
          );
        });
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
