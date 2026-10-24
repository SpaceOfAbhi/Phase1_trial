/// Stub for the future FastAPI backend integration.
///
/// When the FastAPI backend is ready, implement this service to:
///   1. POST a normalized 256×8 feature array to the /predict endpoint.
///   2. Parse the JSON response (predicted_class, probabilities).
///   3. Return a real [PredictionResult] with [isDemo]=false.
///
/// Until then, all actual inference goes through [MockDataService] in demo mode.
///
/// Expected FastAPI contract (example):
/// ```
/// POST /predict
/// Content-Type: application/json
/// {
///   "features": [[f0, f1, ..., f7], ...],  // 256 × 8 float array
///   "exercise": "bicep_curl"
/// }
///
/// Response:
/// {
///   "predicted_class": "GOOD",
///   "probabilities": {
///     "EXCESSIVE_ELBOW_MOVEMENT": 0.02,
///     "EXCESSIVE_SWING": 0.03,
///     "GOOD": 0.92,
///     "PARTIAL_ROM": 0.03
///   },
///   "confidence": 0.92,
///   "model_version": "cnn_lstm_v1"
/// }
/// ```
library api_service;

import '../models/workout_models.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  // TODO(phase-2): Replace stub with real HTTP implementation using dio.
  // ignore: unused_element
  Future<PredictionResult> predictFormClass({
    required List<List<double>> features, // shape [256][8]
    required String exercise,
  }) async {
    throw UnimplementedError(
      'FastAPI backend not yet integrated. '
      'Use MockDataService for demo predictions.',
    );
  }

  Future<bool> checkHealth() async {
    // TODO(phase-2): GET $baseUrl/health and return true if 200.
    return false;
  }
}
