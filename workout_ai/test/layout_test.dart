import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:workout_ai/screens/analysis_screen.dart';
import 'package:workout_ai/screens/dashboard_screen.dart';
import 'package:workout_ai/screens/exercise_select_screen.dart';
import 'package:workout_ai/screens/history_screen.dart';
import 'package:workout_ai/screens/rep_detail_screen.dart';
import 'package:workout_ai/services/analysis_provider.dart';
import 'package:workout_ai/theme/app_theme.dart';
import 'package:workout_ai/models/workout_models.dart';
import 'package:workout_ai/widgets/chart_widgets.dart';

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('phone screens fit with text scale $scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final provider = AnalysisProvider();
      await provider.ready;
      provider.setDemoMode(true);
      await provider.startSession();
      final rep = provider.currentRep!;
      await provider.stopSession();
      provider.history.single.repetitions
          .addAll(FormClass.values.map((form) => WorkoutRepetition(
                id: 'layout-${form.name}',
                imuSamples: rep.imuSamples,
                emgSamples: rep.emgSamples,
                prediction: PredictionResult(
                  predictedClass: form,
                  probabilities: const [0.25, 0.25, 0.25, 0.25],
                  isDemo: true,
                  timestamp: rep.prediction.timestamp,
                ),
                repNumber: form.index + 2,
              )));

      Future<void> show(Widget screen) async {
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(theme: AppTheme.dark, home: screen),
        ));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull,
            reason: '${screen.runtimeType} at scale $scale');
      }

      await show(const DashboardScreen());
      await show(const ExerciseSelectScreen());
      await show(const HistoryScreen());
      await tester.drag(
          find.byType(CustomScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'History breakdown at scale $scale');
      await show(RepDetailScreen(rep: rep, sessionExercise: 'Bicep Curl'));
      await tester.ensureVisible(find.text('EMG'));
      await tester.tap(find.text('EMG'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'EMG legend at scale $scale');
      await show(const AnalysisScreen());
      await provider.startSession();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull,
          reason: 'Active analysis at scale $scale');
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });
  }
  testWidgets('flat, single-sample signals render without invalid axes',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SignalChart(
              title: 'EMG Activation',
              series: [
                [0]
              ],
              colors: [AppColors.primary],
              legendLabels: ['Biceps RMS'],
              minY: 0),
        )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Biceps RMS'), findsOneWidget);
  });
}
