import 'dart:async';

import 'package:meta/meta.dart';

/// {@template stream.stream_extensions}
/// Stream extension methods.
/// {@endtemplate}
extension StreamX<T> on Stream<T> {
  /// Allow relieve impact on event loop on large collections.
  /// Parallelize the event queue and free up time for processing animation,
  /// user gestures without using isolates.
  ///
  /// Thats transformer makes stream low priority.
  ///
  /// [duration] - elapsed time of iterations before releasing
  /// the event queue and microtasks.
  Stream<T> relieve([
    Duration duration = const Duration(milliseconds: 4),
  ]) =>
      transform<T>(RelieveStreamTransformer<T>(duration));
}

/// {@template stream.relieve_stream_transformer}
/// Allow relieve impact on event loop on large collections.
/// Parallelize the event queue and free up time for processing animation,
/// user gestures without using isolates.
///
/// Thats transformer makes stream low priority.
///
/// [duration] - elapsed time of iterations before releasing
/// the event queue and microtasks.
/// {@endtemplate}
@immutable
class RelieveStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// {@macro stream.relieve_stream_transformer}
  const RelieveStreamTransformer([
    this.duration = const Duration(milliseconds: 4),
  ]);

  /// Elapsed time of iterations before releasing
  /// the event queue and microtasks.
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    final sw = Stopwatch()..start();
    StreamSubscription<T>? sub;
    final sc = stream.isBroadcast
        ? StreamController<T>.broadcast(
            onCancel: () => sub?.cancel(),
            sync: true,
          )
        : StreamController<T>(
            onCancel: () => sub?.cancel(),
            sync: true,
          );
    sub = stream.listen(
      (T value) {
        if (sw.elapsed > duration) {
          sub?.pause();
          Future<void>.delayed(Duration.zero).then<void>(
            (_) {
              sc.add(value);
              sw.reset();
              sub?.resume();
            },
            onError: sc.addError,
          );
        } else {
          sc.add(value);
        }
      },
      onDone: () {
        sw.stop();
        sc.close();
      },
      onError: sc.addError,
      cancelOnError: false,
    );
    return sc.stream;
  }
}
