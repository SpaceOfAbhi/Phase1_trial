import 'package:equatable/equatable.dart';

/// Enum for the four workout form classes the CNN-LSTM model classifies.
enum FormClass {
  good,
  partialRom,
  excessiveSwing,
  excessiveElbowMovement;

  /// Display label matching the model's label encoder classes.
  String get displayName {
    switch (this) {
      case FormClass.good:
        return 'GOOD';
      case FormClass.partialRom:
        return 'PARTIAL_ROM';
      case FormClass.excessiveSwing:
        return 'EXCESSIVE_SWING';
      case FormClass.excessiveElbowMovement:
        return 'EXCESSIVE_ELBOW_MOVEMENT';
    }
  }

  String get friendlyName {
    switch (this) {
      case FormClass.good:
        return 'Good Form';
      case FormClass.partialRom:
        return 'Partial Range';
      case FormClass.excessiveSwing:
        return 'Excessive Swing';
      case FormClass.excessiveElbowMovement:
        return 'Elbow Drift';
    }
  }

  String get description {
    switch (this) {
      case FormClass.good:
        return 'Full range of motion with proper technique and controlled movement throughout the curl.';
      case FormClass.partialRom:
        return 'Incomplete range of motion detected. Extend fully at the bottom and curl completely to the top.';
      case FormClass.excessiveSwing:
        return 'Excessive body swinging detected. Keep your back straight and isolate the bicep.';
      case FormClass.excessiveElbowMovement:
        return 'Elbow drifting forward during the curl. Pin elbows to your sides for proper form.';
    }
  }

  /// Maps from the model's raw label string (LabelEncoder output order).
  static FormClass fromLabel(String label) {
    switch (label.toUpperCase()) {
      case 'GOOD':
        return FormClass.good;
      case 'PARTIAL_ROM':
        return FormClass.partialRom;
      case 'EXCESSIVE_SWING':
        return FormClass.excessiveSwing;
      case 'EXCESSIVE_ELBOW_MOVEMENT':
        return FormClass.excessiveElbowMovement;
      default:
        throw ArgumentError('Unknown form class label: $label');
    }
  }

  static FormClass fromIndex(int index) {
    // Label encoder alphabetical order:
    // 0=EXCESSIVE_ELBOW_MOVEMENT, 1=EXCESSIVE_SWING, 2=GOOD, 3=PARTIAL_ROM
    switch (index) {
      case 0:
        return FormClass.excessiveElbowMovement;
      case 1:
        return FormClass.excessiveSwing;
      case 2:
        return FormClass.good;
      case 3:
        return FormClass.partialRom;
      default:
        throw RangeError('FormClass index out of range: $index');
    }
  }
}

/// Model metadata matching model_outputs/model_metadata.json
class ModelMetadata {
  const ModelMetadata({
    required this.sequenceLength,
    required this.numFeatures,
    required this.features,
    required this.classes,
    required this.samplingRateHz,
    required this.testAccuracy,
    required this.testLoss,
    required this.datasetType,
  });

  final int sequenceLength;
  final int numFeatures;
  final List<String> features;
  final List<String> classes;
  final int samplingRateHz;
  final double testAccuracy;
  final double testLoss;
  final String datasetType;

  bool get isSyntheticDataset => datasetType == 'synthetic';

  static const ModelMetadata current = ModelMetadata(
    sequenceLength: 256,
    numFeatures: 8,
    features: [
      'accelerometer_x',
      'accelerometer_y',
      'accelerometer_z',
      'gyroscope_x',
      'gyroscope_y',
      'gyroscope_z',
      'biceps_rms',
      'triceps_rms',
    ],
    classes: [
      'EXCESSIVE_ELBOW_MOVEMENT',
      'EXCESSIVE_SWING',
      'GOOD',
      'PARTIAL_ROM',
    ],
    samplingRateHz: 100,
    testAccuracy: 0.89,
    testLoss: 0.2647,
    datasetType: 'synthetic',
  );
}

/// A single repetition's prediction result from the CNN-LSTM model.
class PredictionResult extends Equatable {
  const PredictionResult({
    required this.predictedClass,
    required this.probabilities,
    required this.isDemo,
    required this.timestamp,
  });

  final FormClass predictedClass;

  /// Softmax probabilities for all four classes (index matches FormClass.fromIndex).
  final List<double> probabilities;

  /// True = mock/dataset demo data. False = real model output via FastAPI.
  final bool isDemo;

  final DateTime timestamp;

  double get confidence => probabilityFor(predictedClass);

  /// Probability for a specific class.
  double probabilityFor(FormClass cls) {
    switch (cls) {
      case FormClass.excessiveElbowMovement:
        return probabilities[0];
      case FormClass.excessiveSwing:
        return probabilities[1];
      case FormClass.good:
        return probabilities[2];
      case FormClass.partialRom:
        return probabilities[3];
    }
  }

  @override
  List<Object?> get props => [predictedClass, probabilities, isDemo, timestamp];
}

/// Six IMU sensor readings at a single time step.
class ImuSample extends Equatable {
  const ImuSample({
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
  });

  final double accelerometerX;
  final double accelerometerY;
  final double accelerometerZ;
  final double gyroscopeX;
  final double gyroscopeY;
  final double gyroscopeZ;

  @override
  List<Object?> get props => [
        accelerometerX,
        accelerometerY,
        accelerometerZ,
        gyroscopeX,
        gyroscopeY,
        gyroscopeZ,
      ];
}

/// Two EMG muscle activation RMS values at a single time step.
class EmgSample extends Equatable {
  const EmgSample({
    required this.bicepsRms,
    required this.tricepsRms,
  });

  final double bicepsRms;
  final double tricepsRms;

  @override
  List<Object?> get props => [bicepsRms, tricepsRms];
}

/// A complete recorded repetition with sensor time-series + prediction.
class WorkoutRepetition extends Equatable {
  const WorkoutRepetition({
    required this.id,
    required this.imuSamples,
    required this.emgSamples,
    required this.prediction,
    required this.repNumber,
  });

  final String id;
  final List<ImuSample> imuSamples;
  final List<EmgSample> emgSamples;
  final PredictionResult prediction;
  final int repNumber;

  @override
  List<Object?> get props => [id, prediction, repNumber];
}

/// A complete workout session (multiple reps).
class WorkoutSession extends Equatable {
  const WorkoutSession({
    required this.id,
    required this.exercise,
    required this.startTime,
    required this.repetitions,
    this.endTime,
  });

  final String id;
  final String exercise;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutRepetition> repetitions;

  int get totalReps => repetitions.length;

  int get goodReps =>
      repetitions.where((r) => r.prediction.predictedClass == FormClass.good).length;

  double get formScore =>
      totalReps == 0 ? 0.0 : (goodReps / totalReps) * 100;

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  @override
  List<Object?> get props => [id, exercise, startTime, repetitions];
}
