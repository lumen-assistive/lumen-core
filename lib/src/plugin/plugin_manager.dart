import 'package:lumen_sdk/lumen_sdk.dart';
import 'package:pub_semver/pub_semver.dart';

import 'capability_gate.dart';
import 'consent_store.dart';
import 'managed_plugin_context.dart';
import 'plugin_compatibility_error.dart';
import 'plugin_state.dart';

/// Owns plugin lifecycle: registration, version compatibility checks,
/// and enabling or disabling a module per the user's current capability
/// grants.
///
/// A single [PluginManager] is shared by the whole app. It is the only
/// place that calls into [LumenPlugin] methods, so module lifecycle
/// stays centralized and consistent across every module.
class PluginManager {
  /// Creates a plugin manager.
  ///
  /// [sdkVersion] is the `lumen_sdk` version `lumen-core` was built
  /// against; it is compared against each plugin's
  /// `PluginManifest.sdkConstraint` at registration time.
  PluginManager({
    required this.eventBus,
    required this.modelRegistry,
    required this.capabilityGate,
    required this.consentStore,
    required Version sdkVersion,
  }) : _sdkVersion = sdkVersion;

  /// The event bus shared by every registered plugin.
  final LumenEventBus eventBus;

  /// The model registry shared by every registered plugin.
  final ModelRegistry modelRegistry;

  /// Reports whether a plugin's required capabilities are granted.
  final CapabilityGate capabilityGate;

  /// Reads per-plugin consent flags.
  final ConsentStore consentStore;

  final Version _sdkVersion;

  final Map<String, LumenPlugin> _plugins = {};
  final Map<String, PluginState> _states = {};

  /// Registers and initializes [plugin].
  ///
  /// Throws a [PluginCompatibilityError] if the plugin's manifest
  /// declares an `lumen_sdk` constraint the running `lumen_sdk` version
  /// does not satisfy. Throws a [StateError] if a plugin with the same
  /// id is already registered.
  Future<void> register(LumenPlugin plugin) async {
    final manifest = plugin.manifest;
    if (_plugins.containsKey(manifest.id)) {
      throw StateError('Plugin "${manifest.id}" is already registered.');
    }

    final constraint = VersionConstraint.parse(manifest.sdkConstraint);
    if (!constraint.allows(_sdkVersion)) {
      throw PluginCompatibilityError(
        pluginId: manifest.id,
        requiredConstraint: manifest.sdkConstraint,
        actualVersion: _sdkVersion.toString(),
      );
    }

    final context = ManagedPluginContext(
      eventBus: eventBus,
      modelRegistry: modelRegistry,
      pluginId: manifest.id,
      consentStore: consentStore,
    );

    await plugin.initialize(context);
    _plugins[manifest.id] = plugin;
    _states[manifest.id] = PluginState.initialized;
  }

  /// Starts a previously registered plugin.
  ///
  /// Throws a [StateError] if [pluginId] is not registered, or if
  /// [capabilityGate] reports that a required capability is not
  /// currently granted. Does nothing if the plugin is already started.
  Future<void> enable(String pluginId) async {
    if (_states[pluginId] == PluginState.started) return;

    final plugin = _pluginOrThrow(pluginId);
    if (!capabilityGate.hasCapabilities(plugin.manifest.capabilities)) {
      throw StateError(
        'Cannot enable plugin "$pluginId": a required capability is '
        'not currently granted.',
      );
    }

    await plugin.start();
    _states[pluginId] = PluginState.started;
  }

  /// Stops a running plugin. Does nothing if it is not running.
  Future<void> disable(String pluginId) async {
    if (_states[pluginId] != PluginState.started) return;

    final plugin = _pluginOrThrow(pluginId);
    await plugin.stop();
    _states[pluginId] = PluginState.stopped;
  }

  /// Stops [pluginId] if running, disposes it, and removes it from this
  /// manager. Does nothing if it is not registered.
  Future<void> unregister(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) return;

    if (_states[pluginId] == PluginState.started) {
      await plugin.stop();
    }
    await plugin.dispose();

    _plugins.remove(pluginId);
    _states.remove(pluginId);
  }

  /// Current lifecycle state of [pluginId], or `null` if it was never
  /// registered.
  PluginState? stateOf(String pluginId) => _states[pluginId];

  /// Ids of every currently registered plugin.
  List<String> get registeredPluginIds => List.unmodifiable(_plugins.keys);

  LumenPlugin _pluginOrThrow(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      throw StateError('Plugin "$pluginId" is not registered.');
    }
    return plugin;
  }
}
