import 'dart:async';

import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

abstract class A {
  final String value;

  const A(this.value);
}

mixin X {}

class B = A with X;

class C = A with X;

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

      group('transformOnType', () {
        String sum(String a, String b) => a + b;
        test(
          'Untouched non-broadcast stream',
          () => expectLater(
            Stream<A>.fromIterable(const [B('a'), B('a'), B('a')])
                .transformOnType<C>(
                  (cs) => cs.map((c) => c.value.toUpperCase()).map(C.new),
                )
                .map((event) => event.value)
                .reduce(sum),
            completion('aaa'),
          ),
        );
        test(
          'Untouched broadcast stream',
          () => expectLater(
            Stream<A>.fromIterable(const [B('a'), B('a'), B('a')])
                .asBroadcastStream()
                .transformOnType<C>(
                  (cs) => cs.map((c) => c.value.toUpperCase()).map(C.new),
                )
                .map((event) => event.value)
                .reduce(sum),
            completion('aaa'),
          ),
        );
        test(
          'Transformed non-broadcast stream',
          () => expectLater(
            Stream<A>.fromIterable(const [B('a'), C('A'), B('a')])
                .transformOnType<C>(
                  (cs) => cs.map((c) => c.value.toUpperCase()).map(C.new),
                )
                .map((event) => event.value)
                .reduce(sum),
            completion('aAa'),
          ),
        );
        test(
          'Transformed broadcast stream',
          () => expectLater(
            Stream<A>.fromIterable(const [B('a'), C('A'), B('a')])
                .asBroadcastStream()
                .transformOnType<C>(
                  (cs) => cs.map((c) => c.value.toUpperCase()).map(C.new),
                )
                .map((event) => event.value)
                .reduce(sum),
            completion('aAa'),
          ),
        );
        test(
          'Transformer retains inertia stream contract on non-broadcast stream',
          () async {
            StreamSubscription<A>? sub;
            var transformedHasEmitted = false;
            final controller = StreamController<A>();
            final transformed = controller.stream
                .transformOnType<C>((selected) => selected)
                .map((event) {
              transformedHasEmitted = true;
              return event;
            });

            Future<void> nextEventLoop() => Future<void>.delayed(Duration.zero);
            void emit() => controller.add(const C('a'));
            void subscribe() => sub = transformed.listen((event) {});

            await nextEventLoop();
            expect(transformedHasEmitted, false);
            emit();
            await nextEventLoop();
            expect(transformedHasEmitted, false);
            subscribe();
            await nextEventLoop();
            expect(transformedHasEmitted, true);

            await sub?.cancel();
            await controller.close();
          },
        );
        test(
          'Transformer retains inertia stream contract on broadcast stream',
          () async {
            StreamSubscription<A>? sub;
            var transformedHasEmitted = false;
            final controller = StreamController<A>.broadcast();
            final transformed = controller.stream
                .transformOnType<C>((selected) => selected)
                .map((event) {
              transformedHasEmitted = true;
              return event;
            });

            Future<void> nextEventLoop() => Future<void>.delayed(Duration.zero);
            void emit() => controller.add(const C('a'));
            void subscribe() => sub = transformed.listen((event) {});

            await nextEventLoop();
            expect(transformedHasEmitted, false);
            emit();
            await nextEventLoop();
            expect(transformedHasEmitted, false);
            subscribe();
            await nextEventLoop();
            expect(transformedHasEmitted, false);
            emit();
            await nextEventLoop();
            expect(transformedHasEmitted, true);

            await sub?.cancel();
            await controller.close();
          },
        );
      });
    });
