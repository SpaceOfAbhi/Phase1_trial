import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_models.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider({ApiService? api}) : _api = api ?? ApiService() {
    ready = _loadHistory();
  }

  final ApiService _api;
  final _storage = SharedPreferencesAsync();
  late final Future<void> ready;
  bool _disposed = false;
  bool _isDemoMode = false;
  bool _isPaused = false;
  bool _busy = false;
  bool _importedSession = false;
  String? _error;
  WorkoutSession? _session;
  WorkoutRepetition? _rep;
  List<WorkoutSession> _history = [];
  List<String> _recordings = [];
  int _recordingIndex = 0;
  String _selectedExercise = 'Bicep Curl';

  bool get isDemoMode => _isDemoMode;
  bool get isAnalysing => _session != null;
  bool get isPaused => _isPaused;
  bool get isBusy => _busy;
  bool get usesImportedRecording => _importedSession;
  String? get error => _error;
  WorkoutSession? get currentSession => _session;
  WorkoutRepetition? get currentRep => _rep;
  List<WorkoutSession> get history => List.unmodifiable(_history);
  String get selectedExercise => _selectedExercise;
  List<ImuSample> get liveImu => _rep?.imuSamples ?? [];
  List<EmgSample> get liveEmg => _rep?.emgSamples ?? [];
  PredictionResult? get latestPrediction => _rep?.prediction;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      final saved = await _storage.getString('workout_history');
      if (saved != null) {
        _history = (jsonDecode(saved) as List)
            .map((row) =>
                WorkoutSession.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList();
      }
    } catch (_) {
      _error =
          'Saved history could not be read. Existing stored data has been kept.';
    }
    _notify();
  }

  void setDemoMode(bool value) {
    if (isAnalysing || _busy) return;
    _isDemoMode = value;
    _error = null;
    _notify();
  }

  void selectExercise(String exercise) {
    _selectedExercise = exercise;
    _notify();
  }

  Future<void> startDemoSession() => startSession();

  Future<void> startSession({Map<String, dynamic>? recording}) async {
    if (_busy || isAnalysing) return;
    _busy = true;
    await ready;
    _busy = false;
    _importedSession = recording != null;
    _session = WorkoutSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        exercise: _selectedExercise,
        startTime: DateTime.now(),
        repetitions: []);
    _rep = null;
    _isPaused = false;
    await nextRep(recording: recording);
    if (_session?.totalReps == 0) _session = null;
    _notify();
  }

  Future<void> nextDemoRep() => nextRep();

  Future<void> nextRep({Map<String, dynamic>? recording}) async {
    if (_busy || _session == null || _isPaused) return;
    _busy = true;
    _error = null;
    _notify();
    final sessionId = _session!.id;
    final number = _session!.totalReps + 1;
    try {
      late WorkoutRepetition rep;
      if (_isDemoMode && recording == null) {
        rep = MockDataService.generateRepetition(
            id: '${sessionId}_$number', repNumber: number);
      } else {
        if (recording == null) {
          if (_recordings.isEmpty) _recordings = await _api.recordings();
          if (_recordings.isEmpty)
            throw Exception('No recordings are available.');
          recording = await _api
              .recording(_recordings[_recordingIndex % _recordings.length]);
        }
        final output = await _api.predict(recording);
        rep = WorkoutRepetition.fromJson({
          ...output,
          'id': '${sessionId}_$number',
          'rep_number': number,
          'timestamp': DateTime.now().toIso8601String(),
          'source': recording['source'] ?? 'user_recording',
          'expected_label': recording['expected_label']
        });
        _recordingIndex++;
      }
      if (_session?.id != sessionId) return;
      _rep = rep;
      _session = WorkoutSession(
          id: _session!.id,
          exercise: _session!.exercise,
          startTime: _session!.startTime,
          repetitions: [..._session!.repetitions, rep]);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _busy = false;
      _notify();
    }
  }

  void pauseResume() {
    if (_busy) return;
    _isPaused = !_isPaused;
    _notify();
  }

  Future<void> stopSession() async {
    if (_busy) return;
    final session = _session;
    if (session == null) return;
    _busy = true;
    _notify();
    if (session.totalReps > 0) {
      final finished = WorkoutSession(
          id: session.id,
          exercise: session.exercise,
          startTime: session.startTime,
          endTime: DateTime.now(),
          repetitions: session.repetitions);
      final updated = [finished, ..._history];
      try {
        await _storage.setString('workout_history',
            jsonEncode(updated.map((s) => s.toJson()).toList()));
      } catch (_) {
        _error =
            'History could not be saved. Keep this session open and retry.';
        _busy = false;
        _notify();
        return;
      }
      _history = updated;
    }
    _session = null;
    _rep = null;
    _isPaused = false;
    _busy = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _api.dispose();
    super.dispose();
  }
}
