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
    /* 
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
    */
    final controller = stream.isBroadcast
        ? StreamController<T>.broadcast(
            onListen: null,
            onCancel: null,
            sync: false,
          )
        : StreamController<T>(
            onListen: null,
            onCancel: null,
            onPause: null,
            onResume: null,
            sync: false,
          );
    final add = controller.add;
    final addError = controller.addError;
    final close = controller.close;
    controller.onListen = () {
      final stopwatch = Stopwatch()..start();
      final subscription = stream.listen(
        null,
        onError: addError,
        onDone: () {
          stopwatch.stop();
          close();
        },
      );
      final resume = subscription.resume;
      subscription.onData((T event) {
        if (stopwatch.elapsed > duration) {
          subscription.pause();
          Future<void>.delayed(Duration.zero).then<void>(
            (_) {
              add(event);
              stopwatch.reset();
              resume();
            },
            onError: addError,
          );
        } else {
          add(event);
        }
      });
      controller.onCancel = () {
        stopwatch.stop();
        subscription.cancel();
      };
      if (!stream.isBroadcast) {
        controller
          ..onPause = subscription.pause
          ..onResume = resume;
      }
    };
    return controller.stream;
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
    final controller = stream.isBroadcast
        ? StreamController<T>.broadcast(
            onListen: null,
            onCancel: null,
            sync: false,
          )
        : StreamController<T>(
            onListen: null,
            onCancel: null,
            onPause: null,
            onResume: null,
            sync: false,
          );
    final add = controller.add;
    final addError = controller.addError;
    final close = controller.close;
    controller.onListen = () {
      final subscription = stream.listen(
        null,
        onError: addError,
        onDone: close,
      );
      final pause = subscription.pause;
      final resume = subscription.resume;
      subscription.onData((T event) {
        add(event);
        pause();
        Future<void>.delayed(duration)
            .catchError(addError)
            .whenComplete(resume);
      });
      controller.onCancel = subscription.cancel;
      if (!stream.isBroadcast) {
        controller
          ..onPause = pause
          ..onResume = resume;
      }
    };
    return controller.stream;
  }
}
