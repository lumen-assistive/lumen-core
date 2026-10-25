import 'dart:io';

import 'package:lumen_core/lumen_core.dart';
import 'package:lumen_sdk/lumen_sdk.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

class _AlwaysGrantedCapabilityGate implements CapabilityGate {
  @override
  bool hasCapabilities(List<PluginCapability> capabilities) => true;
}

class _NeverGrantedCapabilityGate implements CapabilityGate {
  @override
  bool hasCapabilities(List<PluginCapability> capabilities) => false;
}

class _InMemoryConsentStore implements ConsentStore {
  final Set<String> granted = {};

  @override
  bool hasConsent(String pluginId, String consentKey) =>
      granted.contains('$pluginId:$consentKey');
}

class _RecordingPlugin implements LumenPlugin {
  _RecordingPlugin(this.manifest);

  @override
  final PluginManifest manifest;

  final List<String> calls = [];
  PluginContext? context;

  @override
  Future<void> initialize(PluginContext context) async {
    this.context = context;
    calls.add('initialize');
  }

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async => calls.add('dispose');
}

PluginManager _buildManager({
  CapabilityGate? capabilityGate,
  ConsentStore? consentStore,
}) {
  return PluginManager(
    eventBus: InMemoryEventBus(),
    modelRegistry: LocalModelRegistry(
      catalog: const [],
      modelsDirectory: Directory.systemTemp,
    ),
    capabilityGate: capabilityGate ?? _AlwaysGrantedCapabilityGate(),
    consentStore: consentStore ?? _InMemoryConsentStore(),
    sdkVersion: Version.parse('0.1.0'),
  );
}

void main() {
  group('PluginManager', () {
    test('register initializes the plugin exactly once', () async {
      final manager = _buildManager();
      final plugin = _RecordingPlugin(
        const PluginManifest(
          id: 'vision',
          nameIt: 'Vedere',
          nameEn: 'Vision',
          version: '1.0.0',
          sdkConstraint: '^0.1.0',
          capabilities: [],
        ),
      );

      await manager.register(plugin);

      expect(plugin.calls, ['initialize']);
      expect(manager.stateOf('vision'), PluginState.initialized);
      expect(manager.registeredPluginIds, ['vision']);
    });

    test('register rejects an incompatible sdk constraint', () async {
      final manager = _buildManager();
      final plugin = _RecordingPlugin(
        const PluginManifest(
          id: 'vision',
          nameIt: 'Vedere',
          nameEn: 'Vision',
          version: '1.0.0',
          sdkConstraint: '^9.0.0',
          capabilities: [],
        ),
      );

      await expectLater(
        manager.register(plugin),
        throwsA(isA<PluginCompatibilityError>()),
      );
      expect(manager.stateOf('vision'), isNull);
    });

    test('register rejects a duplicate plugin id', () async {
      final manager = _buildManager();
      final manifest = const PluginManifest(
        id: 'vision',
        nameIt: 'Vedere',
        nameEn: 'Vision',
        version: '1.0.0',
        sdkConstraint: '^0.1.0',
        capabilities: [],
      );

      await manager.register(_RecordingPlugin(manifest));

      await expectLater(
        manager.register(_RecordingPlugin(manifest)),
        throwsStateError,
      );
    });

    test('enable starts the plugin when capabilities are granted', () async {
      final manager = _buildManager();
      final plugin = _RecordingPlugin(
        const PluginManifest(
          id: 'hearing',
          nameIt: 'Sentire',
          nameEn: 'Hearing',
          version: '1.0.0',
          sdkConstraint: '^0.1.0',
          capabilities: [PluginCapability.microphone],
        ),
      );
      await manager.register(plugin);

      await manager.enable('hearing');

      expect(plugin.calls, ['initialize', 'start']);
      expect(manager.stateOf('hearing'), PluginState.started);
    });

    test('enable throws when a capability is not granted', () async {
      final manager = _buildManager(
        capabilityGate: _NeverGrantedCapabilityGate(),
      );
      final plugin = _RecordingPlugin(
        const PluginManifest(
          id: 'hearing',
          nameIt: 'Sentire',
          nameEn: 'Hearing',
          version: '1.0.0',
          sdkConstraint: '^0.1.0',
          capabilities: [PluginCapability.microphone],
        ),
      );
      await manager.register(plugin);

      await expectLater(manager.enable('hearing'), throwsStateError);
      expect(plugin.calls, ['initialize']);
    });

    test('disable stops a running plugin and is idempotent', () async {
      final manager = _buildManager();
      final plugin = _RecordingPlugin(
        const PluginManifest(
          id: 'safety',
          nameIt: 'Protezione',
          nameEn: 'Safety',
          version: '1.0.0',
          sdkConstraint: '^0.1.0',
          capabilities: [],
        ),
      );
      await manager.register(plugin);
      await manager.enable('safety');

      await manager.disable('safety');
      await manager.disable('safety');

      expect(plugin.calls, ['initialize', 'start', 'stop']);
      expect(manager.stateOf('safety'), PluginState.stopped);
    });

    test('unregister stops, disposes, and forgets the plugin', () async {
      final manager = _buildManager();
      final plugin = _RecordingPlugin(
        const PluginManifest(
          id: 'family',
          nameIt: 'Famiglia',
          nameEn: 'Family',
          version: '1.0.0',
          sdkConstraint: '^0.1.0',
          capabilities: [],
        ),
      );
      await manager.register(plugin);
      await manager.enable('family');

      await manager.unregister('family');

      expect(plugin.calls, ['initialize', 'start', 'stop', 'dispose']);
      expect(manager.stateOf('family'), isNull);
      expect(manager.registeredPluginIds, isEmpty);
    });
  });
}
