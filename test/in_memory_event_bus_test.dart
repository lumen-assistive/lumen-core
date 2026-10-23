import 'package:lumen_core/lumen_core.dart';
import 'package:lumen_sdk/lumen_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryEventBus', () {
    late InMemoryEventBus bus;

    setUp(() {
      bus = InMemoryEventBus();
    });

    tearDown(() async {
      await bus.close();
    });

    test('delivers published events only to matching subscribers', () async {
      final transcripts = <TranscriptEvent>[];
      final alerts = <AlertEvent>[];

      bus.on<TranscriptEvent>().listen(transcripts.add);
      bus.on<AlertEvent>().listen(alerts.add);

      final transcript = TranscriptEvent(
        timestamp: DateTime(2026),
        text: 'Ciao',
        isFinal: true,
      );
      bus.publish(transcript);

      await Future<void>.delayed(Duration.zero);

      expect(transcripts, [transcript]);
      expect(alerts, isEmpty);
    });

    test('supports multiple subscribers to the same event type', () async {
      final first = <SoundAlertEvent>[];
      final second = <SoundAlertEvent>[];

      bus.on<SoundAlertEvent>().listen(first.add);
      bus.on<SoundAlertEvent>().listen(second.add);

      final event = SoundAlertEvent(
        timestamp: DateTime(2026),
        label: 'smoke_alarm',
        confidence: 0.92,
      );
      bus.publish(event);

      await Future<void>.delayed(Duration.zero);

      expect(first, [event]);
      expect(second, [event]);
    });
  });
}
