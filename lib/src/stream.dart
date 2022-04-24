import 'dart:async';

import 'package:meta/meta.dart';

/// {@template stream.stream_extensions}
/// Stream extension methods.
/// {@endtemplate}
extension StreamX<A> on Stream<A> {
  /// Allow relieve impact on event loop on large collections.
  /// Parallelize the event queue and free up time for processing animation,
  /// user gestures without using isolates.
  ///
  /// Thats transformer makes stream low priority.
  ///
  /// [duration] - elapsed time of iterations before releasing
  /// the event queue and microtasks.
  Stream<A> relieve([
    Duration duration = const Duration(milliseconds: 4),
  ]) =>
      transform<A>(RelieveStreamTransformer<A>(duration));

  /// {@macro stream.transform_on_type.transformer}
  Stream<A> transformOnType<B extends A>(
    Stream<B> Function(Stream<B> selected) transform,
  ) =>
      this.transform(TransformOnTypeTransformer<A, B>(transform));
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
class RelieveStreamTransformer<A> extends StreamTransformerBase<A, A> {
  /// {@macro stream.relieve_stream_transformer}
  const RelieveStreamTransformer([
    this.duration = const Duration(milliseconds: 4),
  ]);

  /// Elapsed time of iterations before releasing
  /// the event queue and microtasks.
  final Duration duration;

  @override
  Stream<A> bind(Stream<A> stream) {
    final sw = Stopwatch()..start();
    StreamSubscription<A>? sub;
    final sc = stream.isBroadcast
        ? StreamController<A>.broadcast(
            onCancel: () => sub?.cancel(),
            sync: true,
          )
        : StreamController<A>(
            onCancel: () => sub?.cancel(),
            sync: true,
          );
    sub = stream.listen(
      (A value) {
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

/// {@template stream.transform_on_type.transformer}
/// Allows to transform a stream on a specific subtype of events.
///
/// The transformer performs the transformation on the events of the specified
/// type, while merging the rest of the stream in the output stream.
///
/// The following set of actions are performed:
///   1) The stream that contains only the specified subtype of events is
///   filtered out from the rest.
///   2) The newly filtered stream is passed to the specified [transform]
///   callback.
///   3) The rest of the stream is filtered out.
///   4) Two stream are merged into one.
///
/// [transform] –
///   {@template stream.transform_on_type.transform}
///   Callback that performs an endomorphic transformation on the
///   stream of specified subtype.
///   {@endtemplate}
/// {@endtemplate}
@immutable
class TransformOnTypeTransformer<A, B extends A>
    extends StreamTransformerBase<A, A> {
  /// {@macro stream.transform_on_type.transform}
  final Stream<B> Function(Stream<B> selected) transform;

  /// {@macro stream.transform_on_type.transformer}
  const TransformOnTypeTransformer(this.transform);

  @override
  Stream<A> bind(Stream<A> stream) {
    final source = stream.asBroadcastStream();

    StreamSubscription<A>? remainingSubscription;
    StreamSubscription<A>? transformedSubscription;

    void pauseSubscriptions() {
      remainingSubscription?.pause();
      transformedSubscription?.pause();
    }

    void resumeSubscriptions() {
      remainingSubscription?.resume();
      transformedSubscription?.resume();
    }

    final controller = stream.isBroadcast
        ? StreamController<A>.broadcast(sync: true)
        : StreamController<A>(
            onPause: pauseSubscriptions,
            onResume: resumeSubscriptions,
            sync: true,
          );

    void subscribe({
      required Stream<A> stream,
      required void Function(StreamSubscription<A> subscription) store,
      void Function()? onDone,
    }) {
      store(
        stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: onDone,
          cancelOnError: false,
        ),
      );
    }

    void cancelSubscriptions() {
      remainingSubscription?.cancel();
      transformedSubscription?.cancel();
    }

    void wrapUp() {
      cancelSubscriptions();
      controller.close();
    }

    void startListening() {
      subscribe(
        stream: source.where((event) => event is! B),
        store: (subscription) => remainingSubscription = subscription,
        onDone: wrapUp,
      );
      subscribe(
        stream: transform(source.where((event) => event is B).cast<B>()),
        store: (subscription) => transformedSubscription = subscription,
      );
    }

    controller
      ..onListen = startListening
      ..onCancel = cancelSubscriptions;

    return controller.stream;
  }
}
