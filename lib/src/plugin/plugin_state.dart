/// Lifecycle state of a plugin as tracked by [PluginManager].
enum PluginState {
  /// Registered and initialized, but not started.
  initialized,

  /// Started and currently receiving events.
  started,

  /// Previously started, now stopped.
  stopped,
}
