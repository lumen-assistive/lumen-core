/// Reads per-plugin consent flags.
///
/// `lumen-core` does not decide what counts as consent or how it is
/// persisted; `lumen-app` owns the actual consent UI and storage (for
/// example encrypted local preferences) and provides an implementation
/// of this interface to [PluginManager].
abstract class ConsentStore {
  /// Whether the user has granted [pluginId] consent for [consentKey].
  ///
  /// Consent keys are plugin-defined strings, for example
  /// `share-location-with-caregiver`.
  bool hasConsent(String pluginId, String consentKey);
}
