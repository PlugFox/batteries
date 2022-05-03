import 'dart:async';

import 'package:batteries/batteries.dart';
import 'package:test/test.dart';

void main() => group(
      'stream',
      () {
        test('relieve', () {
          const duration = Duration(microseconds: 150);
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

          final firstHundred = Iterable<int>.generate(100)
              .map<bool>(isPrime)
              .toList(growable: false);

          expectLater(
            Stream<int>.fromIterable(Iterable<int>.generate(100))
                .relieve(duration)
                .toList(),
            completes,
          );
          expectLater(
            Stream<int>.fromIterable(Iterable<int>.generate(100))
                .map<bool>(isPrime)
                .relieve(duration)
                .toList(),
            completion(firstHundred),
          );
          expectLater(
            Stream<int>.fromIterable(<int>[
              for (var i = 0; i < 100; i++) i,
            ]).map<bool>(isPrime).relieve(duration),
            emitsInOrder(firstHundred),
          );
          expectLater(
            Stream<int>.fromIterable(<int>[
              for (var i = 0; i < 100; i++) i,
            ]).map<bool>(isPrime).asBroadcastStream().relieve(duration),
            emitsInOrder(firstHundred),
          );
          expectLater(
            () async {
              int? value;
              Stream<int>.fromIterable(<int>[1, 2, 3])
                  .asBroadcastStream()
                  .map<int>((e) => value = e)
                  .relieve(duration)
                  .take(1);
              await Future<void>.delayed(duration * 2);
              return value;
            }(),
            completion(isNull),
          );
        });
        test('calm', () {
          const duration = Duration(microseconds: 150);
          final data = Iterable<int>.generate(10).toList(growable: false);
          expectLater(
            Stream<int>.fromIterable(data).calm(duration).toList(),
            completes,
          );
          expectLater(
            Stream<int>.fromIterable(<int>[]).calm(duration),
            neverEmits(anything),
          );
          expectLater(
            Stream<int>.fromIterable(data).calm(duration).toList(),
            completion(data),
          );
          expectLater(
            Stream<int>.fromIterable(data).calm(duration),
            emitsInOrder(data),
          );
          expectLater(
            () async {
              final sw = Stopwatch()..start();
              await Stream<int>.fromIterable(<int>[1, 2, 3])
                  .calm(const Duration(milliseconds: 250))
                  .take(3)
                  .drain<void>();
              final elapsed = (sw..stop()).elapsedMilliseconds;
              return elapsed > 500 && elapsed < 750;
            }(),
            completion(isTrue),
          );
          expectLater(
            () async {
              int? value;
              Stream<int>.fromIterable(<int>[1, 2, 3])
                  .asBroadcastStream()
                  .map<int>((e) => value = e)
                  .calm(duration)
                  .take(1);
              await Future<void>.delayed(duration);
              return value;
            }(),
            completion(isNull),
          );
        });
        group(
          'stream_handle',
          () {
            Future<void> sleep(int ms) =>
                Future<void>.delayed(Duration(milliseconds: ms));

            Stream<int> periodicStream() => Stream<int>.periodic(
                const Duration(milliseconds: 10), (i) => i);

            void pass<T>(T data, EventSink<T> sink) {
              sink.add(data);
            }

            Future<void> asyncPass<T>(T data, EventSink<T> sink) async {
              await sleep(10);
              sink.add(data);
            }

            void dublicate<T>(T data, EventSink<T> sink) {
              sink
                ..add(data)
                ..add(data);
            }

            FutureOr<void> asyncDublicate<T>(T data, EventSink<T> sink) async {
              sink.add(data);
              await sleep(10);
              sink.add(data);
            }

            void drain<T>(T data, EventSink<T> sink) {}

            Future<void> asyncDrain<T>(T data, EventSink<T> sink) async {}

            test('pass', () {
              final stream = Stream<int>.value(1).handle<int>(handleData: pass);
              expectLater(stream, emitsInOrder(<Object>[1, emitsDone]));
            });
            test('async_pass', () {
              final stream =
                  Stream<int>.value(1).handle<int>(handleData: asyncPass);
              expectLater(stream, emitsInOrder(<Object>[1, emitsDone]));
            });
            test('dublicate', () {
              expectLater(
                Stream<int>.value(1).handle<int>(handleData: dublicate),
                emitsInOrder(<Object>[1, 1, emitsDone]),
              );
            });
            test('async_dublicate', () {
              expectLater(
                Stream<int>.value(1).handle<int>(handleData: asyncDublicate),
                emitsInOrder(<Object>[1, 1, emitsDone]),
              );
            });
            test('drain', () {
              expectLater(
                Stream<int>.value(1).handle<int>(handleData: drain),
                emitsInOrder(<Object>[emitsDone]),
              );
            });
            test('async_drain', () {
              expectLater(
                Stream<int>.value(1).handle<int>(handleData: asyncDrain),
                emitsInOrder(<Object>[emitsDone]),
              );
            });
            test('chaining', () {
              expectLater(
                periodicStream()
                    .take(3)
                    .handle<int>(handleData: asyncPass)
                    .handle(handleData: asyncDublicate)
                    .handle(handleData: asyncPass)
                    .take(6),
                emitsInOrder(<Object>[0, 0, 1, 1, 2, 2, emitsDone]),
              );
            });
            test('subscribtion', () async {
              var countHandler = 0;
              var countListen = 0;
              final stream = periodicStream().handle<int>(
                handleData: (data, sink) async {
                  countHandler++;
                  sink.add(data);
                },
              );
              final sub = stream.listen((event) {
                countListen++;
              });
              expect(countHandler, 0);
              expect(countListen, 0);
              for (var i = 5; i < 20; i++) {
                expect(countHandler, countListen);
                final cache = countHandler;
                sub.pause();
                await sleep(i);
                sub.resume();
                expect(countHandler, cache);
                expect(countListen, cache);
                await sleep(i);
              }
              expect(countHandler, countListen);
              await sub.cancel();
            });
            test('empty', () {
              expect(
                const Stream<void>.empty().handle(handleData: pass).take(10),
                emitsDone,
              );
            });
            test('on_error', () {
              expect(
                Stream<void>.error(Exception())
                    .handle(
                  handleData: pass,
                  handleError: (e, st, sink) {
                    sink
                      ..add(1)
                      ..addError(e, st);
                  },
                )
                    .handle(
                  handleData: (data, sink) {
                    sink
                      ..add(data)
                      ..addError(Exception());
                  },
                  handleError: (e, st, sink) {
                    sink
                      ..add(2)
                      ..addError(e, st)
                      ..addError(e, st);
                  },
                ).take(10),
                emitsInOrder(<Object>[
                  1,
                  emitsError(isException),
                  2,
                  emitsError(isException),
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('async_on_error', () {
              expectLater(
                Stream<void>.error(Exception())
                    .handle(
                  handleData: pass,
                  handleError: (e, st, sink) async {
                    await sleep(10);
                    sink.add(1);
                    await sleep(10);
                    sink.addError(e, st);
                    await sleep(10);
                  },
                )
                    .handle(
                  handleData: (data, sink) async {
                    await sleep(10);
                    sink.add(data);
                    await sleep(10);
                    sink.addError(Exception());
                    await sleep(10);
                  },
                  handleError: (e, st, sink) async {
                    await sleep(10);
                    sink.add(2);
                    await sleep(10);
                    sink.addError(e, st);
                    await sleep(10);
                    sink.addError(e, st);
                    await sleep(10);
                  },
                ).take(10),
                emitsInOrder(<Object>[
                  1,
                  emitsError(isException),
                  2,
                  emitsError(isException),
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('on_done', () {
              expect(
                const Stream<int>.empty()
                    .handle(
                      handleData: pass,
                      handleDone: (sink) {
                        sink
                          ..add(1)
                          ..add(2);
                      },
                    )
                    .take(2),
                emitsInOrder(<Object>[
                  1,
                  2,
                  emitsDone,
                ]),
              );
            });
            test('async_on_done', () {
              expect(
                const Stream<int>.empty()
                    .handle(
                      handleData: pass,
                      handleDone: (sink) async {
                        await sleep(10);
                        sink.add(1);
                        await sleep(10);
                        sink.add(2);
                        await sleep(10);
                      },
                    )
                    .take(2),
                emitsInOrder(<Object>[
                  1,
                  2,
                  emitsDone,
                ]),
              );
            });
            test('exception', () {
              expectLater(
                periodicStream().handle(
                  handleData: (data, sink) async {
                    await sleep(10);
                    if (data.isEven) {
                      sink.add(data);
                    } else {
                      sink.addError(Exception());
                    }
                    await sleep(10);
                  },
                ).take(3),
                emitsInOrder(
                  <Object>[
                    0,
                    emitsError(isException),
                    2,
                    emitsError(isException),
                    4,
                    emitsDone,
                  ],
                ),
              );
            });
            test('close_sink', () {
              expectLater(
                Stream<int>.value(1).handle(
                  handleData: pass,
                  handleDone: (sink) {
                    sink
                      ..add(2)
                      ..close();
                  },
                ),
                emitsInOrder(
                  <Object>[
                    1,
                    2,
                    emitsDone,
                  ],
                ),
              );
            });
            test('broadcast', () async {
              final controller = StreamController<int>.broadcast();
              final expectation = emitsInOrder(
                <Object>[
                  ...Iterable<Object>.generate(10, (i) => i).expand((i) sync* {
                    yield i;
                    yield emitsError(isException);
                  }),
                  emitsDone,
                ],
              );
              final expect1 = expectLater(
                controller.stream,
                expectation,
              );
              final expect2 = expectLater(
                controller.stream,
                expectation,
              );
              final expect3 = expectLater(
                controller.stream,
                expectation,
              );
              for (var i = 0; i < 10; i++) {
                await sleep(10);
                controller.add(i);
                await sleep(10);
                controller.addError(Exception());
              }
              await controller.close();
              await Future.wait<void>([expect1, expect2, expect3]);
            });
            test('error_in_data_handler', () {
              expect(
                Stream<int>.value(0).handle<int>(
                  // ignore: void_checks
                  handleData: (data, sink) {
                    sink.add(1);
                    throw Exception();
                  },
                ),
                emitsInOrder(<Object>[
                  1,
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('async_error_in_data_handler', () {
              expect(
                Stream<int>.value(0).handle<int>(
                  handleData: (data, sink) async {
                    await sleep(10);
                    sink.add(1);
                    await sleep(10);
                    throw Exception();
                  },
                ),
                emitsInOrder(<Object>[
                  1,
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('error_without_error_handler', () {
              expect(
                Stream<int>.error(Exception()).handle<int>(
                  handleData: pass,
                ),
                emitsInOrder(<Object>[
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('error_in_error_handler', () {
              expect(
                Stream<int>.error(Exception()).handle<int>(
                  handleData: pass,
                  // ignore: void_checks
                  handleError: (error, stackTrace, sink) {
                    sink.add(1);
                    throw Exception();
                  },
                ),
                emitsInOrder(<Object>[
                  1,
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('async_error_in_error_handler', () {
              expect(
                Stream<int>.error(Exception()).handle<int>(
                  handleData: pass,
                  handleError: (error, stackTrace, sink) async {
                    await sleep(10);
                    sink.add(1);
                    await sleep(10);
                    throw Exception();
                  },
                ),
                emitsInOrder(<Object>[
                  1,
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('error_in_done_handler', () {
              expect(
                Stream<int>.value(0).handle<int>(
                  handleData: pass,
                  // ignore: void_checks
                  handleDone: (sink) {
                    sink.add(1);
                    throw Exception();
                  },
                ),
                emitsInOrder(<Object>[
                  0,
                  1,
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('async_error_in_done_handler', () {
              expect(
                Stream<int>.value(0).handle<int>(
                  handleData: pass,
                  handleDone: (sink) async {
                    await sleep(10);
                    sink.add(1);
                    await sleep(10);
                    throw Exception();
                  },
                ),
                emitsInOrder(<Object>[
                  0,
                  1,
                  emitsError(isException),
                  emitsDone,
                ]),
              );
            });
            test('stream_iterable', () {
              expect(
                Stream<int>.fromIterable([0, 1, 2, 3]).handle(
                  handleData: pass,
                ),
                emitsInOrder(<Object>[0, 1, 2, 3, emitsDone]),
              );
            });
            test('async_stream_iterable', () {
              expect(
                Stream<int>.fromIterable([0, 1, 2, 3]).handle(
                  handleData: asyncPass,
                ),
                emitsInOrder(<Object>[0, 1, 2, 3, emitsDone]),
              );
            });
            test('async_stream_iterable_broadcast', () {
              expect(
                Stream<int>.fromIterable([0, 1, 2, 3])
                    .handle(
                      handleData: asyncPass,
                    )
                    .asBroadcastStream(),
                emitsInOrder(<Object>[0, 1, 2, 3, emitsDone]),
              );
            });
          },
          timeout: const Timeout(Duration(seconds: 5)),
        );
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
