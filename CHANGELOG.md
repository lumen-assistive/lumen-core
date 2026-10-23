# Changelog

All notable changes to this project are documented in this file. The
format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- `InMemoryEventBus`, the production `LumenEventBus` implementation.
- `LocalModelRegistry` and `ModelDownloader`, the production
  `ModelRegistry` implementation backed by local storage with
  pluggable, reference-counted model loading.
- `PluginManager`, `CapabilityGate`, `ConsentStore`,
  `ManagedPluginContext`, and `PluginCompatibilityError` for plugin
  lifecycle management with SDK version compatibility checks.

### Known limitations

- No native sensor bridges (camera, microphone) or on-device model
  inference bindings (TFLite, whisper.cpp FFI) yet; see README for
  scope and the tracked next phase.
