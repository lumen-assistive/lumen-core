import 'dart:io';

import 'package:lumen_sdk/lumen_sdk.dart';

/// Fetches a model pack's files onto the device.
///
/// `lumen-core` does not bundle a concrete implementation: the actual
/// download source (a `lumen-server` endpoint, a CDN, or a bundled
/// asset copy) is an app-level concern, and development on
/// `lumen-models` has not started yet. Host apps provide an
/// implementation of this interface to [LocalModelRegistry]; without
/// one, [LocalModelRegistry.ensureDownloaded] fails clearly instead of
/// silently doing nothing.
abstract class ModelDownloader {
  /// Downloads every file for [descriptor] into [destination].
  ///
  /// [destination] already exists and is empty. Implementations must
  /// throw rather than leave partially written files on failure, since
  /// [LocalModelRegistry] treats the directory's existence as proof the
  /// model is ready to use.
  Future<void> download(ModelDescriptor descriptor, Directory destination);
}
