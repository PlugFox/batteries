import 'dart:async';

import 'package:meta/meta.dart';

/// {@template stream.stream_extensions}
/// Stream extension methods.
/// {@endtemplate}
extension BatteriesStreamX<T> on Stream<T> {
  /// {@macro stream.relieve_stream_transformer}
  Stream<T> relieve([
    Duration duration = const Duration(milliseconds: 4),
  ]) =>
      transform<T>(RelieveStreamTransformer<T>(duration));

  /// {@macro stream.calm_stream_transformer}
  Stream<T> calm(Duration duration) =>
      transform<T>(CalmStreamTransformer<T>(duration));
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

/// {@template stream.calm_stream_transformer}
/// Calm stream transformer.
/// For example, when you need a pause between events no less than specified.
/// e.g sending messages to the messenger with intervals and pauses,
/// in order not to be banned for spam.
/// {@endtemplate}
@immutable
class CalmStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// {@macro stream.calm_stream_transformer}
  const CalmStreamTransformer(this.duration);

  /// Elapsed time of iterations before releasing next event.
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    StreamSubscription<T>? sub;
    final sc = stream.isBroadcast
        ? StreamController<T>.broadcast(
            onCancel: () => sub?.cancel(),
            sync: false,
          )
        : StreamController<T>(
            onCancel: () => sub?.cancel(),
            sync: false,
          );
    sub = stream.listen(
      (T value) {
        sub?.pause();
        sc.add(value);
        Future<void>.delayed(duration).then<void>(
          (_) => sub?.resume(),
          onError: sc.addError,
        );
      },
      onDone: sc.close,
      onError: sc.addError,
      cancelOnError: false,
    );
    return sc.stream;
  }
}
