/// {@template collection.iterable_extensions}
/// [Iterable] extension methods.
/// {@endtemplate}
extension IterableX<T extends Object?> on Iterable<T> {
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
}
