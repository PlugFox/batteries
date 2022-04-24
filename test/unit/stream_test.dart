import 'dart:async';

import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

void main() => group('stream', () {
      test('relieve', () {
        const duration = Duration(microseconds: 100);
        bool isPrime(int n) {
          if (n > 1) {
            for (var i = 2; i < n; i++) {
              if (n % i != 0) continue;
              return false;
            }
            return true;
          } else {
            return false;
          }
        }

        final firstThousand = Iterable<int>.generate(1000)
            .map<bool>(isPrime)
            .toList(growable: false);

        expectLater(
          Stream<int>.fromIterable(Iterable<int>.generate(1000))
              .relieve(duration)
              .toList(),
          completes,
        );
        expectLater(
          Stream<int>.fromIterable(Iterable<int>.generate(1000))
              .map<bool>(isPrime)
              .relieve(duration)
              .toList(),
          completion(firstThousand),
        );
        expectLater(
          Stream<int>.fromIterable(<int>[
            for (var i = 0; i < 1000; i++) i,
          ]).map<bool>(isPrime).relieve(duration),
          emitsInOrder(firstThousand),
        );
        expectLater(
          Stream<int>.fromIterable(<int>[
            for (var i = 0; i < 1000; i++) i,
          ]).map<bool>(isPrime).asBroadcastStream().relieve(duration),
          emitsInOrder(firstThousand),
        );
      });
    });
