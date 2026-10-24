import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService(
      {this.baseUrl = const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'http://127.0.0.1:8000'),
      http.Client? client})
      : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;

  Future<dynamic> _request(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await (body == null
              ? _client.get(uri)
              : _client.post(uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(body)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        final payload = jsonDecode(response.body);
        final detail = payload['detail'];
        throw Exception(detail is String
            ? detail
            : 'Invalid recording. Check the sensor format in docs/inference.md.');
      }
      return jsonDecode(response.body);
    } on http.ClientException {
      throw Exception('Cannot reach the analysis server. Start it and retry.');
    } on TimeoutException {
      throw Exception('Analysis timed out. Check the server and retry.');
    }
  }

  Future<List<String>> recordings() async {
    final rows = await _request('/recordings') as List<dynamic>;
    return rows.map((row) => row['id'] as String).toList();
  }

  Future<Map<String, dynamic>> recording(String id) async =>
      Map<String, dynamic>.from(await _request('/recordings/$id') as Map);

  Future<Map<String, dynamic>> predict(Map<String, dynamic> recording) async =>
      Map<String, dynamic>.from(await _request('/predict', body: {
        'exercise': recording['exercise'] ?? 'bicep_curl',
        'imu': recording['imu'],
        'emg': recording['emg'],
      }) as Map);

  Future<bool> checkHealth() async =>
      (await _request('/health'))['model_loaded'] == true;
  void dispose() => _client.close();
}
