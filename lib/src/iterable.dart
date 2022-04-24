import 'dart:math' as math;

/// {@template collection.iterable_extensions}
/// [Iterable] extension methods.
/// {@endtemplate}
extension IterableX<T> on Iterable<T> {
  /// Chunk while
  Iterable<List<T>> chunkWhile(bool Function(T a, T b) test) sync* {
    final i = iterator;
    var list = i.moveNext() ? <T>[i.current] : <T>[];
    while (i.moveNext()) {
      if (test(list.last, i.current)) {
        list.add(i.current);
      } else {
        yield list;
        list = <T>[i.current];
      }
    }
    if (list.isNotEmpty) yield list;
  }

  /// Split when
  Iterable<List<T>> splitWhen(bool Function(T a, T b) test) =>
      chunkWhile((a, b) => !test(a, b));

  /// Allow relieve impact on event loop on large collections.
  /// Parallelize the event queue and free up time for processing animation,
  /// user gestures without using isolates.
  ///
  /// [duration] - elapsed time of iterations before releasing
  /// the event queue and microtasks.
  Stream<T> relieve([
    Duration duration = const Duration(milliseconds: 4),
  ]) async* {
    final sw = Stopwatch()..start();
    try {
      final iter = iterator;
      while (iter.moveNext()) {
        if (sw.elapsed > duration) {
          await Future<void>.delayed(Duration.zero);
          sw.reset();
        }
        yield iter.current;
      }
    } finally {
      sw.stop();
    }
  }
}

/// {@template iterable.utf8_code_units}
/// Iterable<int> as UTF-8 code units.
/// {@endtemplate}
extension UTF8CodeUnitsX on Iterable<int> {
  /// Check code is digit
  /// 0..9: 48..57
  static bool isDigit(int code) => code > 47 && code < 58;

  /// Check code is lattin letter
  /// A..Z: 65..90
  /// a..z: 97..122
  static bool isLatin(int code) =>
      (code > 64 && code < 91) || (code > 96 && code < 123);

  /// Check code is cyrillic letter
  /// Ё:    1025
  /// А..Я: 1040..1071
  /// а..я: 1072..1103
  /// ё:    1105
  static bool isCyrillic(int code) =>
      (code > 1039 && code < 1104) || code == 1025 || code == 1105;

  /// Get from iterable only digits symbols
  Iterable<int> get onlyDigits => where(isDigit);

  /// Get from iterable only latin symbols
  Iterable<int> get onlyLatin => where(isLatin);

  /// Get from iterable only cyrillic symbols
  Iterable<int> get onlyCyrillic => where(isCyrillic);

  /// Maximum code
  int get max => reduce(math.max);

  /// Minimum code
  int get min => reduce(math.min);
}
