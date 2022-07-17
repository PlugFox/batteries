// ignore_for_file: prefer_const_constructors

import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

void main() => group(
      'list',
      () {
        test('immutable_list', () {
          expect(
            () => ImmutableList(Iterable<int>.generate(100)),
            returnsNormally,
          );
          expect(
            ImmutableList(Iterable<int>.generate(100)),
            isA<Iterable<int>>(),
          );
          expect(
            ImmutableList(Iterable<int>.generate(100)),
            isA<Iterable<num>>(),
          );
          expect(
            ImmutableList<int>.empty(),
            equals(const Iterable<int>.empty()),
          );
          expect(
            ImmutableList(Iterable<int>.generate(100)).cast<num>(),
            isA<Iterable<num>>(),
          );
          expect(
            ImmutableList(Iterable<int>.generate(100)).cast<num>(),
            isNot(isA<Iterable<int>>()),
          );
          expect(
            ImmutableList(Iterable<int>.generate(100)).length,
            equals(100),
          );
          expect(
            ImmutableList(const [123]).add(1),
            isA<ImmutableList>(),
          );
          expect(
            ImmutableList<int>.empty().add(1).length,
            equals(1),
          );
          expect(
            ImmutableList<int>.empty().add(1).add(1).length,
            equals(2),
          );
          expect(
            ImmutableList<int>.empty().upsert(1).add(1).length,
            equals(2),
          );
          expect(
            ImmutableList<int>.empty().addAll([1, 2, 3]),
            equals([1, 2, 3]),
          );
          expect(
            ImmutableList<int>(const <int>[1, 3, 5, 2, 10])
                .removeWhere((e) => e > 3),
            equals([1, 3, 2]),
          );
          expect(
            ImmutableList<int>(const <int>[1, 2, 3])[1],
            equals(2),
          );
          expect(
            ImmutableList<int>.empty().upsert(1).remove(1),
            isEmpty,
          );
          expect(
            () => ImmutableList<int>.empty().remove(1),
            returnsNormally,
          );
          expect(
            ImmutableList<int>.empty().upsert(1).upsert(1).length,
            equals(1),
          );
          expect(
            () => ImmutableList<int>.empty().first,
            throwsStateError,
          );
          expect(
            () => ImmutableList<int>.empty().last,
            throwsStateError,
          );
          expect(
            ImmutableList<int>(const <int>[2, 3, 1]).first,
            same(2),
          );
          expect(
            ImmutableList<int>(const <int>[2, 3, 1]).last,
            same(1),
          );
          expect(
            ImmutableList<int>.empty().iterator,
            isA<Iterator>(),
          );
          expect(
            ImmutableList<int>(const <int>[2, 1, 3, 5]).sort(),
            equals(<int>[1, 2, 3, 5]),
          );
        });
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
