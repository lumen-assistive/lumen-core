import 'dart:io';

import 'package:lumen_sdk/lumen_sdk.dart';

import 'model_downloader.dart';

/// Production [ModelRegistry] implementation backed by a directory on
/// local storage.
///
/// Each model pack lives under `<modelsDirectory>/<id>-<version>/`. A
/// model is considered downloaded when that directory exists; download
/// itself is delegated to an injected [ModelDownloader] so that this
/// class stays independent of where model bytes actually come from.
/// Handles are reference-counted so that two plugins requesting the
/// same model share one underlying load.
class LocalModelRegistry implements ModelRegistry {
  /// Creates a registry over [catalog], storing downloaded models under
  /// [modelsDirectory].
  ///
  /// [downloader] is optional; without one, [ensureDownloaded] throws
  /// for any model that is not already present on disk.
  LocalModelRegistry({
    required List<ModelDescriptor> catalog,
    required Directory modelsDirectory,
    ModelDownloader? downloader,
  })  : _catalog = List.unmodifiable(catalog),
        _modelsDirectory = modelsDirectory,
        _downloader = downloader;

  final List<ModelDescriptor> _catalog;
  final Directory _modelsDirectory;
  final ModelDownloader? _downloader;
  final Map<String, _LoadedModel> _loaded = {};

  Directory _directoryFor(ModelDescriptor descriptor) {
    return Directory(
      '${_modelsDirectory.path}/${descriptor.id}-${descriptor.version}',
    );
  }

  ModelDescriptor _descriptorOrThrow(String modelId) {
    return _catalog.firstWhere(
      (descriptor) => descriptor.id == modelId,
      orElse: () => throw StateError('Unknown model id: $modelId'),
    );
  }

  @override
  List<ModelDescriptor> listAvailable() => _catalog;

  @override
  bool isDownloaded(String modelId) {
    final descriptor = _descriptorOrThrow(modelId);
    return _directoryFor(descriptor).existsSync();
  }

  @override
  Future<void> ensureDownloaded(String modelId) async {
    final descriptor = _descriptorOrThrow(modelId);
    final destination = _directoryFor(descriptor);
    if (destination.existsSync()) return;

    final downloader = _downloader;
    if (downloader == null) {
      throw StateError(
        'Model "$modelId" is not present on-device and no '
        'ModelDownloader was configured for this registry.',
      );
    }

    await destination.create(recursive: true);
    try {
      await downloader.download(descriptor, destination);
    } catch (_) {
      if (destination.existsSync()) {
        await destination.delete(recursive: true);
      }
      rethrow;
    }
  }

  @override
  Future<ModelHandle> acquire(String modelId) async {
    final descriptor = _descriptorOrThrow(modelId);
    if (!isDownloaded(modelId)) {
      throw StateError(
        'Model "$modelId" has not been downloaded. Call '
        'ensureDownloaded first.',
      );
    }

    final existing = _loaded[modelId];
    if (existing != null) {
      existing.refCount++;
      return existing.handle;
    }

    final handle = _LocalModelHandle(
      descriptor: descriptor,
      directory: _directoryFor(descriptor),
      onDispose: () => _release(modelId),
    );
    _loaded[modelId] = _LoadedModel(handle: handle, refCount: 1);
    return handle;
  }

  void _release(String modelId) {
    final loaded = _loaded[modelId];
    if (loaded == null) return;
    loaded.refCount--;
    if (loaded.refCount <= 0) {
      _loaded.remove(modelId);
    }
  }
}

class _LoadedModel {
  _LoadedModel({required this.handle, required this.refCount});

  final _LocalModelHandle handle;
  int refCount;
}

class _LocalModelHandle implements ModelHandle {
  _LocalModelHandle({
    required this.descriptor,
    required this.directory,
    required this.onDispose,
  });

  @override
  final ModelDescriptor descriptor;

  /// Directory containing this model's files on-device.
  final Directory directory;

  final void Function() onDispose;
  bool _disposed = false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    onDispose();
  }
}
