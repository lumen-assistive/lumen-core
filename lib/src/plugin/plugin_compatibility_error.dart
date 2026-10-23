/// Thrown when a plugin's declared `lumen_sdk` version constraint does
/// not allow the `lumen_sdk` version `lumen-core` was built against.
///
/// `lumen-core` refuses to register an incompatible plugin rather than
/// risk a silent contract mismatch between the plugin and the engine.
class PluginCompatibilityError extends Error {
  /// Creates a compatibility error for [pluginId].
  PluginCompatibilityError({
    required this.pluginId,
    required this.requiredConstraint,
    required this.actualVersion,
  });

  /// `PluginManifest.id` of the incompatible plugin.
  final String pluginId;

  /// The `lumen_sdk` version constraint the plugin declared, for
  /// example `^0.1.0`.
  final String requiredConstraint;

  /// The `lumen_sdk` version `lumen-core` was built against.
  final String actualVersion;

  @override
  String toString() =>
      'PluginCompatibilityError: plugin "$pluginId" requires lumen_sdk '
      '$requiredConstraint but lumen-core provides $actualVersion.';
}
