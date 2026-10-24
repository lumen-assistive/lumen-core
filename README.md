<p align="center">
  <img src="https://raw.githubusercontent.com/lumen-assistive/.github/main/profile/assets/logo-wordmark.png" alt="Lumen" width="200">
</p>

# lumen_core

The senses engine for [Lumen](https://github.com/lumen-assistive): the
implementation of the contracts defined in
[`lumen_sdk`](https://github.com/lumen-assistive/lumen-sdk).

- **`InMemoryEventBus`**: the production `LumenEventBus` every plugin
  subscribes to.
- **`LocalModelRegistry`**: the production `ModelRegistry`, backed by a
  local directory of downloaded model packs, with pluggable download
  behavior through `ModelDownloader`.
- **`PluginManager`**: owns plugin lifecycle (registration, SDK version
  compatibility checks, starting and stopping modules), gated by an
  injected `CapabilityGate` and `ConsentStore` that the host app
  provides.

`lumen-app` and every `lumen-plugin-*` repository depend on this
package, pinned to a tagged release, never on `main`.

## Current scope

This release ships the platform-independent core of the senses engine
as a pure Dart package: the event bus, model registry, and plugin
manager described above, fully implemented and tested. It does not yet
include:

- Native sensor bridges (camera and microphone capture) that turn raw
  hardware input into `lumen_sdk` events.
- On-device model inference bindings (TFLite, whisper.cpp through FFI,
  OCR).

These require Kotlin, Swift, and native build toolchains to implement
and verify correctly, and are the next phase of work once that
toolchain is available in the development environment. Implementing
them will turn this package into a Flutter plugin with `android/` and
`ios/` platform code; see `CHANGELOG.md` for when that lands.

## Installation

```yaml
dependencies:
  lumen_core:
    git:
      url: https://github.com/lumen-assistive/lumen-core.git
      ref: v0.1.0
```

## Development

```
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

Install the shared commit message hook before committing:

```
git config core.hooksPath .githooks
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

## License

Apache License 2.0, see [LICENSE](LICENSE).
