import 'dart:async';

import 'package:lumen_sdk/lumen_sdk.dart';

/// Production [LumenEventBus] implementation.
///
/// Sense data enters this bus from native platform bridges (camera,
/// microphone, and similar), and plugins subscribe to it by event type.
/// The bus itself holds no sensor logic: it is a plain in-process
/// multiplexer, kept deliberately simple so that the part of the system
/// that actually matters, how native capture turns into typed events,
/// can be tested and reasoned about independently of delivery.
class InMemoryEventBus implements LumenEventBus {
  final Map<Type, StreamController<SenseEvent>> _controllers = {};

  StreamController<SenseEvent> _controllerFor(Type type) {
    return _controllers.putIfAbsent(
      type,
      () => StreamController<SenseEvent>.broadcast(),
    );
  }

  @override
  Stream<T> on<T extends SenseEvent>() {
    return _controllerFor(T).stream.cast<T>();
  }

  @override
  void publish(SenseEvent event) {
    _controllerFor(event.runtimeType).add(event);
  }

  /// Closes every underlying stream controller.
  ///
  /// Intended for orderly shutdown, for example when the host app is
  /// being torn down in a test harness.
  Future<void> close() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }
}
