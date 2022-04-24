import 'dart:collection';

/// {@template iterable.immutable_list}
/// Base class for immutable lists.
/// Creates an unmodifiable list backed by source.
///
/// The source of the elements may be a [List] or any [Iterable] with
/// efficient [Iterable.length] and [Iterable.elementAt].
/// {@endtemplate}
class ImmutableList<E> extends IterableBase<E> {
  /// {@macro iterable.immutable_list}
  ImmutableList(Iterable<E> source)
      : _source = List<E>.of(source, growable: false);

  /// {@macro iterable.immutable_list}
  /// Empty collection
  const ImmutableList.empty() : _source = const Iterable.empty();

  final Iterable<E> _source;

  @override
  ImmutableList<R> cast<R>() => ImmutableList<R>(_source.cast<R>());

  @override
  int get length => _source.length;

  @override
  E get last => _source.last;

  @override
  Iterator<E> get iterator => _source.iterator;

  /// Adds [value] to the end of this list,
  /// Returns a new list with the element added.
  ImmutableList<E> add(E value) =>
      ImmutableList<E>(List<E>.of(_source)..add(value));

  /// Appends all objects of [iterable] to the end of this list.
  /// Returns a new list with the elements added.
  ImmutableList<E> addAll(Iterable<E> iterable) =>
      ImmutableList<E>(List<E>.of(_source)..addAll(iterable));

  /// Removes the first occurrence of [value] from this list.
  /// Returns a new list with removed element.
  ImmutableList<E> remove(E value) => ImmutableList<E>(
        List<E>.of(_source)..remove(value),
      );

  /// Removes all objects from this list that satisfy [test].
  ///
  /// An object `o` satisfies [test] if `test(o)` is true.
  /// ```dart
  /// final numbers = <String>['one', 'two', 'three', 'four'];
  /// numbers.removeWhere((item) => item.length == 3);
  /// print(numbers); // [three, four]
  /// ```
  /// Returns a new list with removed element.
  ImmutableList<E> removeWhere(bool Function(E) test) => ImmutableList<E>(
        List<E>.of(_source)..removeWhere(test),
      );

  /// Set element.
  /// Returns a new list with element.
  ImmutableList<E> set(E element) => ImmutableList<E>(
        List<E>.of(_source)
          ..remove(element)
          ..add(element),
      );

  /// Sorts this list according to the order specified by the [compare] function
  ImmutableList<E> sort([int Function(E a, E b)? compare]) => ImmutableList<E>(
        List<E>.of(_source, growable: false)..sort(compare),
      );

  /// Returns the element at the given [index] in the list
  ///  or throws an [RangeError]
  E operator [](int index) => _source.elementAt(index);
}
