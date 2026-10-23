import 'dart:io';

import 'package:lumen_core/lumen_core.dart';
import 'package:lumen_sdk/lumen_sdk.dart';
import 'package:test/test.dart';

const _ocrModel = ModelDescriptor(
  id: 'paddleocr-it',
  task: ModelTask.ocr,
  quantization: 'int8',
  sizeBytes: 12000000,
  licenseId: 'paddleocr-apache-2.0',
  version: '1.0.0',
);

class _RecordingDownloader implements ModelDownloader {
  int callCount = 0;
  bool shouldFail = false;

  @override
  Future<void> download(
      ModelDescriptor descriptor, Directory destination) async {
    callCount++;
    if (shouldFail) {
      throw Exception('simulated download failure');
    }
    await File('${destination.path}/model.bin').writeAsString('data');
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lumen_core_model_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LocalModelRegistry', () {
    test('lists the configured catalog', () {
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
      );

      expect(registry.listAvailable(), [_ocrModel]);
    });

    test('reports a model as not downloaded until its directory exists', () {
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
      );

      expect(registry.isDownloaded('paddleocr-it'), isFalse);
    });

    test('ensureDownloaded throws without a downloader', () {
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
      );

      expect(
        () => registry.ensureDownloaded('paddleocr-it'),
        throwsStateError,
      );
    });

    test('ensureDownloaded uses the configured downloader', () async {
      final downloader = _RecordingDownloader();
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
        downloader: downloader,
      );

      await registry.ensureDownloaded('paddleocr-it');

      expect(downloader.callCount, 1);
      expect(registry.isDownloaded('paddleocr-it'), isTrue);

      // A second call is a no-op since the model is already present.
      await registry.ensureDownloaded('paddleocr-it');
      expect(downloader.callCount, 1);
    });

    test('ensureDownloaded cleans up after a failed download', () async {
      final downloader = _RecordingDownloader()..shouldFail = true;
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
        downloader: downloader,
      );

      await expectLater(
        registry.ensureDownloaded('paddleocr-it'),
        throwsException,
      );
      expect(registry.isDownloaded('paddleocr-it'), isFalse);
    });

    test('acquire throws for a model that has not been downloaded', () {
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
      );

      expect(() => registry.acquire('paddleocr-it'), throwsStateError);
    });

    test('acquire shares one handle across concurrent callers', () async {
      final downloader = _RecordingDownloader();
      final registry = LocalModelRegistry(
        catalog: const [_ocrModel],
        modelsDirectory: tempDir,
        downloader: downloader,
      );
      await registry.ensureDownloaded('paddleocr-it');

      final first = await registry.acquire('paddleocr-it');
      final second = await registry.acquire('paddleocr-it');

      expect(identical(first, second), isTrue);

      await first.dispose();
      // Still referenced by `second`'s acquisition.
      await second.dispose();
    });
  });
}
