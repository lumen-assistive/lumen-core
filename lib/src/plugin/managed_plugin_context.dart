import 'package:lumen_sdk/lumen_sdk.dart';

import 'consent_store.dart';

/// [PluginContext] implementation [PluginManager] hands to each plugin.
///
/// Scopes [ConsentStore] lookups to the owning plugin's id, so a plugin
/// cannot accidentally read another plugin's consent flags.
class ManagedPluginContext implements PluginContext {
  /// Creates a context for [pluginId].
  ManagedPluginContext({
    required this.eventBus,
    required this.modelRegistry,
    required String pluginId,
    required ConsentStore consentStore,
  })  : _pluginId = pluginId,
        _consentStore = consentStore;

  @override
  final LumenEventBus eventBus;

  @override
  final ModelRegistry modelRegistry;

  final String _pluginId;
  final ConsentStore _consentStore;

  @override
  bool hasConsent(String consentKey) =>
      _consentStore.hasConsent(_pluginId, consentKey);
}
