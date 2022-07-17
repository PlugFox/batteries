import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'listenable_selector.dart';

/// Signature for the listener function which takes the BuildContext
/// along with the value and is responsible for executing
/// in response to value changes.
///
/// See also:
///
///  * [ListenableConsumer], a widget which invokes this listener each time
///    a [Listenable] changes.
typedef ListenableConsumerListener<Controller extends Listenable,
        Value extends Object?>
    = void Function(
  BuildContext context,
  Controller controller,
  Value prev,
  Value next,
);

/// Signature for the shouldRebuild function which takes the previous value
/// and the current value and is responsible for returning a bool
/// which determines whether to rebuild ListenableConsumer
/// with the current value.
///
/// See also:
///
///  * [ListenableConsumer], a widget which invokes this builder each time
///    a [Listenable] changes.
typedef ListenableConsumerCondition<Value extends Object?> = bool Function(
  BuildContext context,
  Value prev,
  Value next,
);

/// Builds a [Widget] when given a concrete value of a [Listenable].
///
/// If the `child` parameter provided to the [ListenableConsumer] is not
/// null, the same `child` widget is passed back
/// to this [ListenableConsumerBuilder]
/// and should typically be incorporated in the returned widget tree.
///
/// See also:
///
///  * [ListenableConsumer], a widget which invokes this builder each time
///    a [Listenable] changes.
typedef ListenableConsumerBuilder<Value extends Object?> = Widget Function(
  BuildContext context,
  Value value,
  Widget? child,
);

/// {@template listenable_consumer}
/// ListenableConsumer widget
/// {@endtemplate}
class ListenableConsumer<Controller extends Listenable, Value extends Object?>
    extends StatefulWidget {
  /// {@macro listenable_consumer}
  const ListenableConsumer({
    required this.listenable,
    required this.selector,
    this.listener,
    this.shouldRebuild,
    this.builder,
    this.child,
    super.key,
  });

  /// The [Listenable] whose values you depend on in order to build.
  /// This [Listenable] itself must not be null.
  final Controller listenable;

  /// Selector from [Listenable]
  final ChangeNotifierSelector<Controller, Value> selector;

  /// A [ListenableConsumerBuilder] which builds a widget depending on the
  /// [Listenable]'s values.
  ///
  /// Can incorporate a [Listenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final ListenableConsumerListener<Controller, Value>? listener;

  /// An optional shouldRebuild can be implemented for more granular control
  /// over how often ListenableConsumer rebuilds. shouldRebuild should only
  /// be used for performance optimizations as it provides no security about
  /// the value passed to the builder function. shouldRebuild will be invoked
  /// on each Listenable change. shouldRebuild takes the previous value and
  /// current value and must return a bool which determines whether or not the
  /// builder function will be invoked. The previous value will be initialized
  /// to the value of the Listenable when the ListenableConsumer is initialized.
  /// shouldRebuild is optional and if omitted, it will default to true.
  final ListenableConsumerCondition<Value>? shouldRebuild;

  /// A [ListenableConsumerBuilder] which builds a widget depending on the
  /// [Listenable]'s values.
  ///
  /// Can incorporate a [Listenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final ListenableConsumerBuilder<Value>? builder;

  /// The widget below this widget in the tree.
  final Widget? child;

  @override
  State<ListenableConsumer<Controller, Value>> createState() =>
      _ListenableConsumerState<Controller, Value>();
} // ListenableConsumer<Controller, Value>

/// State for widget ListenableConsumer
class _ListenableConsumerState<Controller extends Listenable,
        Value extends Object?>
    extends State<ListenableConsumer<Controller, Value>> {
  late ValueListenable<Value> _valueListenable;
  late Value _value;

  @override
  void initState() {
    super.initState();
    _valueListenable = widget.listenable.select(widget.selector);
    _valueListenable.addListener(_onValueChanged);
    _value = _valueListenable.value;
  }

  @override
  void didUpdateWidget(
    covariant ListenableConsumer<Controller, Value> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.listenable, widget.listenable) &&
        identical(oldWidget.selector, widget.selector)) {
      return;
    }
    _valueListenable.removeListener(_onValueChanged);
    _valueListenable = widget.listenable.select(widget.selector);
    _valueListenable.addListener(_onValueChanged);
    _value = _valueListenable.value;
  }

  @override
  void dispose() {
    _valueListenable.removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() {
    final prev = _value;
    final next = _valueListenable.value;
    _value = next;
    widget.listener?.call(
      context,
      widget.listenable,
      prev,
      next,
    );
    if (widget.shouldRebuild?.call(context, prev, next) ?? true) {
      setState(() => next);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder?.call(context, _value, widget.child) ??
      widget.child ??
      const SizedBox.shrink();
} // _ListenableConsumerState<Controller, Value>
