import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workout_models.dart';
import '../services/mock_data_service.dart';

// ---------------------------------------------------------------------------
// Analysis Provider – orchestrates the form-analysis flow
// ---------------------------------------------------------------------------

/// AnalysisProvider manages the state of a live or demo analysis session.
/// 
/// IMPORTANT: This provider currently uses MOCK data only.
/// Real model inference will be wired up via [ApiService] (FastAPI backend)
/// in a future phase.  The [isDemoMode] flag clearly separates the two paths.
class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider() {
    _history = MockDataService.generateHistorySessions();
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isDemoMode = true;
  bool _isAnalysing = false;
  bool _isPaused = false;

  WorkoutSession? _currentSession;
  WorkoutRepetition? _currentRep;
  List<WorkoutSession> _history = [];

  String _selectedExercise = 'Bicep Curl';

  Timer? _replayTimer;
  int _replayIndex = 0;

  // Demo replay state
  List<ImuSample> _liveImu = [];
  List<EmgSample> _liveEmg = [];

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isDemoMode => _isDemoMode;
  bool get isAnalysing => _isAnalysing;
  bool get isPaused => _isPaused;
  WorkoutSession? get currentSession => _currentSession;
  WorkoutRepetition? get currentRep => _currentRep;
  List<WorkoutSession> get history => List.unmodifiable(_history);
  String get selectedExercise => _selectedExercise;

  List<ImuSample> get liveImu => List.unmodifiable(_liveImu);
  List<EmgSample> get liveEmg => List.unmodifiable(_liveEmg);

  PredictionResult? get latestPrediction => _currentRep?.prediction;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void setDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }

  void selectExercise(String exercise) {
    _selectedExercise = exercise;
    notifyListeners();
  }

  /// Starts a new analysis session in Dataset Demo mode.
  /// This replays pre-generated synthetic data one sample at a time to simulate
  /// a live sensor feed.  The rep classification is also synthetic.
  Future<void> startDemoSession() async {
    assert(_isDemoMode, 'startDemoSession called in non-demo mode');

    _isAnalysing = true;
    _isPaused = false;
    _liveImu = [];
    _liveEmg = [];
    _replayIndex = 0;

    final sessionId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    _currentSession = WorkoutSession(
      id: sessionId,
      exercise: _selectedExercise,
      startTime: DateTime.now(),
      repetitions: [],
    );
    _currentRep = null;

    notifyListeners();
    await _runDemoRep(repNumber: 1);
  }

  Future<void> _runDemoRep(
      {required int repNumber, FormClass? forcedClass}) async {
    final formClass = forcedClass ?? _pickDemoClass(repNumber);

    final imuFull = MockDataService.generateImuSamples(formClass: formClass);
    final emgFull = MockDataService.generateEmgSamples(formClass: formClass);

    // Stream samples at ~100 Hz compressed to ~256 ms per rep for demo speed
    const interval = Duration(milliseconds: 8);
    _replayTimer?.cancel();

    _replayIndex = 0;
    _replayTimer = Timer.periodic(interval, (timer) {
      if (!_isAnalysing || _isPaused) return;

      if (_replayIndex >= imuFull.length) {
        timer.cancel();
        _finaliseRep(
          repNumber: repNumber,
          formClass: formClass,
          imuFull: imuFull,
          emgFull: emgFull,
        );
        return;
      }

      _liveImu = imuFull.sublist(0, _replayIndex + 1);
      _liveEmg = emgFull.sublist(0, _replayIndex + 1);
      _replayIndex++;
      notifyListeners();
    });
  }

  void _finaliseRep({
    required int repNumber,
    required FormClass formClass,
    required List<ImuSample> imuFull,
    required List<EmgSample> emgFull,
  }) {
    final repId = '${_currentSession!.id}_rep_$repNumber';
    final prediction = MockDataService.generatePrediction(formClass);

    final rep = WorkoutRepetition(
      id: repId,
      imuSamples: imuFull,
      emgSamples: emgFull,
      prediction: prediction,
      repNumber: repNumber,
    );

    _currentRep = rep;

    final updatedReps = [..._currentSession!.repetitions, rep];
    _currentSession = WorkoutSession(
      id: _currentSession!.id,
      exercise: _currentSession!.exercise,
      startTime: _currentSession!.startTime,
      repetitions: updatedReps,
    );

    notifyListeners();
  }

  /// Records the next repetition in the current demo session.
  Future<void> nextDemoRep() async {
    if (_currentSession == null || !_isAnalysing) return;
    final nextRepNum = _currentSession!.totalReps + 1;
    _liveImu = [];
    _liveEmg = [];
    await _runDemoRep(repNumber: nextRepNum);
  }

  void pauseResume() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void stopSession() {
    _replayTimer?.cancel();
    _isAnalysing = false;
    _isPaused = false;

    if (_currentSession != null && _currentSession!.totalReps > 0) {
      final finished = WorkoutSession(
        id: _currentSession!.id,
        exercise: _currentSession!.exercise,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        repetitions: _currentSession!.repetitions,
      );
      _history = [finished, ..._history];
    }

    _currentSession = null;
    _currentRep = null;
    _liveImu = [];
    _liveEmg = [];

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FormClass _pickDemoClass(int repNumber) {
    // Cycle through all classes for demonstration purposes
    final classes = [
      FormClass.good,
      FormClass.good,
      FormClass.partialRom,
      FormClass.good,
      FormClass.excessiveSwing,
      FormClass.good,
      FormClass.excessiveElbowMovement,
      FormClass.good,
    ];
    return classes[(repNumber - 1) % classes.length];
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }
}
