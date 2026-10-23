/// Lumen senses engine: the event bus, model registry and plugin
/// manager implementation shared by every Lumen module.
///
/// This package implements the contracts defined in `lumen_sdk`.
/// Native sensor bridges (camera and microphone capture, on-device
/// model inference through TFLite and whisper.cpp) are not part of
/// this release; see the package README for current scope.
library;

export 'src/events/in_memory_event_bus.dart';
export 'src/models/local_model_registry.dart';
export 'src/models/model_downloader.dart';
export 'src/plugin/capability_gate.dart';
export 'src/plugin/consent_store.dart';
export 'src/plugin/managed_plugin_context.dart';
export 'src/plugin/plugin_compatibility_error.dart';
export 'src/plugin/plugin_manager.dart';
export 'src/plugin/plugin_state.dart';
