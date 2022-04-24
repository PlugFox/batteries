import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

void main() => group('iterable', () {
      test('chunkWhile', () {
        expect(
          () => Iterable<int>.generate(100).chunkWhile((a, b) => a + 1 == b),
          returnsNormally,
        );
        expect(
          () => <int>[
            for (var i = 0; i < 10; i++) i,
            for (var i = 0; i < 10; i++) i,
          ].chunkWhile((a, b) => a + 1 == b),
          returnsNormally,
        );
        expect(
          <int>[1, 2, 3, 4, 6, 7, 8, 10].chunkWhile((a, b) => a + 1 == b),
          <List<int>>[
            <int>[1, 2, 3, 4],
            <int>[6, 7, 8],
            <int>[10],
          ],
        );
      });

      test('splitWhen', () {
        expect(
          () => Iterable<int>.generate(100).splitWhen((a, b) => a + 1 != b),
          returnsNormally,
        );
        expect(
          () => <int>[
            for (var i = 0; i < 10; i++) i,
            for (var i = 0; i < 10; i++) i,
          ].splitWhen((a, b) => a + 1 != b),
          returnsNormally,
        );
        expect(
          <int>[1, 2, 3, 4, 6, 7, 8, 10].splitWhen((a, b) => a + 1 != b),
          <List<int>>[
            <int>[1, 2, 3, 4],
            <int>[6, 7, 8],
            <int>[10],
          ],
        );
      });

      test('max_min', () {
        expect(
          () => Iterable<int>.generate(100).max,
          returnsNormally,
        );
        expect(
          () => Iterable<int>.generate(100).min,
          returnsNormally,
        );
        expect(
          <int>[
            for (var i = 0; i < 10; i++) i,
            for (var i = 0; i < 10; i++) 9 - i,
          ].max,
          equals(9),
        );
        expect(
          <int>[
            for (var i = 0; i < 10; i++) 9 - i,
            for (var i = 0; i < 10; i++) i,
          ].min,
          equals(0),
        );
      });
    });
