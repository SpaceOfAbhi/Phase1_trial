import 'dart:math';
import '../models/workout_models.dart';

/// Mock data generator for Dataset Demo mode.
/// 
/// ⚠️  IMPORTANT: All data produced by this service is SYNTHETIC / MOCK.
/// It is used only for UI demonstration and is clearly distinguished from
/// real model predictions that would come from the FastAPI backend.
/// 
/// The underlying CNN-LSTM model is NOT invoked here.
class MockDataService {
  MockDataService._();

  static final _rng = Random(42);

  // ---------------------------------------------------------------------------
  // Sensor signal generators
  // ---------------------------------------------------------------------------

  /// Generates a plausible bicep-curl IMU time series (256 steps).
  static List<ImuSample> generateImuSamples({
    FormClass? formClass,
    int steps = 256,
  }) {
    formClass ??= FormClass.good;
    final samples = <ImuSample>[];

    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final phase = t * 2 * pi;

      // Base curl motion on accelerometer Y (vertical axis)
      final baseAccY = sin(phase) * 8.5;

      // Add form-specific distortions
      double accelX, accelY, accelZ;
      double gyroX, gyroY, gyroZ;

      switch (formClass) {
        case FormClass.good:
          accelX = sin(phase * 0.3) * 0.5 + _noise(0.2);
          accelY = baseAccY + _noise(0.3);
          accelZ = cos(phase * 0.5) * 1.2 + _noise(0.2);
          gyroX = sin(phase) * 1.5 + _noise(0.1);
          gyroY = cos(phase * 0.3) * 0.4 + _noise(0.1);
          gyroZ = sin(phase * 0.2) * 0.3 + _noise(0.1);

        case FormClass.partialRom:
          // Reduced amplitude – partial curl
          accelX = sin(phase * 0.3) * 0.6 + _noise(0.2);
          accelY = baseAccY * 0.55 + _noise(0.3);
          accelZ = cos(phase * 0.5) * 0.8 + _noise(0.2);
          gyroX = sin(phase) * 0.9 + _noise(0.1);
          gyroY = cos(phase * 0.3) * 0.3 + _noise(0.1);
          gyroZ = sin(phase * 0.2) * 0.2 + _noise(0.1);

        case FormClass.excessiveSwing:
          // Large X/Z amplitude – body swinging
          accelX = sin(phase) * 4.2 + _noise(0.5);
          accelY = baseAccY * 0.8 + _noise(0.4);
          accelZ = cos(phase) * 3.8 + _noise(0.5);
          gyroX = sin(phase) * 1.2 + _noise(0.15);
          gyroY = sin(phase * 1.5) * 2.8 + _noise(0.3);
          gyroZ = cos(phase) * 2.5 + _noise(0.3);

        case FormClass.excessiveElbowMovement:
          // High gyro X – elbow flare
          accelX = sin(phase * 0.5) * 1.5 + _noise(0.3);
          accelY = baseAccY * 0.9 + _noise(0.3);
          accelZ = cos(phase * 0.8) * 1.8 + _noise(0.3);
          gyroX = sin(phase * 2) * 4.5 + _noise(0.4);
          gyroY = cos(phase * 0.5) * 0.6 + _noise(0.15);
          gyroZ = sin(phase * 1.5) * 1.2 + _noise(0.2);
      }

      samples.add(ImuSample(
        accelerometerX: accelX,
        accelerometerY: accelY,
        accelerometerZ: accelZ,
        gyroscopeX: gyroX,
        gyroscopeY: gyroY,
        gyroscopeZ: gyroZ,
      ));
    }

    return samples;
  }

  /// Generates plausible EMG activation envelopes (256 steps).
  static List<EmgSample> generateEmgSamples({
    FormClass? formClass,
    int steps = 256,
  }) {
    formClass ??= FormClass.good;
    final samples = <EmgSample>[];

    for (int i = 0; i < steps; i++) {
      final t = i / steps;
      final phase = t * 2 * pi;

      double biceps, triceps;

      switch (formClass) {
        case FormClass.good:
          // Biceps peaks mid-curl, triceps low
          biceps = max(0.0, sin(phase) * 0.85) + _noise(0.05).abs() * 0.1;
          triceps = max(0.0, cos(phase) * 0.2) + _noise(0.03).abs() * 0.05;

        case FormClass.partialRom:
          // Both signals weaker – partial activation
          biceps = max(0.0, sin(phase) * 0.48) + _noise(0.04).abs() * 0.08;
          triceps = max(0.0, cos(phase) * 0.12) + _noise(0.02).abs() * 0.04;

        case FormClass.excessiveSwing:
          // Erratic co-activation pattern
          biceps = max(0.0, sin(phase) * 0.72 + sin(phase * 3) * 0.2) + _noise(0.08).abs();
          triceps = max(0.0, sin(phase + 0.8) * 0.38) + _noise(0.06).abs();

        case FormClass.excessiveElbowMovement:
          // High triceps co-activation – stabilising
          biceps = max(0.0, sin(phase) * 0.78) + _noise(0.06).abs();
          triceps = max(0.0, sin(phase + 0.4) * 0.55) + _noise(0.05).abs();
      }

      samples.add(EmgSample(bicepsRms: biceps, tricepsRms: triceps));
    }

    return samples;
  }

  // ---------------------------------------------------------------------------
  // Prediction generation
  // ---------------------------------------------------------------------------

  /// Creates a mock prediction result for demo purposes.
  /// 
  /// The probabilities are plausible-looking softmax outputs, not real model
  /// inference. They are clearly flagged as [isDemo]=true.
  static PredictionResult generatePrediction(FormClass cls) {
    // Probabilities indexed by model label-encoder order:
    // 0=EXCESSIVE_ELBOW_MOVEMENT, 1=EXCESSIVE_SWING, 2=GOOD, 3=PARTIAL_ROM
    late List<double> probs;

    switch (cls) {
      case FormClass.good:
        probs = [
          _jitter(0.03),
          _jitter(0.04),
          _jitter(0.88),
          _jitter(0.05),
        ];
      case FormClass.partialRom:
        probs = [
          _jitter(0.06),
          _jitter(0.07),
          _jitter(0.12),
          _jitter(0.75),
        ];
      case FormClass.excessiveSwing:
        probs = [
          _jitter(0.05),
          _jitter(0.80),
          _jitter(0.09),
          _jitter(0.06),
        ];
      case FormClass.excessiveElbowMovement:
        probs = [
          _jitter(0.82),
          _jitter(0.07),
          _jitter(0.05),
          _jitter(0.06),
        ];
    }

    // Normalize to sum to 1.0
    final sum = probs.fold(0.0, (a, b) => a + b);
    probs = probs.map((p) => p / sum).toList();

    return PredictionResult(
      predictedClass: cls,
      probabilities: probs,
      isDemo: true,
      timestamp: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Session & history generation
  // ---------------------------------------------------------------------------

  static WorkoutRepetition generateRepetition({
    required String id,
    required int repNumber,
    FormClass? formClass,
  }) {
    final cls = formClass ?? _randomFormClass();
    return WorkoutRepetition(
      id: id,
      imuSamples: generateImuSamples(formClass: cls),
      emgSamples: generateEmgSamples(formClass: cls),
      prediction: generatePrediction(cls),
      repNumber: repNumber,
    );
  }

  static WorkoutSession generateSession({
    required String id,
    required String exercise,
    required DateTime startTime,
    int repCount = 8,
  }) {
    final reps = List.generate(
      repCount,
      (i) => generateRepetition(
        id: '${id}_rep_$i',
        repNumber: i + 1,
        // Bias toward GOOD with occasional issues
        formClass: i % 5 == 2
            ? FormClass.partialRom
            : i % 7 == 4
                ? FormClass.excessiveSwing
                : i % 11 == 6
                    ? FormClass.excessiveElbowMovement
                    : FormClass.good,
      ),
    );

    return WorkoutSession(
      id: id,
      exercise: exercise,
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: 3 + repCount)),
      repetitions: reps,
    );
  }

  /// Generates a list of historical workout sessions for the history screen.
  static List<WorkoutSession> generateHistorySessions() {
    final now = DateTime.now();
    return [
      generateSession(
        id: 'session_1',
        exercise: 'Bicep Curl',
        startTime: now.subtract(const Duration(days: 0, hours: 2)),
        repCount: 10,
      ),
      generateSession(
        id: 'session_2',
        exercise: 'Bicep Curl',
        startTime: now.subtract(const Duration(days: 1, hours: 5)),
        repCount: 8,
      ),
      generateSession(
        id: 'session_3',
        exercise: 'Bicep Curl',
        startTime: now.subtract(const Duration(days: 3, hours: 9)),
        repCount: 12,
      ),
      generateSession(
        id: 'session_4',
        exercise: 'Bicep Curl',
        startTime: now.subtract(const Duration(days: 5, hours: 1)),
        repCount: 6,
      ),
      generateSession(
        id: 'session_5',
        exercise: 'Bicep Curl',
        startTime: now.subtract(const Duration(days: 7, hours: 3)),
        repCount: 9,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static double _noise(double amplitude) =>
      (_rng.nextDouble() * 2 - 1) * amplitude;

  static double _jitter(double base) =>
      (base + (_rng.nextDouble() * 0.08 - 0.04)).clamp(0.01, 0.99);

  static FormClass _randomFormClass() {
    final r = _rng.nextDouble();
    if (r < 0.55) return FormClass.good;
    if (r < 0.72) return FormClass.partialRom;
    if (r < 0.86) return FormClass.excessiveSwing;
    return FormClass.excessiveElbowMovement;
  }
}
