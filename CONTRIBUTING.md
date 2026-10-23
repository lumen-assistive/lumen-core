# Contributing to lumen_core

This repository implements the `lumen_sdk` contracts that every Lumen
module depends on. See the organization-wide
[CONTRIBUTING.md](https://github.com/lumen-assistive/.github/blob/main/CONTRIBUTING.md)
for the general workflow. This file only covers what is specific to
this repository.

## Setup

This package is currently pure Dart; the Flutter SDK is not required
until native platform code is added (see README for current scope).

```
dart pub get
git config core.hooksPath .githooks
```

## Before sending a pull request

```
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

All three must pass; CI runs the same commands on every push and pull
request.

## Working on native sensor bridges

Adding camera, microphone, or model inference bridges turns this
package into a Flutter plugin: add a `flutter` dependency, `android/`
and `ios/` platform directories, and switch the CI workflow's `target`
input from `dart` to `flutter`. Coordinate with `lumen-sdk` if the work
needs a new event type or capability; those are defined there.
