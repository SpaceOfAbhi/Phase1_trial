import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:workout_ai/services/analysis_provider.dart';
import 'package:workout_ai/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());

  test('prediction is decoded, counted, saved and restored with charts',
      () async {
    final api = ApiService(client: MockClient((request) async {
      if (request.url.path == '/recordings')
        return http.Response('[{"id":"sample"}]', 200);
      if (request.url.path.startsWith('/recordings/'))
        return http.Response(
            '{"imu":[],"emg":[],"source":"synthetic_dataset","expected_label":"GOOD"}',
            200);
      expect(jsonDecode(request.body)['exercise'], 'bicep_curl');
      return http.Response(
          jsonEncode({
            'features': List.generate(256, (_) => [1, 2, 3, 4, 5, 6, .1, .2]),
            'predicted_class': 'GOOD',
            'probabilities': {
              'EXCESSIVE_ELBOW_MOVEMENT': .01,
              'EXCESSIVE_SWING': .02,
              'GOOD': .94,
              'PARTIAL_ROM': .03
            },
          }),
          200);
    }));
    final provider = AnalysisProvider(api: api);
    await provider.startSession();
    expect(provider.error, isNull);
    expect(provider.currentSession!.totalReps, 1);
    expect(provider.latestPrediction!.isDemo, false);
    expect(provider.latestPrediction!.confidence, .94);
    expect(provider.liveImu.length, 256);
    await provider.nextRep();
    expect(provider.currentSession!.totalReps, 2);
    await provider.stopSession();
    expect(provider.history.length, 1);
    final restored = AnalysisProvider();
    await restored.ready;
    expect(restored.history.single.repetitions.length, 2);
    expect(restored.history.single.repetitions.first.emgSamples.first.bicepsRms,
        .1);
    expect(restored.history.single.repetitions.first.prediction.source,
        'synthetic_dataset');
    restored.dispose();
    provider.dispose();
  });

  test('server errors keep history empty and allow retry', () async {
    final provider = AnalysisProvider(
        api: ApiService(
            client: MockClient((_) async =>
                http.Response('{"detail":"Streams do not overlap."}', 422))));
    await provider.startSession();
    expect(provider.error, 'Streams do not overlap.');
    expect(provider.isAnalysing, false);
    expect(provider.isBusy, false);
    expect(provider.history, isEmpty);
    provider.setDemoMode(true);
    await provider.startSession();
    expect(provider.latestPrediction!.isDemo, true);
    provider.dispose();
  });
}
