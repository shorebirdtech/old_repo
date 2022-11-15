import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

// Dart (intentionally) does not have finalizers, so to manage listening
// its easier to let State do so, since it already gets a dispose call.
abstract class ListenableState<T extends StatefulWidget> extends State<T> {
  final List<Listenable> _listenables = <Listenable>[];

  void listen(Listenable listenable) {
    _listenables.add(listenable);
    listenable.addListener(_update);
  }

  void _update() {
    // One of our listenables changed, so rebuild the entire widget.
    // If you want more precise control, you can use a ValueListenableBuilder.
    setState(() {});
  }

  @override
  @mustCallSuper
  void dispose() {
    final listenables = List.from(_listenables);
    _listenables.clear();
    for (final listenable in listenables) {
      listenable.removeListener(_update);
    }
    super.dispose();
  }
}

// Is this just a https://api.flutter.dev/flutter/widgets/AsyncSnapshot-class.html?
// This differs from ValueNotifier, in that its read-only from the consumer.
class CachedValue<T> extends ChangeNotifier implements ValueListenable<T> {
  CachedValue(this._value);

  // Needs speculation state.

  // state.Speculative
  // state.Authoratative
  // state.Default

  @override
  T get value => _value;
  T _value;

// FIXME: This should be private.
// Need to fix the contract between the generated code and this class.
  void updateValue(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '$value';
}
