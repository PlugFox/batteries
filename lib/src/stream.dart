import 'dart:async';

import 'package:meta/meta.dart';

/// {@template stream.stream_extensions}
/// Stream extension methods.
/// {@endtemplate}
extension BatteriesStreamX<Input> on Stream<Input> {
  /// {@macro stream.relieve_stream_transformer}
  Stream<Input> relieve([
    Duration duration = const Duration(milliseconds: 4),
  ]) =>
      transform<Input>(_RelieveStreamTransformer<Input>(duration));

  /// {@macro stream.calm_stream_transformer}
  Stream<Input> calm(Duration duration) =>
      transform<Input>(_CalmStreamTransformer<Input>(duration));

  /// {@macro async_stream_handler}
  ///
  /// [handleData] is a callback for the stream data channel that takes
  ///   an data and an [EventSink].
  /// [handleError] is a callback for the stream error channel that takes
  ///   an Error with [StackTrace] and an [EventSink].
  /// [handleDone] is a callback for the stream done channel that takes
  ///   an [EventSink].
  Stream<Output> handle<Output>({
    /// Handler for the stream data channel.
    required FutureOr<void> Function(
      Input data,
      EventSink<Output> sink,
    )
        handleData,

    /// Handler for the stream error channel.
    FutureOr<void> Function(
      Object error,
      StackTrace stackTrace,
      EventSink<Output> sink,
    )?
        handleError,

    /// Handler for the stream close event.
    FutureOr<void> Function(
      EventSink<Output> sink,
    )?
        handleDone,
  }) =>
      transform<Output>(
        _AsyncStreamHandler<Input, Output>(
          handleData: handleData,
          handleError: handleError,
          handleDone: handleDone,
        ),
      );
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
class _RelieveStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// {@macro stream.relieve_stream_transformer}
  const _RelieveStreamTransformer([
    this.duration = const Duration(milliseconds: 4),
  ]);

  /// Elapsed time of iterations before releasing
  /// the event queue and microtasks.
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    final controller = stream.isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);
    return (controller..onListen = () => _onListen(stream, controller)).stream;
  }

  void _onListen(
    Stream<T> stream,
    StreamController<T> controller,
  ) {
    final stopwatch = Stopwatch()..start();
    final sink = controller.sink;
    final subscription = stream.listen(null, cancelOnError: false);
    controller.onCancel = subscription.cancel;
    if (!stream.isBroadcast) {
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
    }
    final scaffold = _scaffold(sink, subscription.pause, subscription.resume);
    subscription
      ..onData((data) => scaffold(stopwatch, data))
      ..onError(sink.addError)
      ..onDone(() {
        stopwatch.stop();
        sink.close();
      });
  }

  void Function(Stopwatch stopwatch, T data) _scaffold(
    StreamSink<T> sink,
    void Function([Future<void>? resumeSignal]) pause,
    void Function() resume,
  ) =>
      (Stopwatch stopwatch, T data) {
        if (stopwatch.elapsed > duration) {
          pause();
          Timer.run(() {
            try {
              sink.add(data);
              stopwatch.reset();
              resume();
            } on Object catch (error, stackTrace) {
              sink.addError(error, stackTrace);
            }
          });
        } else {
          try {
            sink.add(data);
          } on Object catch (error, stackTrace) {
            sink.addError(error, stackTrace);
          }
        }
      };
}

/// {@template stream.calm_stream_transformer}
/// Calm stream transformer.
/// For example, when you need a pause between events no less than specified.
/// e.g sending messages to the messenger with intervals and pauses,
/// in order not to be banned for spam.
/// {@endtemplate}
@immutable
class _CalmStreamTransformer<T> extends StreamTransformerBase<T, T> {
  /// {@macro stream.calm_stream_transformer}
  const _CalmStreamTransformer(this.duration);

  /// Elapsed time of iterations before releasing next event.
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    final controller = stream.isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);
    return (controller..onListen = () => _onListen(stream, controller)).stream;
  }

  void _onListen(
    Stream<T> stream,
    StreamController<T> controller,
  ) {
    final sink = controller.sink;
    final subscription = stream.listen(null, cancelOnError: false);
    controller.onCancel = subscription.cancel;
    if (!stream.isBroadcast) {
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
    }
    final scaffold = _scaffold(sink, subscription.pause, subscription.resume);
    subscription
      ..onData(scaffold)
      ..onError(sink.addError)
      ..onDone(sink.close);
  }

  void Function(T data) _scaffold(
    StreamSink<T> sink,
    void Function([Future<void>? resumeSignal]) pause,
    void Function() resume,
  ) =>
      (T data) {
        try {
          sink.add(data);
        } on Object catch (error, stackTrace) {
          sink.addError(error, stackTrace);
        }
        pause();
        Timer(duration, resume);
      };
}

/// {@template async_stream_handler}
/// Stream Transformer with async handlers, saves the order of events.
/// {@endtemplate}
@immutable
class _AsyncStreamHandler<Input, Output>
    extends StreamTransformerBase<Input, Output> {
  /// {@macro async_stream_handler}
  const _AsyncStreamHandler({
    required this.handleData,
    this.handleError,
    this.handleDone,
  });

  final FutureOr<void> Function(
    Input data,
    EventSink<Output> sink,
  ) handleData;

  final FutureOr<void> Function(
    Object error,
    StackTrace stackTrace,
    EventSink<Output> sink,
  )? handleError;

  final FutureOr<void> Function(EventSink<Output> sink)? handleDone;

  @override
  Stream<Output> bind(Stream<Input> stream) {
    final controller = stream.isBroadcast
        ? StreamController<Output>.broadcast(sync: true)
        : StreamController<Output>(sync: true);
    return (controller..onListen = () => _onListen(stream, controller)).stream;
  }

  void _onListen(
    Stream<Input> stream,
    StreamController<Output> controller,
  ) {
    final sink = controller.sink;
    final subscription = stream.listen(null, cancelOnError: false);
    controller.onCancel = subscription.cancel;
    if (!stream.isBroadcast) {
      controller
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
    }
    final scaffold = _scaffold(sink, subscription.pause, subscription.resume);
    subscription
      ..onData(
        (Input data) => scaffold(() => handleData(data, sink)),
      )
      ..onError(
        (Object error, StackTrace stackTrace) => handleError == null
            ? sink.addError(error, stackTrace)
            : scaffold(() => handleError!(error, stackTrace, sink)),
      )
      ..onDone(
        () => handleDone == null
            ? sink.close()
            : scaffold(() => handleDone!(sink)).whenComplete(sink.close),
      );
  }

  Future<void> Function(FutureOr<void> Function() handler) _scaffold(
    StreamSink<Output> sink,
    void Function([Future<void>? resumeSignal]) pause,
    void Function() resume,
  ) =>
      (FutureOr<void> Function() handler) {
        FutureOr<void> fn;
        try {
          fn = handler();
        } on Object catch (error, stackTrace) {
          sink.addError(error, stackTrace);
        }
        if (fn is Future) {
          pause();
          return fn.catchError(sink.addError).whenComplete(resume);
        } else {
          return Future<void>.value();
        }
      };
}
