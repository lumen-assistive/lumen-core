import 'package:lumen_sdk/lumen_sdk.dart';

/// Reports whether a set of device capabilities is currently granted.
///
/// `lumen-core` does not prompt the user for permissions itself;
/// `lumen-app` owns the actual permission request flow (for example
/// through the operating system's permission dialogs) and provides an
/// implementation of this interface to [PluginManager]. [PluginManager]
/// only checks the current state before starting a plugin; it never
/// triggers a prompt.
abstract class CapabilityGate {
  /// Whether every capability in [capabilities] is currently granted.
  bool hasCapabilities(List<PluginCapability> capabilities);
}
